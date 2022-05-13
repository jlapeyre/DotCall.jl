## The real reason for CBOO.jl

<!-- ```julia -->
<!-- julia> split("a;b;c", ";") -->
<!-- 3-element Vector{SubString{String}}: -->
<!--  "a" -->
<!--  "b" -->
<!--  "c" -->
<!-- ``` -->

`split("a;b;c", ";")` is not really the right way to do it. If we do this

```julia
julia> @eval Base import CBOO;
julia> @eval Base CBOO.@cboo_call String (split,)
```

then we can do this

```julia
julia> ";".split("a;b;c")
3-element Vector{SubString{String}}:
 "a"
 "b"
 "c"
```

Ahhhh... That's much better!

... ... uh ..., it's, ... it's the other way around, right? Let's consult the *Zen of CBOO*.

```python
>>> from string import spl[TAB, TAB]  # Bonk! Bonk !. It's not there
>>> ';'.split('a;b;c')
[';']
>>> 'a;b;c'.split(';')
['a', 'b', 'c']
```

Ok, so let's fix it.

```julia
julia> @eval Base CBOO.@cboo_call String (split=(x,y) -> split(y, x),)

julia> print(";".split("a;b;c"))
SubString{String}["a", "b", "c"]
```

There. Perfect. ... Almost. Some day I need to find an elegant way to to disable this
```julia
julia> split("a;b;c", ";")
3-element Vector{SubString{String}}:
 "a"
 "b"
 "c"
```

Of course, you have to pay for this intuitive syntax with a performance hit, right? How much is it?

Pick a fast operation, and put it in the middle of a list, and swap parameter order for no reason.

```julia
julia> @eval Base CBOO.@cboo_call Int64 (+, /, length, xor=(x,y)->xor(y,x), floor, rand)
```

The usual way
```julia
julia> @btime sum(xor(x,y) for (x, y) in zip(1:100, 101:200))
  2.134 ns (0 allocations: 0 bytes)
16856
```

The way of CBOO
```julia
julia> @btime sum(x.xor(y) for (x, y) in zip(1:100, 101:200))
  2.134 ns (0 allocations: 0 bytes)
16856
```

Why does this work ? Someone made searching for a `Symbol` in
a `Tuple` of `Symbol`s very fast in order to make `NamedTuple`s fast.

```julia
julia> @btime in(3, (1,2,3))
  1.442 ns (0 allocations: 0 bytes)
true

julia> @btime in(:a, (:b, :c, :a))
  0.020 ns (0 allocations: 0 bytes)
true
```

Add a barrier function in the right place, and you can get the compiler to rewrite the CBOO
syntax for you.
