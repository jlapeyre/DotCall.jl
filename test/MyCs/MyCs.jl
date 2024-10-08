module MyCs

using DotCall: @dotcallify

export MyC, x, s

struct MyC{T}
    data::T
end

@dotcallify MyC getproperty=mygetfield (f, g)

mygetfield(c::MyC, sym::Symbol) = getfield(c, sym)

f(a::MyC, x) = a.data + x

end # module MyCs
