using Combinatorics
using Random

function maskqtree(pic::AbstractMatrix{UInt8})
    m = log2(max(size(pic)...)*1.2)
    qt = ShiftedQtree(pic, 2^ceil(Int, m), default=QTree.FULL)
    a, b = size(pic)
    setrshift!(qt[1], -(m-a)÷2)
    setcshift!(qt[1], -(m-b)÷2)
    return qt
end
function maskqtree(pic::AbstractMatrix)
    pic = map(x -> x==1 ? QTree.FULL : QTree.EMPTY, pic)
    maskqtree(pic)
end

near(a::Integer, b::Integer; r=1) = a-r:a+r, b-r:b+r
near(m::AbstractMatrix, a::Integer, b::Integer; r=1) = (i->getindex(m, i...)).(
    collect(Iterators.product(near(a,b;r=r)...)))
const directkernel = collect.(Iterators.product(-1:1,-1:1))
decode2(c) = [0, 2, 1][c.&0x03]
whitesum(m::AbstractMatrix) = sum(directkernel .* m)
whitesum(t::ShiftedQtree, l, a, b) = whitesum(decode2(near(t[l],a,b)))

function trainstep!(t1, t2, cp::Tuple{Integer, Integer, Integer}, downlevel=2)
    l = cp[1]
    ws1 = whitesum(t1, cp...)
    ws2 = whitesum(t2, cp...)
    if all(ws1 .== ws2) #避免运动一致，相当于不运动
        ws1 = [rand((0,1,-1)), rand((0,1,-1))]
    end
   
    ul1 = log2(max(abs.(ws1)...)) #幂等级
    ul2 = log2(max(abs.(ws2)...))
#     @show ws1, ws2
#     @show l,ul1,ul2
    if ul1 >= 0 #abs(ws1)>=1
        u = floor(Int, ul1)
        shift!(t1, max(1, l+u-downlevel), (ws1 .÷ 2^u)...) #舍尾，保留最高二进制位
#         @show (ws1 .÷ 2^u)
    end
    if ul2 >= 0
        u = floor(Int, ul2)
        shift!(t2, max(1, l+u-downlevel), (ws2 .÷ 2^u)...)
#         @show (ws2 .÷ 2^u)
    end
end
function trainstep_mask!(mask, t2, cp::Tuple{Integer, Integer, Integer}, downlevel=2)
    l = cp[1]
    ws1 = whitesum(mask, cp...)
    ws2 = whitesum(t2, cp...)
    if all(ws1 .== ws2) #避免运动一致，相当于不运动
        ws1 = [rand((0,1,-1)), rand((0,1,-1))]
    end
    ws = ws2 .- ws1
    ws = apply!(optimiser, t2, Float64.(ws))
    ul = log2(max(abs.(ws)...)) #幂等级
    if ul >= 0
        u = floor(Int, ul)
        shift!(t2, max(1, l+u-downlevel-1), (ws .÷ 2^u)...)
#         @show (ws .÷ 2^u)
    end
end

function trainepoch(ts, dl=2, spdl=4; splevel=-7)
    splevel = splevel<0 ? levelnum(ts[1])+splevel : splevel
    splevel = splevel<1 ? 1 : splevel
    nsp = 0
    sts = combinations(ts,2)|>collect|>shuffle
    for (t1, t2) in sts
        c, cp = collision_bfs_rand(t1, t2)
        if c
            trainstep!(t1, t2, cp, dl)
            nsp += 1
        elseif cp[1] < splevel
#             print("s")
            trainstep!(t1, t2, cp, spdl)
        end
    end
    nsp
end

function train_step_ind(mask, ts, i1, i2, cp, dl)
    if i1 == 0
        trainstep_mask!(mask, ts[i2], cp, dl)
    elseif i2 == 0
        trainstep_mask!(mask, ts[i1], cp, dl)
    else
        trainstep!(ts[i1], ts[i2], cp, dl)
    end
end

function trainepoch(ts, mask, dl=2, spdl=4; splevel=-7)
    splevel = splevel<0 ? levelnum(ts[1])+splevel : splevel
    splevel = splevel<1 ? 1 : splevel
    nsp = 0
    indpairs = combinations(0:length(ts),2)|>collect|>shuffle
    getqt(i) = i==0 ? mask : ts[i]
    for (i1, i2) in indpairs
        c, cp = collision_bfs_rand(getqt(i1), getqt(i2))
        if c
            train_step_ind(mask, ts, i1, i2, cp, dl)
            nsp += 1
        elseif cp[1] < splevel
#             print("s")
            train_step_ind(mask, ts, i1, i2, cp, dl)
        end
    end
    nsp
end
                        
function trainepoch_gen(ts, mask, dl=2, spl=-2)
    spl = spl<0 ? levelnum(ts[1])+spl : spl
    spl = spl<1 ? 1 : spl
    nsp = 0
    indpairs = combinations(0:length(ts),2)|>collect|>shuffle
    getqt(i) = i==0 ? mask : ts[i]
    nearpool = Vector{Tuple{Int,Int}}()
    for (i1, i2) in indpairs        
        c, cp = collision_bfs_rand(getqt(i1), getqt(i2))
        if c
            train_step_ind(mask, ts, i1, i2, cp, dl)
            push!(nearpool, (i1, i2))
            nsp += 1
        elseif cp[1] < spl
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
        for (i1, i2) in nearpool|>shuffle
            c, cp = collision_bfs_rand(getqt(i1), getqt(i2))
            if c
                train_step_ind(mask, ts, i1, i2, cp, dl)
                push!(collpool, (i1, i2))
            end
        end
        if length(collpool) == 0 return nsp end
        for ci in 1:(4length(nearpool)÷length(collpool))
            nsp2 = 0
            for (i1, i2) in collpool|>shuffle
                c, cp = collision_bfs_rand(getqt(i1), getqt(i2))
                if c
                    train_step_ind(mask, ts, i1, i2, cp, dl)
                    nsp2 += 1
                end
            end
            if nsp2 == 0
                return nsp
            end
        end
#         @show length(indpairs),length(nearpool),length(collpool)
    end
    nsp
end