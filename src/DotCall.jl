module DotCall

function __add_dynamic end

export @dotcallify, add_dotcalls, is_dotcallified,
    dotcallified_properties, whichmodule

struct DotCallSyntaxException <: Exception
    msg::String
end

struct NotDotCallifiedException <: Exception
    type
end

function Base.showerror(io::IO, e::NotDotCallifiedException)
    print(io, "Type $(e.type) is not DotCallified.")
end

struct AlreadyDotCallifiedException <: Exception
    type
end

function Base.showerror(io::IO, e::AlreadyDotCallifiedException)
    print(io, "Type $(e.type) is already DotCallified. This can only be done once.")
end

# TODO: reorganize so we don't have to do this.
function _unesc(expr::Expr)
    expr.head === :escape && length(expr.args) == 1 &&
        return only(expr.args)
    throw(ArgumentError("Non-user error: Expression is not escaped"))
end

issym(ex) = isa(ex, Symbol)
istup(ex) = ishead(ex, :tuple)
isexpr(ex) = isa(ex, Expr)
ishead(ex, _head) = (isexpr(ex) && ex.head === _head)
isassign(ex) = ishead(ex, :(=))

function _dotcallify(Type_to_dotcallify; functup=:(()), callmethod=nothing, _getproperty=:getfield)
    nType_to_dotcallify = esc(Type_to_dotcallify)
    named_tup_pairs = []
    _unesc_named_tup_pairs = []
    for ex in functup.args
        if isa(ex, Symbol)
            push!(named_tup_pairs, ((esc(ex)), (esc(ex))))
            push!(_unesc_named_tup_pairs, (ex, ex))
        elseif ishead(ex, :(=))
            a = ex.args
            push!(named_tup_pairs, ((esc(a[1])), (esc(a[2]))))
            push!(_unesc_named_tup_pairs, (a[1], a[2]))
        else
            throw(ArgumentError("Expecting a function name or sym=func"))
        end
    end
    unesc_named_tup_pairs = (_unesc_named_tup_pairs...,)
    # Declare functions in case no methods for them are yet defined
    func_decl = Expr(:block, (:(function $func end) for (sym, func) in named_tup_pairs if isa(_unesc(func), Symbol))...)

    # Build a NamedTuple like (f=f, g=g, ....)
    tuple_arg = ((:($sym = $func) for (sym, func) in named_tup_pairs)...,)
    named_tuple = Expr(:const, Expr(:(=), :FuncMap, Expr(:tuple, tuple_arg...)))
    push!(func_decl.args, named_tuple)

    # Create a single function to call rather than generating one after a symbol matches.
    # The compiler can elide the latter only sometimes
    if callmethod === nothing
        callcode = :(callmethod(q::$nType_to_dotcallify, meth::Function, args...) = meth(q, args...);)
        _callmethod = :callmethod
    else # The user can also supply a function external to the macro to call instead.
        _callmethod = esc(callmethod) # use the user-supplied method
        callcode = :(nothing)
    end
    # The last thing to try before throwing an error is a slow looking in a Dict. This
    # does not slow any of the earlier lookups. Probably worse is the compiler can do
    # less optimization since the required function is not known at compile time.
    if _getproperty === :getfield
        # getfieldcode = :($(esc(_getproperty))(a, f)) # call getfield, or a  user-supplied function
        getfieldcode = :(begin
                             if hasfield($nType_to_dotcallify, f)
                                 return getfield(a, f)
                             elseif haskey(DYNAMIC_PROPERTIES, f)
                                 return addfunc(DYNAMIC_PROPERTIES[f])
                             else
                                 ts = string($nType_to_dotcallify)
                                 error("$ts has no property or key \"$f\"")
                             end
                         end)
    else
        getfieldcode = :($(esc(_getproperty))(a, f)) # call getfield, or a  user-supplied function
    end
    _getprop =
        quote
            $callcode;
            const DYNAMIC_PROPERTIES = Dict{Symbol,Any}();
            const private_properties = (__dotcall_list__ = FuncMap, __dotcall_list__expr = $(QuoteNode(unesc_named_tup_pairs)),
                                __dotcall_callmethod__ = $(QuoteNode(callmethod)), __dotcall_getproperty__ = $(QuoteNode(_getproperty)),
                                __module__ = @__MODULE__);
            function Base.getproperty(a::$nType_to_dotcallify, f::Symbol)
                addfunc(func::Function) = (args...) -> ($_callmethod)(a, func, args...);
                addfunc(notfunc) = notfunc;
                f in keys(private_properties) && return getfield(private_properties, f)
                f in keys(FuncMap) && return addfunc(getproperty(FuncMap, f))
                $getfieldcode;
                # I don't know why I disabled the following line. It was part of a commit
                # with message "Stop mysterious bug in QuantumCircuits.jl"
