module MyCs

using CBOO: @cboo_call

export MyC, x, s

struct MyC{T}
    data::T
end

@cboo_call MyC getproperty=mygetfield (f, g)

mygetfield(c::MyC, sym::Symbol) = getfield(c, sym)

f(a::MyC, x) = a.data + x

end # module MyCs
