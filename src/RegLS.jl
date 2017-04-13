__precompile__()

module RegLS

using ProximalOperators

include("utils.jl")
include("operators.jl")
include("variables.jl")
include("affine.jl")
include("functions.jl")
include("costfunction.jl")
include("solvers.jl")
include("problems.jl")

end