#                $(esc(_getproperty))(a, f) # call getfield, or a  user-supplied function
            end;
            function Base.getproperty(t::Type{$nType_to_dotcallify}, f::Symbol)
                f in keys(private_properties) && return getfield(private_properties, f)
                return getfield(t, f)
            end;
            function Base.propertynames(a::$nType_to_dotcallify, private::Bool=false)
                pnames = (fieldnames($nType_to_dotcallify)..., keys(FuncMap)...)
                if private
                    return (pnames..., keys(private_properties)...) # we need this for is_dotcallified, etc.
                else
                    return pnames
                end
            end;
            function Base.propertynames(::Type{$nType_to_dotcallify}, private::Bool=false)
                if private
                    return (fieldnames(typeof($nType_to_dotcallify))..., keys(private_properties)...)
                else
                    return fieldnames(typeof($nType_to_dotcallify))
                end
            end;
            #            function (@__MODULE__).__add_dynamic(::Type{$nType_to_dotcallify}, f::Symbol, val)
            import DotCall: __add_dynamic
            function DotCall.__add_dynamic(::Type{$nType_to_dotcallify}, f::Symbol, val)
                # TODO: probably want to prohibit clobbering
                DYNAMIC_PROPERTIES[f] = val
            end;
        end
    push!(func_decl.args, _getprop)
    return func_decl
end

"""
    @dotcallify(Type_to_dotcallify, (f1, f2, fa = Mod.f2...), callmethod=nothing, getproperty=getfield)

Allow functions of the form `f1(s::Type_to_dotcallify, args...)` to also be called with `s.f1(args...)` with no performance penalty.

`callmethod` and `getproperty` are keyword arguments.

If an element of the `Tuple` is an assignment `sym = func`, then `sym` is the property
that will call `func`. `sym` must be a simple identifier (a symbol). `func` is not
required to be a symbol. For example `myf = Base._unexportedf`.

If `callmethod` is supplied, then `s.f1(args...)` is translated to `callmethod(s, f1,
args...)` instead of `f1(s, args...)`.

`@dotcallify` works by writing methods (or clobbering methods) for the functions
`Base.getproperty` and `Base.propertnames`.

`getproperty` must be a function. If supplied, then it is called, rather than `getfield`, when looking up a
property that is not on the list of functions. This can be useful if you want further
specialzed behavior of `getproperty`.

`@dotcallify` must by called after the definition of `Type_to_dotcallify`, but may
be called before the functions are defined.

If an entry is not function, then it is returned, rather than called.  For example
`@dotcallify MyStruct (y=3,)`. Callable objects meant to be called must be wrapped in a
function.

# Examples:

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

@dotcallify(Type_to_dotcallify, (f1, f2, ...) callmethod=nothing, getproperty=getfield)
```
"""
macro dotcallify(Type_to_dotcallify, args...)
    _Type_to_dotcallify = Core.eval(__module__, Type_to_dotcallify)
    is_dotcallified(_Type_to_dotcallify) && throw(AlreadyDotCallifiedException(_Type_to_dotcallify))
    # Generate and return code
    _prep_dotcallify(Type_to_dotcallify, args...)
end

"""
    is_dotcallified(::Type{T})

Return `true` if the `@dotcallify` macro has been called on `T`.
"""
is_dotcallified(::Type{T}) where T = :__dotcall_list__ in propertynames(T, true)

# I don't think we want this method.
# TODO: The same as above, really. Reorganize this
# is_dotcallified(a) = :__dotcall_list__ in propertynames(a, true)

