using Combinatorics
using Random

using .QTree


function maskqtree(pic::AbstractMatrix{UInt8})
    m = log2(max(size(pic)...)*1.2)
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
near(m::AbstractMatrix, a::Integer, b::Integer; r=1) = @view m[near(a, b, r)...]
const DIRECTKERNEL = collect.(Iterators.product(-1:1,-1:1))
const DECODETABLE = [0, 2, 1]
decode2(c) = DECODETABLE[c.&0x03]
whitesum(m::AbstractMatrix) = sum(DIRECTKERNEL .* m)
whitesum(t::ShiftedQtree, l, a, b) = whitesum(decode2(near(t[l],a,b)))
intlog2(x::Number)=Int[0,1,1,2,2,2,2,3,3,3,3,3,3,3][x]
function trainstep!(t1, t2, collisionpoint::Tuple{Integer, Integer, Integer}, speeddown=2)
    l = collisionpoint[1]
    ks1 = kernelsize(t1[1])
    ks1 = ks1[1] * ks1[2]
    ks2 = kernelsize(t2[1])
    ks2 = ks2[1] * ks2[2]
    if rand()<ks2/ks1 #ks1越大移动概率越小，ks1<=ks2时必然移动（质量越大，惯性越大运动越少）
        ws1 = whitesum(t1, collisionpoint...)
        if ws1[1]==ws1[2]==0 || rand()<0.1 #避免静止及破坏周期运动
            ws1 .+= [rand((0,1,-1)), rand((0,1,-1))]
        end
        wm = max(abs.(ws1)...)
        if wm > 0
            u = intlog2(wm)
            shift!(t1, max(1, l+u-speeddown), (ws1 .÷ 2^u)...) #舍尾，保留最高二进制位
    #         @show (ws1 .÷ 2^u)
        end
    end
    if rand()<ks1/ks2
        ws2 = whitesum(t2, collisionpoint...)
        if ws2[1]==ws2[2]==0 || rand()<0.1 #避免静止及破坏周期运动
            ws2 .+= [rand((0,1,-1)), rand((0,1,-1))]
        end
        wm = max(abs.(ws2)...)
        if wm > 0
            u = intlog2(wm)
            shift!(t2, max(1, l+u-speeddown), (ws2 .÷ 2^u)...)
            # @show (ws2 .÷ 2^u)
        end
    end
end
function trainstep_mask!(mask, t2, collisionpoint::Tuple{Integer, Integer, Integer}, speeddown=2)
    l = collisionpoint[1]
    ws1 = whitesum(mask, collisionpoint...)
    ws2 = whitesum(t2, collisionpoint...)
    ws = ws2 .- ws1
    if ws[1]==ws[2]==0 || rand()<0.1 #避免静止及破坏周期运动
        ws .+= [rand((0,1,-1)), rand((0,1,-1))]
    end
   
    wm = max(abs.(ws)...) #幂等级
    if wm > 0
        u = intlog2(wm)
        shift!(t2, max(1, l+u-speeddown-1), (ws .÷ 2^u)...)
#         @show (ws .÷ 2^u)
    end
end

function trainepoch!(qtrees; speeddown=2, speeddown_gap=4, gaplevel=0)
    gaplevel = gaplevel<0 ? levelnum(qtrees[1])+gaplevel : gaplevel
    collision_times = 0
    pairs = combinations(qtrees, 2) |> collect |> shuffle!
    etp = typeof(levelnum(qtrees[1]))
    q =  Vector{Tuple{etp, etp, etp}}()
    for (t1, t2) in pairs
        empty!(q)
        push!(q, (levelnum(t1), 1, 1))
        cp = collision_bfs_rand(t1, t2, q)
        if cp[1] >= 0
            trainstep!(t1, t2, cp, speeddown)
            collision_times += 1
        elseif cp[1] < gaplevel
#             print("s")
            trainstep!(t1, t2, cp, speeddown_gap)
        end
    end
    collision_times
end

function train_step_ind!(mask, qtrees, i1, i2, collisionpoint, speeddown)
#     @show i1, i2
    if i1 == 0
        trainstep_mask!(mask, qtrees[i2], collisionpoint, speeddown)
    elseif i2 == 0
        trainstep_mask!(mask, qtrees[i1], collisionpoint, speeddown)
    else
        trainstep!(qtrees[i1], qtrees[i2], collisionpoint, speeddown)
    end
end

function list_collision(qtrees, mask)
    collist = []
    indpairs = combinations(0:length(qtrees), 2) |> collect
    getqtree(i) = i==0 ? mask : qtrees[i]
    for (i1, i2) in indpairs
        cp = collision_bfs_rand(getqtree(i1), getqtree(i2))
        if cp[1] >= 0
            push!(collist, (i1, i2))
        end
    end
    collist
end

