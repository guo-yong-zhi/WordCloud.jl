using Combinatorics
using Random
using .QTree

include("traintools.jl")
mutable struct Momentum
    eta::Float64
    rho::Float64
    velocity::IdDict
end

Momentum(η, ρ = 0.9) = Momentum(η, ρ, IdDict())
Momentum(;η = 0.01, ρ = 0.9) = Momentum(η, ρ, IdDict())

function apply(o::Momentum, x, Δ)
    η, ρ = o.eta, o.rho
    v = get!(o.velocity, x, Float64.(Δ))
    @. v = ρ * v + (1 - ρ) * Δ
    η * v
end
function apply!(o::Momentum, x, Δ)
    @. Δ = apply(o, x, Δ)
end
(opt::Momentum)(x, Δ) = apply(opt::Momentum, x, Δ)
    
function maskqtree(pic::AbstractMatrix{UInt8})
    m = log2(max(size(pic)...)*1.1)
    s = 2^ceil(Int, m)
    qt = ShiftedQtree(pic, s, default=QTree.FULL)
#     @show size(pic),m,s
    a, b = size(pic)
    setrshift!(qt[1], (s-a)÷2)
    setcshift!(qt[1], (s-b)÷2)
    return qt
end
function maskqtree(pic::AbstractMatrix, bgcolor=pic[1])
    pic = map(x -> x==bgcolor ? QTree.FULL : QTree.EMPTY, pic)
    maskqtree(pic)
end

near(a::Integer, b::Integer, r=1) = a-r:a+r, b-r:b+r
near(m::AbstractMatrix, a::Integer, b::Integer, r=1) = @view m[near(a, b, r)...]
const DIRECTKERNEL = collect.(Iterators.product(-1:1,-1:1))
const DECODETABLE = [0, 2, 1]
decode2(c) = DECODETABLE[c.&0x03]
whitesum(m::AbstractMatrix) = sum(DIRECTKERNEL .* m)
whitesum(t::ShiftedQtree, l, a, b) = whitesum(decode2(near(t[l],a,b)))
# function intlog2(x::Float64) #not safe
#     #Float64 符号位(S)，编号63；阶码位，编号62 ~52
#     b8 = reinterpret(UInt64, x)
#     m = UInt64(0x01)<<63 #符号位mask
#     Int(1-((b8&m)>>62)), Int((b8&(~m)) >> 52 - 1023) #符号位:1-2S (1->-1、0->1)，指数位 - 1023
# end
function intlog2(x::Float64) #not safe, x>0
    #Float64 符号位(S)，编号63；阶码位，编号62 ~52
    b8 = reinterpret(Int64, x)
    (b8 >> 52 - 1023) #符号位:1-2S (1->-1、0->1)，指数位 - 1023
end

function move!(qt, ws)
    if (-1<ws[1]<1 && -1<ws[2]<1) || rand()<0.1 #避免静止及破坏周期运动
        ws = [rand((1.,-1.)), rand((1.,-1.))]
    end
    wm = max(abs.(ws)...)
    # @assert wm >= 1
    u = intlog2(wm)
    # @assert u == floor(Int, log2(wm))
    shift!(qt, 1+u, (trunc.(Int, ws) .÷ 2^u)...) #舍尾，保留最高二进制位
end

function step!(t1, t2, collisionpoint::Tuple{Integer, Integer, Integer}, optimiser=(t, Δ)->Δ./4)
    ks1 = kernelsize(t1[1])
    ks1 = ks1[1] * ks1[2]
    ks2 = kernelsize(t2[1])
    ks2 = ks2[1] * ks2[2]
    l = collisionpoint[1]
    ll = 2 ^ (l-1)
    ws1 = ll .* whitesum(t1, collisionpoint...)
    ws2 = ll .* whitesum(t2, collisionpoint...)
    #     @show ws1,collisionpoint,whitesum(t1, collisionpoint...)
    ws1 = optimiser(t1, ws1)
#     @show ws1
    ws2 = optimiser(t2, ws2)
    move1 = rand()<ks2/ks1 #ks1越大移动概率越小，ks1<=ks2时必然移动（质量越大，惯性越大运动越少）
    move2 = rand()<ks1/ks2
    if move1
        if !move2
            ws1 .= ws1 .- ws2
        end
        move!(t1, ws1)
    end
    if move2
        if !move1
            ws2 .= ws2 .- ws1
        end
        move!(t2, ws2)
    end
