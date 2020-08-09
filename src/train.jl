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
function maskqtree(pic::AbstractMatrix)
    pic = map(x -> x==pic[1] ? QTree.FULL : QTree.EMPTY, pic)
    maskqtree(pic)
end

near(a::Integer, b::Integer; r=1) = a-r:a+r, b-r:b+r
near(m::AbstractMatrix, a::Integer, b::Integer; r=1) = (i->getindex(m, i...)).(
    collect(Iterators.product(near(a,b;r=r)...)))
const directkernel = collect.(Iterators.product(-1:1,-1:1))
decode2(c) = [0, 2, 1][c.&0x03]
whitesum(m::AbstractMatrix) = sum(directkernel .* m)
whitesum(t::ShiftedQtree, l, a, b) = whitesum(decode2(near(t[l],a,b)))

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
        ul1 = log2(max(abs.(ws1)...)) #幂等级
        if ul1 >= 0
            u = floor(Int, ul1)
            shift!(t1, max(1, l+u-speeddown), (ws1 .÷ 2^u)...) #舍尾，保留最高二进制位
    #         @show (ws1 .÷ 2^u)
        end
    end
    if rand()<ks1/ks2
        ws2 = whitesum(t2, collisionpoint...)
        if ws2[1]==ws2[2]==0 || rand()<0.1 #避免静止及破坏周期运动
            ws2 .+= [rand((0,1,-1)), rand((0,1,-1))]
        end
        ul2 = log2(max(abs.(ws2)...))
        # @show ws2,ul2
        if ul2 >= 0
            u = floor(Int, ul2)
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
   
    ul = log2(max(abs.(ws)...)) #幂等级
    if ul >= 0
        u = floor(Int, ul)
        shift!(t2, max(1, l+u-speeddown-1), (ws .÷ 2^u)...)
#         @show (ws .÷ 2^u)
    end
end

function trainepoch!(qtrees, speeddown=2, speeddown_gap=4; gaplevel=0)
    gaplevel = gaplevel<0 ? levelnum(qtrees[1])+gaplevel : gaplevel
    collision_times = 0
    pairs = combinations(qtrees, 2) |> collect |> shuffle
    for (t1, t2) in pairs
        c, cp = collision_bfs_rand(t1, t2)
        if c
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
        c, cp = collision_bfs_rand(getqtree(i1), getqtree(i2))
        if c
            push!(collist, (i1, i2))
        end
    end
    collist
end

function trainepoch!(qtrees, mask; speeddown=2, speeddown_gap=4, gaplevel=0)
    gaplevel = gaplevel<0 ? levelnum(qtrees[1])+gaplevel : gaplevel
    nsp = 0
    indpairs = combinations(0:length(qtrees), 2) |> collect |> shuffle
    getqtree(i) = i==0 ? mask : qtrees[i]
    for (i1, i2) in indpairs
        c, cp = collision_bfs_rand(getqtree(i1), getqtree(i2))
        if c
            train_step_ind!(mask, qtrees, i1, i2, cp, speeddown)
            nsp += 1
        elseif cp[1] < gaplevel
            print("s")
            train_step_ind!(mask, qtrees, i1, i2, cp, speeddown_gap)
        end
    end
    nsp
end
                        
function trainepoch_gen!(qtrees, mask; speeddown=2, nearlevel=-4)
    nearlevel = nearlevel<0 ? levelnum(qtrees[1])+nearlevel : nearlevel
    nearlevel = nearlevel<1 ? 1 : nearlevel
    nsp = 0
    indpairs = combinations(0:length(qtrees),2) |> collect |> shuffle
    getqt(i) = i==0 ? mask : qtrees[i]
    nearpool = Vector{Tuple{Int,Int}}()
    for (i1, i2) in indpairs        
        c, cp = collision_bfs_rand(getqt(i1), getqt(i2))
        if c
            train_step_ind!(mask, qtrees, i1, i2, cp, speeddown)
            push!(nearpool, (i1, i2))
            nsp += 1
        elseif cp[1] < nearlevel
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
        for (i1, i2) in nearpool |> shuffle
            c, cp = collision_bfs_rand(getqt(i1), getqt(i2))
            if c
                train_step_ind!(mask, qtrees, i1, i2, cp, speeddown)
                push!(collpool, (i1, i2))
            end
        end
        if length(collpool) == 0 return nsp end
        for ci in 1:(4length(nearpool)÷length(collpool))
            nsp2 = 0
            for (i1, i2) in collpool |> shuffle
                c, cp = collision_bfs_rand(getqt(i1), getqt(i2))
                # @show getqt(i2)
                if c
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

function train!(ts, maskqt, nepoch=1, args...; callbackstep=0, callbackfun, kargs...)
    ep = 0
    nc = 0
    while true
        nc = trainepoch!(ts, maskqt, args...; kargs...)
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

function train_gen!(ts, maskqt, nepoch=1, args...; callbackstep=0, callbackfun, kargs...)
    ep = 0
    nc = 0
    while true
        nc = trainepoch_gen!(ts, maskqt, args...; kargs...)
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