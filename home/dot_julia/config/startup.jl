using Pkg
using Revise
using BenchmarkTools

if isfile("Project.toml") && isfile("Manifest.toml")
    Pkg.activate(".")
end