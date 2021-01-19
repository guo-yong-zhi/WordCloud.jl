function collision(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, i=(levelnum(Q1), 1, 1))
    #     @show i
#     @assert size(Q1) == size(Q2)
    n1 = Q1[i]
    n2 = Q2[i]
    if n1 == EMPTY || n2 == EMPTY
        return false, i
    end
    if n1 == FULL || n2 == FULL
        return true, i
    end
        
    r = false, i
    for cn in 1:4 # half
        ci = child(i, cn)
    #         @show cn,ci
    #         @show Q1[ci],Q2[ci]
        r = collision(Q1, Q2, ci)
        if r[1] return r end 
    end
    return r # no collision
end

function collision_bfs(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, q=[(levelnum(Q1), 1, 1)])
#     @assert size(Q1) == size(Q2)
    if isempty(q)
        push!(q, (levelnum(Q1), 1, 1))
    end
    i = q[1]
    n1 = Q1[i]
    n2 = Q2[i]
    if n1 == EMPTY || n2 == EMPTY
        return false, i
    end
    if n1 == FULL || n2 == FULL
        return true, i
    end
    while !isempty(q)
#         @show q
        # Q1[i],Q2[i]都是HALF
        i = popfirst!(q)
        for cn in 1:4
            ci = child(i, cn)
#             @show cn,ci
#             @show Q1[ci],Q2[ci]
            if !(Q1[ci] == EMPTY || Q2[ci] == EMPTY)
                if Q1[ci] == FULL || Q2[ci] == FULL
                    return true, ci
                else
                    push!(q, ci)
                end
            end
        end
    end
    return false, i # no collision
end

function collision_bfs_rand(Q1::AbstractStackedQtree, Q2::AbstractStackedQtree, q=[(levelnum(Q1), 1, 1)])
#     @assert size(Q1) == size(Q2)
    if isempty(q)
        push!(q, (levelnum(Q1), 1, 1))
    end
    i = q[1]
    n1 = Q1[i]
    n2 = Q2[i]
    if n1 == EMPTY || n2 == EMPTY
        return .-i
    end
    if n1 == FULL || n2 == FULL
        return i
    end
    while !isempty(q)
#         @show q
        # Q1[i],Q2[i]都是HALF
        i = popfirst!(q)
        for cn in shuffle4()
            ci = child(i, cn)
#             @show cn,ci
#             @show Q1[ci],Q2[ci]
            if !(Q1[ci] == EMPTY || Q2[ci] == EMPTY)
                if Q1[ci] == FULL || Q2[ci] == FULL
                    return ci
                else
                    push!(q, ci)
                end
            end
        end
    end
    return .- i # no collision
end

ColItemType = Pair{Tuple{Int,Int},Tuple{Int,Int,Int}}
function listcollision_native(qtrees::AbstractVector, mask::AbstractStackedQtree, 
        indpairs::Vector{<:Union{Vector, Tuple}}; collist=Vector{ColItemType}(),
        queue=Vector{Tuple{Int,Int,Int}}(), at=(levelnum(qtrees[1]), 1, 1))
    getqtree(i) = i==0 ? mask : qtrees[i]
    for (i1, i2) in indpairs
        empty!(queue)
        push!(queue, at)
        cp = collision_bfs_rand(getqtree(i1), getqtree(i2), queue)
        if cp[1] >= 0
            push!(collist, (i1, i2)=>cp)
        end
    end
    collist
end
function listcollision_native(qtrees::AbstractVector, mask::AbstractStackedQtree, 
    indpairs::Vector{Tuple{Tuple{Int,Int},Tuple{Int,Int,Int}}}; collist=Vector{ColItemType}(),
    queue=Vector{Tuple{Int,Int,Int}}())
getqtree(i) = i==0 ? mask : qtrees[i]
for ((i1, i2), at) in indpairs
    empty!(queue)
    push!(queue, at)
    cp = collision_bfs_rand(getqtree(i1), getqtree(i2), queue)
    if cp[1] >= 0
        push!(collist, (i1, i2)=>cp)
    end
end
collist
end
function listcollision_native(qtrees::AbstractVector, mask::AbstractStackedQtree, 
    inds=0:length(qtrees); collist=Vector{ColItemType}(), 
    queue=Vector{Tuple{Int,Int,Int}}(), at=(levelnum(qtrees[1]), 1, 1))
   indpairs = combinations(inds, 2) |> collect |> shuffle!
   listcollision_native(qtrees, mask, indpairs, collist=collist, at=at)
