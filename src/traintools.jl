mutable struct ListNode{T}
    value::Union{Nothing, T}
    prev::Union{Nothing, ListNode}
    next::Union{Nothing, ListNode}
end
ListNode(value) = ListNode(value, nothing, nothing)
ListNode{T}(value) where T = ListNode{T}(value, nothing, nothing)

mutable struct DoubleList{T}
    head::ListNode{T}
    tail::ListNode{T}
end
function DoubleList{T}() where T
    h = ListNode{T}(nothing)
    t = ListNode{T}(nothing)
    h.next = t
    t.prev = h
    DoubleList(h, t)
end

function Base.pushfirst!(l::DoubleList, n::ListNode)
    n.next = l.head.next
    n.prev = l.head
    l.head.next = n
    n.next.prev = n
    n
end
function Base.pop!(l::DoubleList, n::ListNode)
    n.prev.next = n.next
    n.next.prev = n.prev
    n
end
function movetofirst!(l::DoubleList, n::ListNode)
    pop!(l, n)
    pushfirst!(l, n)
end

function take!(l::DoubleList, collection)
    p = l.head.next
    while p !== l.tail
        push!(collection, p.value)
        p = p.next
    end
    collection
end
function take!(l::DoubleList, collection, firstn)
    p = l.head.next
    for i in 1:firstn
        if p === l.tail
            break
        end
        push!(collection, p.value)
        p = p.next
    end
    collection
end
function take(l::DoubleList{T}, args...) where T
    collection = Vector{T}()
    take!(l, collection, args...)
end

struct LRU{T, MAPTYPE}
    list::DoubleList{T}
    map::MAPTYPE
end
LRU{T}() where T = LRU{T, Dict}(DoubleList{T}(), Dict())
LRU{T}(map::U) where {T, U} = LRU{T, U}(DoubleList{T}(), map)

function Base.push!(lru::LRU, v)
    if haskey(lru.map, v)
        n = lru.map[v]
        movetofirst!(lru.list, n)
    else
        n = ListNode(v)
        lru.map[v] = n
        pushfirst!(lru.list, n)
    end
    v
end
take!(lru::LRU, args...) = take!(lru.list, args...)
take(lru::LRU, args...) = take(lru.list, args...)
Base.broadcastable(lru::LRU) = Ref(lru)
struct IntMap{T}
    map::Vector{ListNode{T}}
end
IntMap{T}(n::Int) where T = IntMap{T}(Vector{ListNode{T}}(undef, n))
Base.haskey(im::IntMap, key) = isassigned(im.map, key)
Base.getindex(im::IntMap, ind...) = getindex(im.map, ind...)
Base.setindex!(im::IntMap, v, ind...) = setindex!(im.map, v, ind...)

intlru(n) = LRU{Int}(IntMap{Int}(n))

mutable struct MemSet
    mem::Vector{Set{Int}}
    shift::Int
end

MemSet(n::Int) = MemSet([Set{Int}() for i in 1:n], 0)
getmem(ms::MemSet, g=1) = ms.mem[((g-1)+ms.shift)%length(ms.mem)+1]
function Base.push!(ms::MemSet, mem)
    m = getmem(ms, 1)
    empty!(m)
    for e in mem
        push!(m, e)
    end
    ms.shift += 1
end

take(ms::MemSet) = union(ms.mem...)