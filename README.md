# CBOO

[![Build Status](https://github.com/jlapeyre/CBOO.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/CBOO.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/CBOO.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/CBOO.jl)

This package provides `@cboo_call` which allows you to write the function call `f(a::A, args...)` as `a.f(args...)` as well.
You can use it by adding a single line to your module. Using the alternative call syntax incurs no performance
penalty.

The main motivation is make is easy to call many functions with short names without bringing
them into scope. For example `s.x(1)`, `s.y(3)`,  `s.z(3)`, etc. We want to do this without
claiming `x`, `y`, `z`, and many others.

A requirement is no performance penalty. Benchmarking the code in the test suite shows
no performance penalty. But, there may be some lurking.

For example the script [smalltest.jl](./smalltest.jl)
```julia
push!(LOAD_PATH, "./test/MyAs/", "./test/MyBs/")
using MyAs
using BenchmarkTools
const y2 = MyA(5)
@btime [y2.sx(i) for i in 1:100];
@btime [MyAs.sx(y2, i) for i in 1:100];
```
Prints:
```
  40.218 ns (1 allocation: 896 bytes)
  40.025 ns (1 allocation: 896 bytes)
```

#### Usage

```julia
module Amod

using CBOO: @cboo_call

struct A
  x::Int
end

@cboo_call A (f, g)

f(a::A, x, y) = a.x + x + y
g(a::A) = a.x

end # module Amod
```

Then you can write either `Amod.f(a, 1, 2)` or `a.f(1, 2)`.

For more features and details, see the docstring.

#### Functions and macros
`@cboo_call`, `add_cboo_calls`, `is_cbooified`, `whichmodule`, `cbooified_properties`.

#### Docstring

    @cboo_call(Type_to_cbooifiy, (f1, f2, fa = Mod.f2...), callmethod=nothing, getproperty=getfield)

Allow functions of the form `f1(s::Type_to_cbooifiy, args...)` to also be called with `s.f1(args...)` with no performance penalty.

`callmethod` and `getproperty` are keyword arguments.

If an element of the `Tuple` is an assignment `sym = func`, then `sym` is the property
that will call `func`. `sym` must be a simple identifier (a symbol). `func` is not
required to be a symbol. For example `myf = Base._unexportedf`.

If `callmethod` is supplied, then `s.f1(args...)` is translated to `callmethod(s, f1,
args...)` instead of `f1(s, args...)`.


If `getproperty` is supplied then it is called, rather than `getfield`, when looking up a
property that is not on the list of functions. This can be useful if you want further
specialzed behavior of `getproperty`.

`@cboo_call` must by called after the definition of `Type_to_cbooifiy`, but may
be called before the functions are defined.

If an entry is not function, then it is returned, rather than called.  For example
`@cboo_call MyStruct (y=3,)`. Callable objects meant to be called must be wrapped in a
function.

For `a::A`, two additional properties are defined for both `a` and `A`: `__module__` which
returns the module in which `@cboo_call` was invoked, and `__cboo_list__` which returns
the list of properties and functions that were passed in the invocation of `@cboo_call`.

#### Examples:

* Use within a module

```julia
module Amod
import CBOO

struct A
    x::Int
end

CBOO.@cboo_call A (w, z)

w(a::A, y) = a.x + y
z(a::A, x, y) = a.x + y + x
end # module
```
```julia-repl
julia> a = Amod.A(3);

julia> Amod.w(a, 4) == a.w(4) == 7
true

julia> a.__module__
Main.Amod

julia> a.__cboo_list__
(w = Main.Amod.w, z = Main.Amod.z)
```

* The following two calls have the same effect.

```julia
@cboo_call(T, (f1, f2, ...))

@cboo_call(T, (f1, f2, ...) callmethod=nothing, getproperty=getfield)
```


<!--  LocalWords:  CBOO args Benchmarking smalltest jl julia MyAs const MyA sx
 -->
<!--  LocalWords:  BenchmarkTools btime ns Amod cboo struct docstring
 -->
