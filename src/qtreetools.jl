# q1cc = [0,0,0]
# q2cc = [0,0,0]
function collision_bfs_rand(Q1::AbstractStackQtree, Q2::AbstractStackQtree, q=[(levelnum(Q1), 1, 1)])
#     @assert size(Q1) == size(Q2)
    if isempty(q)
        push!(q, (levelnum(Q1), 1, 1))
    end
    i = @inbounds q[1]
    while !isempty(q)
        i = popfirst!(q)
        for cn in shuffle4()
            ci = child(i, cn)
            q2 = _getindex(Q2, ci)
            # q1 = _getindex(Q1, ci)
            # q1cc[q1] += 1 result ratio [1.4, 0.002, 1.0] EMPTY > MIX > FULL
            # q2cc[q2] += 1 result ratio [2.6, 0.002, 1.0]
            cond = q2 == EMPTY
            if cond #q2 is smaller, so it's more empty
                continue
            elseif q2 == MIX
                q1 = _getindex(Q1, ci)
                if q1 == EMPTY
                    continue
                elseif q1 == MIX
                    push!(q, ci)
                    continue
                else
                    return ci
                end
            else
                q1 = _getindex(Q1, ci)
                if q1 == EMPTY
                    continue
                end
                return ci
            end
        end
    end
    return .- i # no collision
end

