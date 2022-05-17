using Printf
using BenchmarkTools

# @testset "bench" begin
#     y2 = MyA(3.0)
#     y2.sx(3)
#     tusual = @belapsed(MyAs.sx($y2, 3))
#     tcboo = @belapsed($y2.sx(3))
#     @show tusual, tcboo
# end

# TODO: Just use BenchmarkTools here
@testset "bench2" begin
    y2 = MyA(3.0)

    f_cboo = (_=nothing) -> [y2.sx(i) for i in 1:100];
    f_usual = (_=nothing) -> [MyAs.sx(y2, i) for i in 1:100];
    _pr(t) = @sprintf("%.3g", t)

    local t_cboo
    local t_usual

    f_cboo()
    f_usual()
    _ = @elapsed foreach(f_cboo, 1:10)
    _ = @elapsed foreach(f_usual, 1:10)

    n = 10^6
    try
        GC.enable(false)
        GC.gc()
        t_usual = @elapsed foreach(f_usual, 1:n)
        GC.gc()
        t_cboo = @elapsed foreach(f_cboo, 1:n)
    finally
        GC.enable(true)
    end

    err = (t_cboo - t_usual) / t_cboo
    println("Roll your own")
    println("bench: t_cboo = $(_pr(t_cboo)), t_usual = $(_pr(t_usual))")
    println("bench: (t_cboo - t_usual) / t_cboo = $(_pr(err))")
    @test abs(err) < 0.2

    try # reverse order
        GC.enable(false)
        GC.gc()
        t_cboo = @elapsed foreach(f_cboo, 1:n)
        GC.gc()
        t_usual = @elapsed foreach(f_usual, 1:n)
    finally
        GC.enable(true)
    end

    err = (t_cboo - t_usual) / t_cboo
    println("bench: t_cboo = $(_pr(t_cboo)), t_usual = $(_pr(t_usual))")
    println("bench: (t_cboo - t_usual) / t_cboo = $(_pr(err))")
    @test abs(err) < 0.2

    t_cboo = @belapsed $f_cboo() # foreach(f_cboo, 1:n)
    t_usual = @belapsed $f_usual() #foreach(f_usual, 1:n)
    err = (t_cboo - t_usual) / t_cboo
    println("@belapsed")
    println("bench: t_cboo = $(_pr(t_cboo)), t_usual = $(_pr(t_usual))")
    println("bench: (t_cboo - t_usual) / t_cboo = $(_pr(err))")
    @test abs(err) < 0.2
end