end
function step_mask!(mask, t2, collisionpoint::Tuple{Integer, Integer, Integer}, optimiser=(t, Δ)->Δ./4)
    l = collisionpoint[1]
    ll = 2 ^ (l-1)
    ws1 = ll .* whitesum(mask, collisionpoint...)
    ws2 = ll .* whitesum(t2, collisionpoint...)
    ws1 = optimiser(mask, ws1)
    ws2 = optimiser(t2, ws2)
    ws2 .= (ws2 .- ws1) ./ 2
    move!(t2, ws2)
end

function step_ind!(mask, qtrees, i1, i2, collisionpoint, optimiser)
#     @show i1, i2
    if i1 == 0
        step_mask!(mask, qtrees[i2], collisionpoint, optimiser)
    elseif i2 == 0
        step_mask!(mask, qtrees[i1], collisionpoint, optimiser)
    else
        step!(qtrees[i1], qtrees[i2], collisionpoint, optimiser)
    end
end

function step_inds!(mask, qtrees, collist::Vector{QTree.ColItemType}, optimiser)
    for ((i1, i2), cp) in collist
#         @show cp
        # @assert cp[1] > 0
        step_ind!(mask, qtrees, i1, i2, cp, optimiser)
    end
end

"element-wise trainer"
trainepoch_E!(tr_ma) = Dict(:collpool=>Vector{QTree.ColItemType}(), :queue=>Vector{Tuple{Int, Int, Int}}())
trainepoch_E!(s::Symbol) = get(Dict(:patient=>10, :nepoch=>1000), s, nothing)
function trainepoch_E!(qtrees, mask; optimiser=(t, Δ)->Δ./4, 
    queue=Vector{Tuple{Int, Int, Int}}(), collpool=trainepoch_E!(:collpool))
    listcollision(qtrees, mask, queue=queue, collist=empty!(collpool))
    nc = length(collpool)
    if nc == 0 return nc end
    step_inds!(mask, qtrees, collpool, optimiser)
    inds = first.(collpool)|>Iterators.flatten|>Set
    pop!(inds,0, 0)
#     @show length(qtrees),length(inds)
    for ni in 1:length(qtrees)÷length(inds)
        listcollision(qtrees, mask, inds, queue=queue, collist=empty!(collpool))
        step_inds!(mask, qtrees, collpool, optimiser)
        if ni > 8length(collpool) break end
    end
    nc
end

"element-wise trainer with LRU"
trainepoch_EM!(tr_ma) = Dict(:collpool=>Vector{QTree.ColItemType}(), 
                            :queue=>Vector{Tuple{Int, Int, Int}}(), 
                            :memory=>intlru(length(tr_ma[1])))
trainepoch_EM!(s::Symbol) = get(Dict(:patient=>10, :nepoch=>1000), s, nothing)
function trainepoch_EM!(qtrees, mask; memory, optimiser=(t, Δ)->Δ./4, 
    queue=Vector{Tuple{Int, Int, Int}}(), collpool=Vector{QTree.ColItemType}())
    listcollision(qtrees, mask, queue=queue, collist=empty!(collpool))
    nc = length(collpool)
    if nc == 0 return nc end
    step_inds!(mask, qtrees, collpool, optimiser)
    inds = first.(collpool)|>Iterators.flatten|>Set
#     @show length(inds)
    pop!(inds,0, 0)
    push!.(memory, inds)
    inds = take(memory, length(inds)*2)
    for ni in 1:length(qtrees)÷length(inds)
        listcollision(qtrees, mask, inds, queue=queue, collist=empty!(collpool))
        step_inds!(mask, qtrees, collpool, optimiser)
        if ni > 4length(collpool) break end
        inds2 = first.(collpool)|>Iterators.flatten|>Set
        pop!(inds2,0, 0)
#         @show length(qtrees),length(inds),length(inds2)
        for ni2 in 1:length(inds)÷length(inds2)
            listcollision(qtrees, mask, inds2, queue=queue, collist=empty!(collpool))
            step_inds!(mask, qtrees, collpool, optimiser)
            if ni2 > 8length(collpool) break end
        end
    end
    nc
end
"element-wise trainer with LRU(more levels)"
trainepoch_EM2!(tr_ma) = trainepoch_EM!(tr_ma)
trainepoch_EM2!(s::Symbol) = trainepoch_EM!(s)
function trainepoch_EM2!(qtrees, mask; memory, optimiser=(t, Δ)->Δ./4, 
    queue=Vector{Tuple{Int, Int, Int}}(), collpool=Vector{QTree.ColItemType}())
    listcollision(qtrees, mask, queue=queue, collist=empty!(collpool))
    nc = length(collpool)
    if nc == 0 return nc end
    step_inds!(mask, qtrees, collpool, optimiser)
    inds = first.(collpool)|>Iterators.flatten|>Set
