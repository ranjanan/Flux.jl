module Flux

using MacroTools, Lazy, Flow

# Zero Flux Given

include("model.jl")
include("utils.jl")

include("compiler/graph.jl")
include("compiler/diff.jl")
include("compiler/code.jl")
include("compiler/loops.jl")

include("layers/dense.jl")
include("layers/shape.jl")
include("layers/chain.jl")
include("layers/shims.jl")

include("cost.jl")
include("activation.jl")

include("backend/backend.jl")

end # module
