## The real reason for CBOOCall.jl

`split(",", "a,b,c")` is not really the right way to do it.
`split` only works with strings, so it should be a class method.
We should be able to do `",".split("a,b,c")`.
There's even a mnemonic. Think of "comma-separated values".
Well this is a "comma split string".

Now there is a way with `CBOOCall.jl`:

```julia
julia> @eval Base import CBOOCall;
julia> @eval Base CBOOCall.@cbooify String (split,)
```

Then we have
```
julia> ",".split("a,b,c")
1-element Vector{SubString{String}}:
 ","
```
.... uh, we can fix that

```
julia> @eval Base CBOOCall.@cbooify String (split=(x,y) -> split(y, x),)
julia> ",".split("a,b,c")
3-element Vector{SubString{String}}:
 "a"
 "b"
 "c"
```

Ahhhh... That's much better than `split("a,b,c", ",")`! ...
I mean `split(",", "a,b,c")`.

... wait ..., is, ... it's the other way around, right? Let's consult the *Zen of CBOO*.

```python
>>> spl[TAB, TAB] # Bonk! Bonk! It's not there.
>>> from string import spl[TAB, TAB] # Bonk! Bonk ! Not there either. Good.
>>> ','.split("a,b,c")
[',']
>>> "a,b,c".split(',')
['a', 'b', 'c']
```

So the first way was correct. In any case, this is clearly the superior syntax
for splitting strings.

Of course, you have to pay for this intuitive syntax with a performance hit, right? How much is it?

Let's pick a fast operation, and put it in the middle of a list, and swap parameter order for no reason.

```julia
julia> @eval Base CBOOCall.@cbooify Int64 (+, /, length, xor=(x,y)->xor(y,x), floor, rand)
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

Why does this work ? Someone made searching for a literal `Symbol` in
a `Tuple` of `Symbol`s very fast in order to make `NamedTuple`s fast.

```julia
julia> @btime in(3, (1,2,3))
  1.442 ns (0 allocations: 0 bytes)
true

julia> @btime in(:a, (:b, :c, :a))
  0.020 ns (0 allocations: 0 bytes)
true
```
