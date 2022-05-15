module MyAs

using CBOO: @cbooify

export MyA, x, sx

struct MyA{T}
    data::T
end

import Base: sin

#@cbooify MyA nothing getfield (x, sx, sin)
@cbooify MyA (sx, x, sin, y = 3, mycos = (a -> Base.cos(a.data)))

sx(a::MyA, x::Int) = a.data + x
x(a::MyA) = (a.data)^2
sin(a::MyA) = sin(a.data)

bf(a::MyA) = 1
cf(a::MyA) = 1

end # module MyAs