ColItemType = Pair{Tuple{Int,Int},Tuple{Int,Int,Int}}
function batchcollision_native(qtrees::AbstractVector, mask::AbstractStackQtree, 
        indpairs; collist=Vector{ColItemType}(),
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
function batchcollision_native(qtrees::AbstractVector, mask::AbstractStackQtree, 
    indpairs::Vector{Tuple{Tuple{Integer,Integer},Tuple{Integer,Integer,Integer}}}; collist=Vector{ColItemType}(),
    queue=Vector{Tuple{Int,Int,Int}}())
    getqtree(i) = i==0 ? mask : qtrees[i]
    for ((i1, i2), at) in indpairs
        empty!(queue)
        push!(queue, at)
        cp = collision_bfs_rand(getqtree(i1), getqtree(i2), queue)
        if cp[1] >= 0
            push!(collist, (i1,i2)=>cp)
        end
    end
    collist
end
function batchcollision_native(qtrees::AbstractVector, mask::AbstractStackQtree, 
    inds::AbstractVector{<:Integer}=0:length(qtrees); collist=Vector{ColItemType}(), 
    queue=Vector{Tuple{Int,Int,Int}}(), at=(levelnum(qtrees[1]), 1, 1))
    getqtree(i) = i==0 ? mask : qtrees[i]
    l = length(inds)
    for i in 1:l
        for j in i+1:l
            empty!(queue)
            push!(queue, at)
            @inbounds i1 = inds[i]
            @inbounds i2 = inds[j]
            cp = collision_bfs_rand(getqtree(i1), getqtree(i2), queue)
            if cp[1] >= 0
                push!(collist, (i1,i2)=>cp)
            end
        end
    end
    collist
end
function batchcollision_native(qtrees::AbstractVector, mask::AbstractStackQtree, 
    inds::AbstractSet{<:Integer}; kargs...)
   batchcollision_native(qtrees, mask, inds|>collect; kargs...)
end

function findroom_uniform(ground, q=[(levelnum(ground), 1, 1)])
    if isempty(q)
        push!(q, (levelnum(ground), 1, 1))
    end
    while !isempty(q)
        i = popfirst!(q)
#         @show i
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
                elseif ground[ci] == MIX
                    push!(q, ci)
                end
            end
        end
    end
    return nothing
end
function findroom_gathering(ground, q=[]; level=5, p=2)
    if isempty(q)
        l = max(1, levelnum(ground)-level)
        s = size(ground[l], 1)
        append!(q, ((l, i, j) for i in 1:s for j in 1:s if ground[l, i, j]!=FULL))
    end
    while !isempty(q)
        # @assert q[1][1] == q[end][1]
        ce = (1 + size(ground[q[1][1]], 1)) / 2
        h,w = kernelsize(ground)
        shuffle!(q)
        sort!(q, by=i->(abs((i[2]-ce)/h)^p+(abs(i[3]-ce)/w)^p)) #椭圆p范数
        lq = length(q)
        for n in 1:lq
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
                    elseif ground[ci] == MIX
                        push!(q, ci)
                    end
                end
            end
        end
    end
    return nothing
end
function treeset!(tree::ShiftedQtree, ind::Tuple{Int,Int,Int}, value::UInt8) #unused
    l, m1, n1 = ind
    m2, n2 = m1, n1
    for ll in l:-1:1
        tree[ll][m1:m2, n1:n2] .= value #goes wrong when out of kernel bounds
        m1 = 2m1 - 1
        m2 = 2m2
        n1 = 2n1 - 1
        n2 = 2n2
    end
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
function placement!(ground, sortedtrees; kargs...)
#     pos = Vector{Tuple{Int, Int, Int}}()
    ind = nothing
    for t in sortedtrees
        ind = placement!(ground, t; kargs...)
        overlap!(ground, t)
        if ind === nothing
            return ind
        end
#         push!(pos, ind)
    end
    ind
#     return pos
end

function placement!(ground, qtree::ShiftedQtree; roomfinder=findroom_uniform, kargs...)
    ind = roomfinder(ground; kargs...)
    # @show ind
    if ind === nothing
        return nothing
    end
    setcenter!(qtree, getcenter(ind)) # 居中
    return ind
end

function placement!(ground, sortedtrees, index::Number; kargs...)
    for i in 1:length(sortedtrees)
        if i == index
            continue
        end
        overlap!(ground, sortedtrees[i])
    end
    placement!(ground, sortedtrees[index]; kargs...)
end
function placement!(ground, sortedtrees, indexes; kargs...)
    for i in 1:length(sortedtrees)
        if i in indexes
            continue
        end
        overlap!(ground, sortedtrees[i])
    end
    ind = nothing
    for i in indexes
        ind = placement!(ground, sortedtrees[i]; kargs...)
        if ind === nothing return ind end
        overlap!(ground, sortedtrees[i])
    end
    ind
end

function locate(qt::AbstractStackQtree, ind::Tuple{Int, Int, Int}=(levelnum(qt), 1, 1))
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
function locate!(qt::AbstractStackQtree, loctree::QtreeNode=LocQtree((levelnum(qt), 1, 1)),
    ind::Tuple{Int, Int, Int}=(levelnum(qt), 1, 1); label=qt, newnode=LocQtree)
    if _getindex(qt, ind) == EMPTY
        return loctree
    end
    if ind[1] == 1
        push!(loctree.value.loc, label)
        return loctree
    end
    unempty = (-1, -1, -1)
    unemptyci = -1
    for ci in 1:4
        c = child(ind, ci)
        if _getindex(qt, c) != EMPTY
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

@assert collect(Iterators.product(1:2,4:6))[1] == (1,4)
function batchcollision_qtree(qtrees::AbstractVector, mask::AbstractStackQtree, loctree::QtreeNode;
    collist = Vector{ColItemType}(),
    queue =  Vector{Tuple{Int, Int, Int}}(),
    )
    nodequeue = [loctree]

    while !isempty(nodequeue)
        loctree = popfirst!(nodequeue)
        if length(loctree.value.loc) > 1
#             @show length(loctree.value.loc), length(loctree.value.cumloc)
            batchcollision_native(qtrees, mask, loctree.value.loc, collist=collist, queue=queue, at=loctree.value.ind)
        end
        if length(loctree.value.loc) > 0 && length(loctree.value.cumloc) > 0
            indpairs = Iterators.product(loctree.value.loc, loctree.value.cumloc)
            batchcollision_native(qtrees, mask, indpairs, collist=collist, queue=queue, at=loctree.value.ind)
        end
        for c in loctree.children
            if c !== nothing
                push!(nodequeue, c)
            end
        end
    end
    collist
end
function batchcollision_qtree(qtrees::AbstractVector, mask::AbstractStackQtree; kargs...)
    loctree = locate!(qtrees)
    loctree = locate!(mask, loctree, label=0, newnode=LocQtreeInt)
    batchcollision_qtree(qtrees, mask, loctree; kargs...)
end
function batchcollision_qtree(qtrees::AbstractVector, mask::AbstractStackQtree, inds::Union{AbstractVector{Int}, AbstractSet{Int}}; kargs...)
    loctree = locate!(qtrees, inds)
    loctree = locate!(mask, loctree, label=0, newnode=LocQtreeInt)
    batchcollision_qtree(qtrees, mask, loctree; kargs...)
end

function batchcollision(qtrees::AbstractVector, mask::AbstractStackQtree, args...; kargs...)
    if length(qtrees) > 25
        return batchcollision_qtree(qtrees, mask, args...; kargs...)
    else
        return batchcollision_native(qtrees, mask, args...; kargs...)
    end
end