macro _add_dotcalls(Type_to_dotcallify, args...)
    _Type_to_dotcallify = Core.eval(__module__, Type_to_dotcallify)
    code = _prep_dotcallify(Type_to_dotcallify, args...)
    return code
end

function _prep_dotcallify(Type_to_dotcallify, args...)
    argd = Dict{Symbol,Any}()
    argd[:functup] = :(())
    argd[:callmethod] = nothing
    argd[:getproperty] = :getfield
    validkeys = collect(keys(argd))
    for arg in args
        if istup(arg)
            argd[:functup] = arg
        elseif isassign(arg)
            length(arg.args) == 2 || error("@dotcallify: Bad assignment")
            (sym, rhs) = (arg.args...,)
            issym(sym) || error("@dotcallify: LHS is not a symbol")
            haskey(argd, sym) || error("@dotcallify: Invalid keyword $sym")
            argd[sym] = rhs
        else
            error("@dotcallify: Invalid argument $arg")
        end
    end
    return _dotcallify(Type_to_dotcallify; functup=argd[:functup], callmethod=argd[:callmethod], _getproperty=argd[:getproperty])
end


"""
    add_dotcalls(::Type{DottedT}, dotcalllist)

Add the properties in `dotcalllist` to the list of properties that can be dot-called for
a type `DottedT` that has already been DotCall-ified.

Only properties that are not already DotCall-ified for `DottedT` are added. Previous
added properties will not be updated.

Since `add_dotcalls` is a function, in contrast to `@dotcallify`,
`dotcalllist` can be a literal container
(for example `Tuple` or `Vector`) or a variable name bound to a container.

Returns a `Vector` of two-tuples (`Tuple`) of the properties that were added,
that is, not already on the list.

# Examples
```julia-repl
julia> dotcallified_properties(MyA)
(sx = MyAs.sx, x = MyAs.x, sin = sin, y = 3, mycos = MyAs.var"#1#3"())

julia> add_dotcalls(MyA, (:x, :sx, :cf))
1-element Vector{Tuple{Symbol, Symbol}}:
 (:cf, :cf)

julia> add_dotcalls(MyA, (:x, :sx, :cf))
()
```
"""
function add_dotcalls(::Type{DottedT}, dotcalllist) where DottedT
    is_dotcallified(DottedT) || throw(NotDotCallifiedException(DottedT))
    toadd = filter(x -> !in(first(x), keys(DottedT.__dotcall_list__)),
                   [isa(y, Symbol) ? (y, y) : (y.args...,) for y in dotcalllist])
    isempty(toadd) && return ()
    expr = (DottedT.__dotcall_list__expr..., toadd...)
    expreq = ((:($(x[1])=$(x[2])) for x in expr)...,)
    callmethod = DottedT.__dotcall_callmethod__
    _getproperty = DottedT.__dotcall_getproperty__
    _dotcalllist = Expr(:tuple, expreq...)

    Core.eval(DottedT.__module__, :(using DotCall: @_add_dotcalls))
    Core.eval(DottedT.__module__,
              :(@_add_dotcalls $DottedT callmethod=$callmethod getproperty=$_getproperty ($(expreq...),)))
    return toadd
end

"""
    dotcallified_properties(::Type{T}) where T

Return a `NamedTuple` of DotCall-ified properties for type `T`.
The keys are properties, and the values are the functions or data
associated with the properties.
"""
function dotcallified_properties(::Type{T}) where T
    is_dotcallified(T) || throw(NotDotCallifiedException(T))
    return T.__dotcall_list__
end

# TODO: Note, this error message may be wrong. MyA and MyA{Int} are different
function dotcallified_properties(a)
    is_dotcallified(a) || throw(NotDotCallifiedException(typeof(a)))
    return a.__dotcall_list__
end

"""
    whichmodule(::Type{T}) where T

Return the module in which `T` was DotCall-ified.

NOTE: this uses information stored by DotCall. Might be the same as
info retrievable through Julia.
"""
function whichmodule(::Type{T}) where T
    is_dotcallified(T) || throw(NotDotCallifiedException(T))
    return T.__module__
end

# Note, this error message may be wrong. MyA and MyA{Int} are different
function whichmodule(a)
    is_dotcallified(a) || throw(NotDotCallifiedException(typeof(a)))
    return a.__module__
end

end # module DotCall