end
function listcollision_native(qtrees::AbstractVector, mask::AbstractStackedQtree, 
    inds::AbstractSet; kargs...)
   listcollision_native(qtrees, mask, inds|>collect; kargs...)
end

function findroom(ground, q=[(levelnum(ground), 1, 1)])
    if isempty(q)
        push!(q, (levelnum(ground), 1, 1))
    end
    i = q[1]
    if ground[i] == EMPTY
        return i
    elseif ground[i] == FULL
        return nothing
    end
    while !isempty(q)
        i = popfirst!(q)
        if i[1] == 1
            if ground[i] == EMPTY return i end
        else
            for cn in shuffle4()
                ci = child(i, cn)
                if ground[ci] == EMPTY
                    if rand() < 0.7 #避免每次都是局部最优
                        return ci 
                    else
                        push!(q, ci)
                    end
                elseif ground[ci] == HALF
                    push!(q, ci)
                end
            end
        end
    end
    return nothing
end

function overlap(p1::UInt8, p2::UInt8)
    if p1 == FULL || p2 == FULL
        return FULL
    elseif p1 == EMPTY && p2 == EMPTY
        return EMPTY
    else
        error("roung code")
    end
end

overlap(p1::AbstractMatrix, p2::AbstractMatrix) = overlap.(p1, p2)

"将p2叠加到p1上"
function overlap!(p1::PaddedMat, p2::PaddedMat)
    @assert size(p1) == size(p2)
    rs, cs = getshift(p2)
    for i in 1:kernelsize(p2)[1]
        for j in 1:kernelsize(p2)[2]
            p1[rs + i, cs + j] = overlap(p1[rs + i, cs + j], p2[rs + i, cs + j])
        end
    end
    return p1
end

function overlap2!(tree1::ShiftedQtree, tree2::ShiftedQtree)
    overlap!(tree1[1], tree2[1])
    tree1 |> buildqtree!
end

function overlap!(tree1::ShiftedQtree, tree2::ShiftedQtree, ind::Tuple{Int,Int,Int})
    if !(tree1[ind] == FULL || tree2[ind] == EMPTY)
        if ind[1] == 1
            tree1[ind] = FULL
        else
            for ci in 1:4
                overlap!(tree1, tree2, child(ind, ci))
            end
            qcode!(tree1, ind)
        end
    end
    tree1
end

function overlap!(tree1::ShiftedQtree, tree2::ShiftedQtree)
    @assert lastindex(tree1) == lastindex(tree2)
    @assert size(tree1[end]) == size(tree2[end]) == (1, 1)
    overlap!(tree1, tree2, (lastindex(tree1), 1, 1))
end

"将sortedtrees依次叠加到ground上，同时修改sortedtrees的shift"
function placement!(ground, sortedtrees)
    # pos = Vector{Tuple{Int, Int, Int}}()
    for t in sortedtrees
        ind = placement!(ground, t)
        overlap!(ground, t)
        if ind === nothing
            return pos
        end
        # push!(pos, ind)
    end
    nothing
    # return pos
end

function placement!(ground, qtree::ShiftedQtree)
    ind = findroom(ground)
    # @show ind
    if ind === nothing
        return nothing
    end
    l, r, c = ind
    x = floor(2^(l - 1) * (r - 1) + 2^(l - 2))
    y = floor(2^(l - 1) * (c - 1) + 2^(l - 2))
    m, n = kernelsize(qtree[1])
    setshift!(qtree, 1, x - m ÷ 2, y - n ÷ 2) # 居中
    return ind
end

function placement!(ground, sortedtrees, index::Number)
    for i in 1:length(sortedtrees)
        if i == index
            continue
        end
        overlap!(ground, sortedtrees[i])
    end
    placement!(ground, sortedtrees[index])
    # return ind
end
function placement!(ground, sortedtrees, indexes)
    for i in 1:length(sortedtrees)
        if i in indexes
            continue
        end
        overlap!(ground, sortedtrees[i])
    end
    for i in indexes
        placement!(ground, sortedtrees[i])
    end
    nothing
end

function locate(qt::AbstractStackedQtree, ind::Tuple{Int, Int, Int}=(levelnum(qt), 1, 1))
    if qt[ind] == EMPTY
        return ind
    end
    unempty = (-1, -1, -1)
    for ci in 1:4
        c = child(ind, ci)
        if qt[c] != EMPTY
            if unempty[1] == -1 #only one empty child
                unempty = c
            else
                return ind #multiple empty child
            end
        end
    end
    return locate(qt, unempty)