#     @show length(inds)
    pop!(inds,0, 0)
    push!.(memory, inds)
    inds = take(memory, length(inds)*4)
    for ni in 1:length(qtrees)÷length(inds)
        listcollision(qtrees, mask, inds, queue=queue, collist=empty!(collpool))
        step_inds!(mask, qtrees, collpool, optimiser)
        if ni > 4length(collpool) break end
        inds2 = first.(collpool)|>Iterators.flatten|>Set
        pop!(inds2,0, 0)
        push!.(memory, inds2)
        inds2 = take(memory, length(inds2)*2)
        for ni2 in 1:length(inds)÷length(inds2)
            listcollision(qtrees, mask, inds2, queue=queue, collist=empty!(collpool))
            step_inds!(mask, qtrees, collpool, optimiser)
            if ni2 > 4length(collpool) break end
            inds3 = first.(collpool)|>Iterators.flatten|>Set
            pop!(inds3,0, 0)
#             @show length(qtrees),length(inds),length(inds2),length(inds3)
            for ni3 in 1:length(inds2)÷length(inds3)
                listcollision(qtrees, mask, inds3, queue=queue, collist=empty!(collpool))
                step_inds!(mask, qtrees, collpool, optimiser)
                if ni3 > 8length(collpool) break end
            end
        end
    end
    nc
end

"element-wise trainer with LRU(more-more levels)"
trainepoch_EM3!(tr_ma) = trainepoch_EM!(tr_ma)
trainepoch_EM3!(s::Symbol) = trainepoch_EM!(s)
function trainepoch_EM3!(qtrees, mask; memory, optimiser=(t, Δ)->Δ./4, 
    queue=Vector{Tuple{Int, Int, Int}}(), collpool=Vector{QTree.ColItemType}())
    listcollision(qtrees, mask, queue=queue, collist=empty!(collpool))
    nc = length(collpool)
    if nc == 0 return nc end
    step_inds!(mask, qtrees, collpool, optimiser)
    inds = first.(collpool)|>Iterators.flatten|>Set
#     @show length(inds)
    pop!(inds,0, 0)
    push!.(memory, inds)
    inds = take(memory, length(inds)*8)
    for ni in 1:length(qtrees)÷length(inds)
        listcollision(qtrees, mask, inds, queue=queue, collist=empty!(collpool))
        step_inds!(mask, qtrees, collpool, optimiser)
        if ni > 4length(collpool) break end
        inds2 = first.(collpool)|>Iterators.flatten|>Set
        pop!(inds2,0, 0)
        push!.(memory, inds2)
        inds2 = take(memory, length(inds2)*4)
        for ni2 in 1:length(inds)÷length(inds2)
            listcollision(qtrees, mask, inds2, queue=queue, collist=empty!(collpool))
            step_inds!(mask, qtrees, collpool, optimiser)
            if ni2 > 4length(collpool) break end
            inds3 = first.(collpool)|>Iterators.flatten|>Set
            pop!(inds3,0, 0)
            push!.(memory, inds3)
            inds3 = take(memory, length(inds3)*2)
            for ni3 in 1:length(inds2)÷length(inds3)
                listcollision(qtrees, mask, inds3, queue=queue, collist=empty!(collpool))
                step_inds!(mask, qtrees, collpool, optimiser)
                if ni3 > 4length(collpool) break end
                inds4 = first.(collpool)|>Iterators.flatten|>Set
                pop!(inds4,0, 0)
#             @show length(qtrees),length(inds),length(inds2),length(inds3)
                for ni4 in 1:length(inds3)÷length(inds4)
                    listcollision(qtrees, mask, inds4, queue=queue, collist=empty!(collpool))
                    step_inds!(mask, qtrees, collpool, optimiser)
                    if ni4 > 8length(collpool) break end
                end
            end
        end
    end
    nc
end

function filttrain!(qtrees, mask, inpool, outpool, nearlevel2; optimiser, queue)
    getqt(i) = i==0 ? mask : qtrees[i]
    nsp1 = 0
    for (i1, i2) in inpool |> shuffle!
        cp = collision_bfs_rand(getqt(i1), getqt(i2), empty!(queue))
        if cp[1] >= nearlevel2
            if outpool !== nothing
                push!(outpool, (i1, i2))
            end
            if cp[1] > 0
                step_ind!(mask, qtrees, i1, i2, cp, optimiser)
                nsp1 += 1
            end
        end
    end
    nsp1
end

