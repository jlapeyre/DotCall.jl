using DotCall
using Test

include("aqua_test.jl")

# It looks like JET tries to analyze itself in v1.7
# And it finds ambiguities. So, let's skip JET for v1.7
if VERSION >= v"1.8"
    include("jet_test.jl")
end

oldLOAD_PATH = copy(LOAD_PATH)
try
    for dir in ("./MyAs", "./MyBs", "./MyCs")
        if !(dir in LOAD_PATH)
            push!(LOAD_PATH, dir)
        end
    end

    using MyAs: MyA, MyAs
    include("basic_tests.jl")
    # include("bench_tests.jl")

finally
    empty!(LOAD_PATH)
    copy!(LOAD_PATH, oldLOAD_PATH)
end
