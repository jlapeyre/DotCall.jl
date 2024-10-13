@testset "DotCall.jl" begin
    y = MyA(3)
    @test y.sx(4) == 7
    @test MyAs.sx(y, 4) == 7
    @test y.mycos() == cos(y.data)
    @test y.y == 3
    @test_throws ErrorException y.cf # find a better error to throw
#    @test_throws KeyError y.cf  # if we look up in dynamic dict
    result = add_dotcalls(MyA, (:x, :sx, :cf))
    @test result == [(:cf, :cf)]
    @test y.cf() == 1

    using MyBs: MyB, addto!, MyBs
    z = MyB(3)
    result = z.sx(4)
    @test result == (:addto!, 7)
    @test MyBs.addto!(z, MyBs.sx, 4) == (:addto!, 7)

    using MyCs: MyC, MyCs
    w = MyC(10)
    @test w.f(3) == 13
    @test w.f(3) == MyCs.f(w, 3)
    @test w.data == 10
end

@testset "properties" begin
    @test propertynames(MyA) == (:var, :body)
    @test propertynames(MyA, true) == (:var, :body, :__dotcall_list__, :__dotcall_list__expr,
                                       :__dotcall_callmethod__, :__dotcall_getproperty__, :__module__)
    @test fieldnames(MyA) == (:data,)
    z = MyA(4.1)
    @test propertynames(z) == (:data, :sx, :x, :sin, :y, :mycos, :cf)
    @test propertynames(z, true) == (:data, :sx, :x, :sin, :y, :mycos, :cf,
                                  :__dotcall_list__, :__dotcall_list__expr, :__dotcall_callmethod__, :__dotcall_getproperty__, :__module__)
    @test_throws MethodError fieldnames(z)
end

@testset "dotcallified_properties" begin
    props = dotcallified_properties(MyA)
    @test props.sx == MyAs.sx
    @test props.x == MyAs.x
    @test props.cf == MyAs.cf
    @test props.y == 3
    @test props.sin == Base.sin
    @test isa(props.mycos, Function)
    @test length(props) == 6

    @test_throws DotCall.NotDotCallifiedException dotcallified_properties(Int)
    @test_throws DotCall.AlreadyDotCallifiedException @macroexpand @dotcallify MyA (sx, x)
    @test whichmodule(MyA) == MyAs
    @test_throws DotCall.NotDotCallifiedException whichmodule(Float64)
    @test_throws DotCall.DotCallSyntaxException @macroexpand @dotcallify Int 3
end