"pairwise trainer"
trainepoch_P!(tr_ma) = Dict(:collpool=>Vector{Tuple{Int, Int}}(),
                            :queue=>Vector{Tuple{Int, Int, Int}}(),
                            :nearpool=>Vector{Tuple{Int,Int}}())
trainepoch_P!(s::Symbol) = get(Dict(:patient=>10, :nepoch=>100), s, nothing)
function trainepoch_P!(qtrees, mask; optimiser=(t, Δ)->Δ./4, nearlevel=-levelnum(qtrees[1])/2, queue=Vector{Tuple{Int, Int, Int}}(), 
    nearpool = Vector{Tuple{Int,Int}}(), collpool = Vector{Tuple{Int, Int}}())
    nearlevel = min(-1, nearlevel)
    indpairs = combinations(0:length(qtrees), 2) |> collect |> shuffle!
    # @time 
    nsp = filttrain!(qtrees, mask, indpairs, empty!(nearpool), nearlevel, optimiser=optimiser, queue=queue)
    # @show nsp
    if nsp == 0 return 0 end 
    # @show "###",length(indpairs), length(nearpool), length(nearpool)/length(indpairs)

    # @time 
    for ni in 1 : length(indpairs)÷length(nearpool) #the loop cost should not exceed length(indpairs)
        nsp1 = filttrain!(qtrees, mask, nearpool, empty!(collpool), 0, optimiser=optimiser, queue=queue)
        # @show nsp, nsp1
        if ni > 8nsp1 break end # loop only when there are enough collisions

        for ci in 1 : length(nearpool)÷length(collpool) #the loop cost should not exceed length(nearpool)
            nsp2 = filttrain!(qtrees, mask, collpool, nothing, 0, optimiser=optimiser, queue=queue)
            if ci > 4nsp2 break end # loop only when there are enough collisions
        end
        # @show length(indpairs),length(nearpool),collpool
    end
    nsp
end

"pairwise trainer(more level)"
trainepoch_P2!(tr_ma) = Dict(:collpool=>Vector{Tuple{Int, Int}}(),
                            :queue=>Vector{Tuple{Int, Int, Int}}(),
                            :nearpool1=>Vector{Tuple{Int,Int}}(),
                            :nearpool2=>Vector{Tuple{Int,Int}}())
trainepoch_P2!(s::Symbol) = get(Dict(:patient=>2, :nepoch=>100), s, nothing)
function trainepoch_P2!(qtrees, mask; optimiser=(t, Δ)->Δ./4, 
    nearlevel1=-levelnum(qtrees[1])*0.75, 
    nearlevel2=-levelnum(qtrees[1])*0.5, 
    queue=Vector{Tuple{Int, Int, Int}}(), 
    nearpool1 = Vector{Tuple{Int,Int}}(), 
    nearpool2 = Vector{Tuple{Int,Int}}(), 
    collpool = Vector{Tuple{Int, Int}}()
    )
    nearlevel1 = min(-1, nearlevel1)
    nearlevel2 = min(-1, nearlevel2)

    indpairs = combinations(0:length(qtrees), 2) |> collect |> shuffle!
    nsp = filttrain!(qtrees, mask, indpairs, empty!(nearpool1), nearlevel1, optimiser=optimiser, queue=queue)
    # @show nsp
    if nsp == 0 return 0 end 
    # @show "###", length(nearpool1), length(nearpool1)/length(indpairs)

    # @time 
    for ni1 in 1 : length(indpairs)÷length(nearpool1) #the loop cost should not exceed length(indpairs)
        nsp1 = filttrain!(qtrees, mask, nearpool1, empty!(nearpool2), nearlevel2, optimiser=optimiser, queue=queue)
        if ni1 > nsp1 break end # loop only when there are enough collisions
        # @show nsp, nsp1
        # @show "####", length(nearpool2), length(nearpool2)/length(nearpool1)

        # @time
        for ni2 in 1 : length(nearpool1)÷length(nearpool2) #the loop cost should not exceed length(indpairs)
            nsp2 = filttrain!(qtrees, mask, nearpool2, empty!(collpool), 0, optimiser=optimiser, queue=queue)
            # @show nsp2# length(collpool)/length(nearpool2)
            if nsp2==0 || ni2 > 4+nsp2 break end # loop only when there are enough collisions

            for ci in 1 : length(nearpool2)÷length(collpool) #the loop cost should not exceed length(nearpool)
                nsp3 = filttrain!(qtrees, mask, collpool, nothing, 0, optimiser=optimiser, queue=queue)
                if ci > 4nsp3 break end # loop only when there are enough collisions
            end
            # @show length(indpairs),length(nearpool),collpool
        end
    end
    nsp
end

