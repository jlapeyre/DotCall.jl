using CBOOCall # just to get the path
using BenchmarkTools

basedir = joinpath(dirname(dirname(pathof(CBOOCall))), "test")
tstmods = joinpath.(basedir, ["MyAs", "MyBs", "MyCs"])
push!(LOAD_PATH, tstmods...)

using MyAs

const y2 = MyA(33.0)

n = 10^5
t_cboo = @elapsed for _ in 1:n
    [y2.sx(i) for i in 1:100];
end

t_plain = @elapsed for _ in 1:n
    [MyAs.sx(y2, i) for i in 1:100];
end

@show t_cboo, t_plain, (t_cboo - t_plain) / t_plain

println("cboo")
@btime [y2.sx(i) for i in 1:100];

println("usual")
@btime [MyAs.sx(y2, i) for i in 1:100];

sleep(0.5)

println("usual")
@btime [MyAs.sx(y2, i) for i in 1:100];

println("cboo")
@btime [y2.sx(i) for i in 1:100];


nothing;
