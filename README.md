# DotCall

[![Build Status](https://github.com/jlapeyre/DotCall.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/DotCall.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/DotCall.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/DotCall.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This package facilitates using the "dot notation" for calling methods that is common in class-based object oriented langauges.
It provides a macro `@dotcallify` which allows you to call an existing method.
```julia
f(a::A, args...)
```
like this
```julia
a.f(args...)
```

### Example

```julia
module Amod

using DotCall: @dotcallify

struct A
  x::Int
end

@dotcallify A (f, g)

f(a::A, x, y) = a.x + x + y
g(a::A) = a.x

end # module Amod
```

Then you can write either `Amod.f(a, 1, 2)` or `a.f(1, 2)`.

### Performance

Benchmarking has not revealed any runtime performance penalty in calling a method using dot notation.

For example the script [examples/smalltest.jl](./examples/smalltest.jl)
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

### Package that uses DotCall

`DotCall.jl` was previously named `CBOOCall.jl`. But only the name changed, not the API. (other than minor updates
and fixes)

The package [QuantumCircuits.jl](https://github.com/rafal-pracht/QuantumCircuits.jl) uses `CBOOCall.jl`.

The main motivation is to make it easy to call many functions with short names without bringing
them into scope. For example `s.x(1)`, `s.y(3)`,  `s.z(3)`, etc. We want to do this without
claiming `x`, `y`, `z`, among others. This is all the package does.

For example, in building  quantum computing circuits programmatically, people really want
to write `circ.x(1)` to add an `X` gate on wire `1`. You could do
```julia
using QCircuit: add!  # ok to import this probably

add!(circ, QCircuit.x, 1) # But, I really don't want to import x, y, z, etc.
```

Here is [an example](https://github.com/rafal-pracht/QuantumCircuits.jl/blob/b1463aa6aac3c088c3ca14b90067a525788ddf8b/src/QCircuits/Circuit.jl#L93) from an application
```julia
@dotcallify QCircuit (x, sx, y, z, h, cx, s, sdg, t, tdg, u, u3, rx, ry, rz, rzx, u4, barrier, measure)
```

### Usage

#### Functions and macros

See doc strings for the following macros and methods.

`@dotcallify`, `add_dotcalls`, `is_dotcallified`, `whichmodule`, `dotcallified_properties`.

#### `@dotcallify` doc string

    @dotcallify(Type_to_dotcallify, (f1, f2, fa = Mod.f2...), callmethod=nothing, getproperty=getfield)

Allow functions of the form `f1(s::Type_to_dotcallify, args...)` to also be called with `s.f1(args...)` with no performance penalty.

`callmethod` and `getproperty` are keyword arguments.

If an element of the `Tuple` is an assignment `sym = func`, then `sym` is the property
that will call `func`. `sym` must be a simple identifier (a symbol). `func` is not
required to be a symbol. For example `myf = Base._unexportedf`.

If `callmethod` is supplied, then `s.f1(args...)` is translated to `callmethod(s, f1,
args...)` instead of `f1(s, args...)`.

`@dotcallify` works by writing methods (or clobbering methods) for the functions
`Base.getproperty` and `Base.propertynames`.

`getproperty` must be a function. If supplied, then it is called, rather than `getfield`, when looking up a
property that is not on the list of functions. This can be useful if you want further
specialzed behavior of `getproperty`.

`@dotcallify` must by called after the definition of `Type_to_dotcallify`, but may
be called before the functions are defined.

If an entry is not function, then it is returned, rather than called.  For example
`@dotcallify MyStruct (y=3,)`. Callable objects meant to be called must be wrapped in a
function.

#### Examples

* Use within a module

```julia
module Amod
import DotCall

struct A
    x::Int
end

DotCall.@dotcallify A (w, z)

w(a::A, y) = a.x + y
z(a::A, x, y) = a.x + y + x
end # module
```
```julia-repl
julia> a = Amod.A(3);

julia> Amod.w(a, 4) == a.w(4) == 7
true

julia> DotCall.whichmodule(a)
Main.Amod

julia> DotCall.dotcallified_properties(a)
(w = Main.Amod.w, z = Main.Amod.z)
```

* The following two calls have the same effect.

```julia
@dotcallify(Type_to_dotcallify, (f1, f2, ...))

@dotcallify(Type_to_dotcallify, (f1, f2, ...), callmethod=nothing, getproperty=getfield)
```

<!--  LocalWords:  DotCall args Benchmarking smalltest jl julia MyAs const MyA sx
 -->
<!--  LocalWords:  BenchmarkTools btime ns Amod dotcall struct docstring
 -->