end
IndType = Tuple{Int, Int, Int}
LocQtreeType = QtreeNode{NamedTuple{(:loc, :cumloc, :ind),Tuple{Array{Any,1},Array{Any,1}, IndType}}}
LocQtreeTypeInt = QtreeNode{NamedTuple{(:loc, :cumloc, :ind),Tuple{Array{Int,1},Array{Int,1}, IndType}}}
LocQtree(ind) = LocQtreeType((loc = Vector(), cumloc = Vector(), ind=ind))
LocQtreeInt(ind) = LocQtreeTypeInt((loc = Vector{Int}(), cumloc = Vector{Int}(), ind=ind))
function locate!(qt::AbstractStackedQtree, loctree::QtreeNode=LocQtree((levelnum(qt), 1, 1)),
    ind::Tuple{Int, Int, Int}=(levelnum(qt), 1, 1); label=qt, newnode=LocQtree)
    if qt[ind] == EMPTY
        return loctree
    end
    unempty = (-1, -1, -1)
    unemptyci = -1
    for ci in 1:4
        c = child(ind, ci)
        if qt[c] != EMPTY
            if unemptyci == -1 #only one empty child
                unempty = c
                unemptyci = ci
            else
                push!(loctree.value.loc, label)
                return loctree #multiple empty child
            end
        end
    end
    if loctree.children[unemptyci] === nothing
        loctree.children[unemptyci] = newnode(unempty)
    end
    push!(loctree.value.cumloc, label)
    locate!(qt, loctree.children[unemptyci], unempty, label=label, newnode=newnode)
    return loctree
end

function locate!(qts::AbstractVector, loctree::QtreeNode=LocQtreeInt((levelnum(qts[1]), 1, 1))) #must have same levelnum
    for (i, qt) in enumerate(qts)
        locate!(qt, loctree, label=i, newnode=LocQtreeInt)
    end
    loctree
end
function locate!(qts::AbstractVector, inds::Union{AbstractVector{Int}, AbstractSet{Int}}, 
        loctree::QtreeNode=LocQtreeInt((levelnum(qts[1]), 1, 1))) #must have same levelnum
    for i in inds
        locate!(qts[i], loctree, label=i, newnode=LocQtreeInt)
    end
    loctree
end


function listcollision_qtree(qtrees::AbstractVector, mask::AbstractStackedQtree, loctree::QtreeNode;
    collist = Vector{ColItemType}(),
    queue =  Vector{Tuple{Int, Int, Int}}(),
    )
    nodequeue = [loctree]

    while !isempty(nodequeue)
        loctree = popfirst!(nodequeue)
        if length(loctree.value.loc) > 1
#             @show length(loctree.value.loc), length(loctree.value.cumloc)
            indpairs = combinations(loctree.value.loc, 2) |> collect
            indpairs = [(min(p...), max(p...)) for p in indpairs] |> shuffle!
            listcollision_native(qtrees, mask, indpairs, collist=collist, queue=queue, at=loctree.value.ind)
        end
        if length(loctree.value.loc) > 0 && length(loctree.value.cumloc) > 0
            indpairs = Iterators.product(loctree.value.cumloc, loctree.value.loc) |> collect |> vec
            indpairs = [(min(p...), max(p...)) for p in indpairs] |> shuffle!
            listcollision_native(qtrees, mask, indpairs, collist=collist, queue=queue, at=loctree.value.ind)
        end
        for c in loctree.children
            if c !== nothing
                push!(nodequeue, c)
            end
        end
    end
    collist
end
function listcollision_qtree(qtrees::AbstractVector, mask::AbstractStackedQtree; kargs...)
    loctree = locate!(qtrees)
    loctree = locate!(mask, loctree, label=0, newnode=LocQtreeInt)
    listcollision_qtree(qtrees, mask, loctree; kargs...)
end
function listcollision_qtree(qtrees::AbstractVector, mask::AbstractStackedQtree, inds::Union{AbstractVector{Int}, AbstractSet{Int}}; kargs...)
    loctree = locate!(qtrees, inds)
    loctree = locate!(mask, loctree, label=0, newnode=LocQtreeInt)
    listcollision_qtree(qtrees, mask, loctree; kargs...)
end

function listcollision(qtrees::AbstractVector, mask::AbstractStackedQtree, args...; kargs...)
    if length(qtrees) > 25
        return listcollision_qtree(qtrees, mask, args...; kargs...)
    else
        return listcollision_native(qtrees, mask, args...; kargs...)
    end
end
