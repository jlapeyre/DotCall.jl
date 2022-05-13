module MyBs

using CBOO: @cboo_call

export MyB, x, sx, addto!

struct MyB{T}
    data::T
end

import Base: sin

@cboo_call MyB callmethod=addto! (x, sx, sin)

function addto!(a::MyB, gate, args...)
    (:addto!, gate(a, args...))
end



# Kind of dummy

sx(a::MyB, x::Int) = a.data + x
x(a::MyB) = (a.data)^2
sin(a::MyB) = sin(a.data)

end # module MyBs
