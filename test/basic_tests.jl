@testset "CBOO.jl" begin
    y = MyA(3)
    @test y.sx(4) == 7
    @test MyAs.sx(y, 4) == 7
    @test y.mycos() == cos(y.data)
    @test y.y == 3

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
    @test propertynames(MyA, true) == (:var, :body, :__cboo_list__, :__cboo_list__expr,
                                       :__cboo_callmethod__, :__cboo_getproperty__, :__module__)
    #(:var, :body, :__cboo_list__, :__module__)
    @test fieldnames(MyA) == (:data,)
    z = MyA(4.1)
    @test propertynames(z) == (:data, :sx, :x, :sin, :y, :mycos)
    @test propertynames(z, true) == (:data, :sx, :x, :sin, :y, :mycos) # removed these  :__cboo_list__, :__module__)
    @test_throws MethodError fieldnames(z)
end
