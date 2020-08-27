using Combinatorics
using Random
using .QTree


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
intlog2(x::Number)=Int[0,1,1,2,2,2,2,3,3,3,3,3,3,3][x]

function move!(qt, ws)
    if (-1<ws[1]<1 && -1<ws[2]<1) || rand()<0.1 #避免静止及破坏周期运动
        ws .+= [rand((1,-1)), rand((1,-1))]
    end
    wm = max(abs.(ws)...)
    if wm >= 1
        u = floor(Int, log2(wm))
        shift!(qt, 1+u, (trunc.(Int, ws) .÷ 2^u)...) #舍尾，保留最高二进制位
    end
end

function trainstep!(t1, t2, collisionpoint::Tuple{Integer, Integer, Integer}, optimiser=(t, Δ)->Δ./4)
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
            ws1 = ws1 .- ws2
        end
        move!(t1, ws1)
    end
    if move2
        if !move1
            ws2 = ws2 .- ws1
        end
        move!(t2, ws2)
    end
end
function trainstep_mask!(mask, t2, collisionpoint::Tuple{Integer, Integer, Integer}, optimiser=(t, Δ)->Δ./4)
    l = collisionpoint[1]
    ll = 2 ^ (l-1)
    ws1 = ll .* whitesum(mask, collisionpoint...)
    ws2 = ll .* whitesum(t2, collisionpoint...)
    ws1 = optimiser(mask, ws1)
    ws2 = optimiser(t2, ws2)
    ws = (ws2 .- ws1) ./ 2
    move!(t2, ws)
end

function trainepoch!(qtrees; optimiser=(t, Δ)->Δ./4, optimiser_near=(t, Δ)->Δ./4, nearlevel=0)
    nearlevel = nearlevel<0 ? levelnum(qtrees[1])+nearlevel : nearlevel
    collision_times = 0
    pairs = combinations(qtrees, 2) |> collect |> shuffle!
    etp = typeof(levelnum(qtrees[1]))
    q =  Vector{Tuple{etp, etp, etp}}()
    for (t1, t2) in pairs
        empty!(q)
        push!(q, (levelnum(t1), 1, 1))
        cp = collision_bfs_rand(t1, t2, q)
        if cp[1] >= 0
            trainstep!(t1, t2, cp, optimiser)
            collision_times += 1
        elseif cp[1] < nearlevel
#             print("s")
            trainstep!(t1, t2, cp, optimiser_near)
        end
    end
    collision_times
end

function train_step_ind!(mask, qtrees, i1, i2, collisionpoint, optimiser)
#     @show i1, i2
    if i1 == 0
        trainstep_mask!(mask, qtrees[i2], collisionpoint, optimiser)
    elseif i2 == 0
        trainstep_mask!(mask, qtrees[i1], collisionpoint, optimiser)
    else
        trainstep!(qtrees[i1], qtrees[i2], collisionpoint, optimiser)
    end
end


function trainepoch!(qtrees, mask; optimiser=(t, Δ)->Δ./4, optimiser_near=(t, Δ)->Δ./4, nearlevel=0, queue=Vector{Tuple{Int, Int, Int}}(), collpool=nothing)
    nearlevel = nearlevel<0 ? levelnum(qtrees[1])+nearlevel : nearlevel
    nsp = 0
    indpairs = combinations(0:length(qtrees), 2) |> collect |> shuffle!
    getqtree(i) = i==0 ? mask : qtrees[i]
    if collpool !== nothing
        empty!(collpool)
    end
    for (i1, i2) in indpairs
        t1 = getqtree(i1)
        t2 = getqtree(i2)
        empty!(queue)
        cp = collision_bfs_rand(t1, t2, queue)
#         @show cp
        if cp[1] >= 0
            train_step_ind!(mask, qtrees, i1, i2, cp, optimiser)
            nsp += 1
            if collpool !== nothing
                push!(collpool, (i1, i2))
            end
        elseif -cp[1] < nearlevel
            print("s")
            train_step_ind!(mask, qtrees, i1, i2, .-cp, optimiser_near)
        end
    end
    nsp
end

function filttrain!(mask, qtrees, inpool, outpool, nearlevel2, optimiser)
    getqt(i) = i==0 ? mask : qtrees[i]
    if outpool !== nothing
        empty!(outpool)
    end
    nsp1 = 0
    for (i1, i2) in inpool |> shuffle!
        cp = collision_bfs_rand(getqt(i1), getqt(i2))
        if cp[1] >= 0
            train_step_ind!(mask, qtrees, i1, i2, cp, optimiser)
            if outpool !== nothing
                push!(outpool, (i1, i2))
            end
            nsp1 += 1
        elseif -cp[1] < nearlevel2 && outpool !== nothing
            push!(outpool, (i1, i2))
        end
    end
    nsp1
end

function trainepoch_gen!(qtrees, mask; optimiser=(t, Δ)->Δ./4, nearlevel=levelnum(qtrees[1])/2, queue=Vector{Tuple{Int, Int, Int}}(), nearpool = Vector{Tuple{Int,Int}}(), collpool = Vector{Tuple{Int,Int}}())
    nearlevel = max(1, nearlevel<0 ? levelnum(qtrees[1])+nearlevel : nearlevel)
    indpairs = combinations(0:length(qtrees), 2) |> collect |> shuffle!
    @time nsp = filttrain!(mask, qtrees, indpairs, nearpool, nearlevel, optimiser)
    if nsp == 0 return nsp end 
    @show "###",length(indpairs), length(nearpool), length(nearpool)/length(indpairs)

    @time for ni in 1 : length(indpairs)÷length(nearpool) #the loop cost should not exceed length(indpairs)
        nsp1 = filttrain!(mask, qtrees, nearpool, collpool, 0, optimiser)
        @show nsp1
        if ni > 8nsp1 break end # loop only when there are enough collisions

        for ci in 1 : length(nearpool)÷length(collpool) #the loop cost should not exceed length(nearpool)
            nsp2 = filttrain!(mask, qtrees, collpool, nothing, 0, optimiser)
            if ci > 4nsp2 break end # loop only when there are enough collisions
        end
        # @show length(indpairs),length(nearpool),collpool
    end
    nsp
