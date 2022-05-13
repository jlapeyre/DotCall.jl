push!(LOAD_PATH, "./test/MyAs/", "./test/MyBs/")

using MyAs

using BenchmarkTools

const y2 = MyA(33.0)

n = 10^5
t_cboo = @elapsed for _ in 1:n
    [y2.sx(i) for i in 1:100];
end

t_plain = @elapsed for _ in 1:n
    [MyAs.sx(y2, i) for i in 1:100];
end

@show t_cboo, t_plain, (t_cboo - t_plain) / t_plain

@btime [y2.sx(i) for i in 1:100];
@btime [MyAs.sx(y2, i) for i in 1:100];

nothing;
