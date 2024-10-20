using DotCall
using Aqua: Aqua

const ThePackage = DotCall

@testset "aqua deps compat" begin
    Aqua.test_deps_compat(ThePackage)
end

@testset "aqua unbound_args" begin
    Aqua.test_unbound_args(ThePackage)
end

@testset "aqua undefined exports" begin
    Aqua.test_undefined_exports(ThePackage)
end

# TODO: Not sure exactly which versions are ok.
# For <= v1.6, there are ambiguities in Dictionaries
if VERSION >= v"1.7"
    @testset "aqua test ambiguities" begin
        Aqua.test_ambiguities([ThePackage, Core, Base])
    end
end

@testset "aqua piracies" begin
    Aqua.test_piracies(ThePackage)
end

@testset "aqua project extras" begin
    Aqua.test_project_extras(ThePackage)
end

@testset "aqua state deps" begin
    Aqua.test_stale_deps(ThePackage)
end
