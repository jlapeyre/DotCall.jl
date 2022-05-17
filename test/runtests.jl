using CBOO
using Test

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