function levelpools(qtrees, levels=[-levelnum(qtrees[1]):2:-3..., -1])
    pools = [i=>Vector{Tuple{Int, Int}}() for i in levels]
#     @show typeof(pools)
    for (i1, i2) in combinations(0:length(qtrees), 2)
        push!(last(pools[1]), (i1, i2))
    end
    pools
end
"pairwise trainer(general levels)"
trainepoch_Px!(tr_ma) = Dict(:levelpools=>levelpools(tr_ma[1]),
                            :queue=>Vector{Tuple{Int, Int, Int}}())
trainepoch_Px!(s::Symbol) = get(Dict(:patient=>1, :nepoch=>10), s, nothing)
function trainepoch_Px!(qtrees, mask; 
    levelpools::AbstractVector{<:Pair{Int, <:AbstractVector{Tuple{Int, Int}}}} = levelpools(qtrees),
    optimiser=(t, Δ)->Δ./4, queue=Vector{Tuple{Int, Int, Int}}())
    last_nc = typemax(Int)
    nc = 0
    if (length(levelpools) == 0) return nc end
    outpool = length(levelpools)>= 2 ? last(levelpools[2]) : nothing
    outlevel = length(levelpools)>= 2 ? first(levelpools[2]) : 0
    inpool = last(levelpools[1])
    for niter in 1:typemax(Int)
        if outpool !== nothing empty!(outpool) end
        nc = filttrain!(qtrees, mask, inpool, outpool, outlevel, optimiser=optimiser, queue=queue)
        if first(levelpools[1]) < -levelnum(qtrees[1])+2
            r = outpool !== nothing ? length(outpool)/length(inpool) : 1
            println(niter, "#"^(-first(levelpools[1])), "$(first(levelpools[1])) pool:$(length(inpool))($r) nc:$nc ")
        end
        if (nc == 0) break end
#         if (nc < last_nc) last_nc = nc else break end
        if (niter > nc) break end
        if length(levelpools) >= 2
            trainepoch_Px!(qtrees, mask, levelpools=levelpools[2:end], optimiser=optimiser, queue=queue)
        end
    end
    nc
end

function teleport!(ts, maskqt, collpool, args...; kargs...)
    outinds = outofbounds(maskqt, ts)
    if !isempty(outinds)
        @show outinds
        placement!(deepcopy(maskqt), ts, outinds)
        return outinds
    end
    cinds = collisional_indexes_rand(ts, maskqt, collpool, args...; kargs...)
    if cinds !== nothing && length(cinds)>0
        placement!(deepcopy(maskqt), ts, cinds)
    end
    return cinds
end

function train!(ts, maskqt, nepoch::Number=-1, args...; 
        trainer=trainepoch_EM2!, patient::Number=trainer(:patient), optimiser=Momentum(η=1/4, ρ=0.5), 
        callbackstep=0, callbackfun=x->x, kargs...)
    ep = 0
    nc = 0
    count = 0
    nc_min = typemax(Int)
    teleport_count = 0
    last_cinds = nothing
    resource = trainer((ts, maskqt))
    collpool = nothing
    if :collpool in keys(resource)
        collpool = resource[:collpool]
    else
        collpool = resource[:levelpools][end] |> last
    end
    nepoch = nepoch >= 0 ? nepoch : trainer(:nepoch)
    @show nepoch, patient
    while ep < nepoch
#         @show "##", ep, nc, length(collpool), (count,nc_min)
        nc = trainer(ts, maskqt, args...; resource..., optimiser=optimiser, kargs...)
        ep += 1
        count += 1
        if nc < nc_min
            count = 0
            nc_min = nc
        end
        if nc != 0 && length(ts)/10>length(collpool)>0 && patient>0 && (count >= patient || count > length(collpool)) #超出耐心或少数几个碰撞
            nc_min = nc
            cinds = teleport!(ts, maskqt, collpool)
            println("@epoch $ep, count $count collision $nc($(length(collpool))) teleport $cinds to $(getshift.(ts[cinds]))")
            count = 0
            cinds_set = Set(cinds)
            if last_cinds == cinds_set
                teleport_count += 1
            else
                teleport_count = 0
            end
            last_cinds = cinds_set
        end
        if callbackstep>0 && ep%callbackstep==0
            callbackfun(ep)
        end
        if nc == 0
            return ep, nc
        end
        if teleport_count >= 10
            println("The teleport strategy failed after $ep epochs")
            return ep, nc
        end
        if count > max(2, 2patient, nepoch ÷ 10)
            println("training early break after $ep epochs")
            return ep, nc
        end
    end
    ep, nc
end