end

function trainepoch_gen2!(qtrees, mask; optimiser=(t, Δ)->Δ./4, 
    nearlevel1=levelnum(qtrees[1])*0.75, 
    nearlevel2=levelnum(qtrees[1])*0.5, 
    queue=Vector{Tuple{Int, Int, Int}}(), 
    nearpool1 = Vector{Tuple{Int,Int}}(), 
    nearpool2 = Vector{Tuple{Int,Int}}(), 
    collpool = Vector{Tuple{Int,Int}}()
    )
    nearlevel1 = max(1, nearlevel1<0 ? levelnum(qtrees[1])+nearlevel1 : nearlevel1)
    nearlevel2 = max(1, nearlevel2<0 ? levelnum(qtrees[1])+nearlevel2 : nearlevel2)

    indpairs = combinations(0:length(qtrees), 2) |> collect |> shuffle!
    nsp = filttrain!(mask, qtrees, indpairs, nearpool1, nearlevel1, optimiser)
    if nsp == 0 return nsp end 
    @show "###", length(nearpool1), length(nearpool1)/length(indpairs)

    @time for ni1 in 1 : length(indpairs)÷length(nearpool1) #the loop cost should not exceed length(indpairs)
        nsp1 = filttrain!(mask, qtrees, nearpool1, nearpool2, nearlevel2, optimiser)
        if ni1 > nsp1 break end # loop only when there are enough collisions
        @show nsp, nsp1
        @show "####", length(nearpool2), length(nearpool2)/length(nearpool1)

        @time for ni2 in 1 : length(nearpool1)÷length(nearpool2) #the loop cost should not exceed length(indpairs)
            nsp2 = filttrain!(mask, qtrees, nearpool2, collpool, 0, optimiser)
            @show nsp2# length(collpool)/length(nearpool2)
            if nsp2==0 || ni2 > 4+nsp2 break end # loop only when there are enough collisions

            for ci in 1 : length(nearpool2)÷length(collpool) #the loop cost should not exceed length(nearpool)
                nsp3 = filttrain!(mask, qtrees, collpool, nothing, 0, optimiser)
                if ci > 4nsp3 break end # loop only when there are enough collisions
            end
            # @show length(indpairs),length(nearpool),collpool
        end
    end
    nsp
end

function train!(ts, maskqt, nepoch=1, args...; callbackstep=0, callbackfun=x->x, queue=Vector{Tuple{Int, Int, Int}}(), kargs...)
    ep = 0
    nc = 0
    while true
        nc = trainepoch!(ts, maskqt, args...; queue=queue, kargs...)
        ep += 1
        if callbackstep>0 && ep%callbackstep==0
            callbackfun(ep)
        end
        if ep >= nepoch || nc == 0
            break
        end
    end
    ep, nc
end

function train_gen!(ts, maskqt, nepoch=1, args...; callbackstep=0, callbackfun=x->x, queue=Vector{Tuple{Int, Int, Int}}(), kargs...)
    ep = 0
    nc = 0
    while true
        nc = trainepoch_gen!(ts, maskqt, args...; queue=queue, kargs...)
        ep += 1
        if callbackstep>0 && ep%callbackstep==0
            callbackfun(ep)
        end
        if ep >= nepoch || nc == 0
            break
        end
    end
    ep, nc
end

function teleport!(ts, maskqt, args...; kargs...)
    outinds = outofbounds(maskqt, ts)
    if !isempty(outinds)
        placement!(deepcopy(maskqt), ts, outinds)
        return outinds
    end
    cinds = collisional_indexes_rand(ts, maskqt, args...; kargs...)
    if cinds !== nothing && length(cinds)>0
        placement!(deepcopy(maskqt), ts, cinds)
    end
    return cinds
end


function train_with_teleport!(ts, maskqt, nepoch::Number, args...; 
        trainer=trainepoch_gen!, patient::Number=5, callbackstep=0, callbackfun=x->x,
        queue=Vector{Tuple{Int, Int, Int}}(), collpool = Vector{Tuple{Int,Int}}(), kargs...)
    ep = 0
    nc = 0
    count = 0
    nc_min = Inf
    while ep < nepoch
        @show "##", ep, nc, length(collpool), (count,nc_min)
        nc = trainer(ts, maskqt, args...; collpool=collpool, queue=queue, kargs...)
        ep += 1
        count += 1
        if nc < nc_min
            count = 0
            nc_min = nc
        end
        if nc != 0 && length(collpool)>0 && (count >= patient || count > length(collpool)) #超出耐心或少数几个碰撞
            count = 0
            nc_min = nc
            cinds = teleport!(ts, maskqt, collpool=collpool)
            println("@epoch $ep, count $count collision $nc teleport $cinds")
        end
        if callbackstep>0 && ep%callbackstep==0
            callbackfun(ep)
        end
        if nc == 0
            return ep, nc
        end
    end
    ep, nc
end