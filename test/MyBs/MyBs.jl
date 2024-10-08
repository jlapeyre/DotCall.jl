module MyBs

using DotCall: @dotcallify

export MyB, x, sx, addto!

struct MyB{T}
    data::T
end

import Base: sin

@dotcallify MyB callmethod=addto! (x, sx, sin)

function addto!(a::MyB, gate, args...)
    (:addto!, gate(a, args...))
end



# Kind of dummy

sx(a::MyB, x::Int) = a.data + x
x(a::MyB) = (a.data)^2
sin(a::MyB) = sin(a.data)

end # module MyBs