function trainepoch!(qtrees, mask; speeddown=2, speeddown_gap=4, gaplevel=0, queue=Vector{Tuple{Int, Int, Int}}())
    gaplevel = gaplevel<0 ? levelnum(qtrees[1])+gaplevel : gaplevel
    nsp = 0
    indpairs = combinations(0:length(qtrees), 2) |> collect |> shuffle!
    getqtree(i) = i==0 ? mask : qtrees[i]
    for (i1, i2) in indpairs
        t1 = getqtree(i1)
        t2 = getqtree(i2)
        empty!(queue)
        cp = collision_bfs_rand(t1, t2, queue)
#         @show cp
        if cp[1] >= 0
            train_step_ind!(mask, qtrees, i1, i2, cp, speeddown)
            nsp += 1
        elseif -cp[1] < gaplevel
            train_step_ind!(mask, qtrees, i1, i2, .-cp, speeddown_gap)
        end
    end
    nsp
end
                        
function trainepoch_gen!(qtrees, mask; speeddown=2, nearlevel=-4, queue=Vector{Tuple{Int, Int, Int}}())
    nearlevel = nearlevel<0 ? levelnum(qtrees[1])+nearlevel : nearlevel
    nearlevel = nearlevel<1 ? 1 : nearlevel
    nsp = 0
    indpairs = combinations(0:length(qtrees),2) |> collect |> shuffle!
    getqt(i) = i==0 ? mask : qtrees[i]
    nearpool = Vector{Tuple{Int,Int}}()
    for (i1, i2) in indpairs
        t1 = getqt(i1)
        t2 = getqt(i2)
        empty!(queue)
        cp = collision_bfs_rand(t1, t2, queue)
        if cp[1] >= 0
            train_step_ind!(mask, qtrees, i1, i2, cp, speeddown)
            push!(nearpool, (i1, i2))
            nsp += 1
        elseif -cp[1] < nearlevel
            push!(nearpool, (i1, i2))
        end
    end
    if nsp == 0
        return nsp
    end 
    collpool = Vector{Tuple{Int,Int}}()
    if length(nearpool) == 0 return nsp end
    for ni in 1:(4length(indpairs)÷length(nearpool))
        empty!(collpool)
        for (i1, i2) in nearpool |> shuffle!
            cp = collision_bfs_rand(getqt(i1), getqt(i2))
            if cp[1] >= 0
                train_step_ind!(mask, qtrees, i1, i2, cp, speeddown)
                push!(collpool, (i1, i2))
            end
        end
        if length(collpool) == 0 return nsp end
        for ci in 1:(4length(nearpool)÷length(collpool))
            nsp2 = 0
            for (i1, i2) in collpool |> shuffle!
                cp = collision_bfs_rand(getqt(i1), getqt(i2))
                # @show getqt(i2)
                if cp[1] >= 0
                    train_step_ind!(mask, qtrees, i1, i2, cp, speeddown)
                    nsp2 += 1
                end
            end
            if nsp2 == 0
                return nsp
            end
        end
        # @show length(indpairs),length(nearpool),collpool
    end
    nsp
end

function train!(ts, maskqt, nepoch=1, args...; callbackstep=0, callbackfun=x->x, queue=Vector{Tuple{Int, Int, Int}}(), kargs...)
    ep = 0
    nc = 0
    while true
        nc = trainepoch!(ts, maskqt, args...; queue=queue, kargs...)
        ep += 1
        if ep >= nepoch || nc == 0
            break
        end
        if callbackstep>0 && ep%callbackstep==0
            callbackfun(ep)
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
        if ep >= nepoch || nc == 0
            break
        end
        if callbackstep>0 && ep%callbackstep==0
            callbackfun(ep)
        end
    end
    ep, nc
end

function teleport!(ts, maskqt, bgqt)
    outinds = outofbounds(maskqt, ts)
    if !isempty(outinds)
        placement!(bgqt, ts, outinds)
        return outinds
    end
    ci = max_collisional_index_rand(ts, maskqt)
    if ci !== nothing
        placement!(bgqt, ts, ci)
    end
    return ci
end

function train_with_teleport!(ts, maskqt, nepoch::Number, args...; 
        trainer=trainepoch_gen!, patient::Number=5, callbackstep=0, callbackfun=x->x, kargs...)
    ep = 0
    nc = 0
    count = 0
    nc_min = 1e6
    while ep < nepoch
        nc = trainer(ts, maskqt, args...; kargs...)
        ep += 1
        count += 1
        if nc < nc_min
            count = 0
            nc_min = nc
        end
        if nc == 0
            return ep, nc
        end
        if count >= patient
            count = 0
            nc_min = nc
            i = teleport!(ts, maskqt, maskqtree(mask.|>Gray)|>buildqtree!)
            @show ep,nc,i
        end
        if callbackstep>0 && ep%callbackstep==0
            callbackfun(ep)
        end
    end
    ep, nc
end