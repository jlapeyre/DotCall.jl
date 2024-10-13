using DotCall # just to get the path
using BenchmarkTools

basedir = joinpath(dirname(dirname(pathof(DotCall))), "test")
tstmods = joinpath.(basedir, ["MyAs", "MyBs", "MyCs"])
push!(LOAD_PATH, tstmods...)

using MyAs

const y2 = MyA(33.0)

const n = 10^6
const mreps = 100

t_dot = @elapsed for _ in 1:n
    [y2.sx(i) for i in 1:mreps];
end

t_plain = @elapsed for _ in 1:n
    [MyAs.sx(y2, i) for i in 1:mreps];
end

abs_diff = (t_dot - t_plain)
rel_diff = abs_diff / t_plain

@show t_dot, t_plain, abs_diff, rel_diff

println("\ndot y2.sx(i)")
@btime [y2.sx(i) for i in 1:mreps];

println("\nusual MyAs.sx(y2, i)")
@btime [MyAs.sx(y2, i) for i in 1:mreps];

sleep(0.5)

println("\nusual MyAs.sx(y2, i)")
@btime [MyAs.sx(y2, i) for i in 1:mreps];

println("\ndot y2.sx(i)")
@btime [y2.sx(i) for i in 1:mreps];

nothing;
