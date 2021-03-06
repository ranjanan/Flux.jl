struct Model
  model::Any
  session::Session
  params::Dict{Flux.Param,Tensor}
  stacks::Dict
  inputs::Vector{Tensor}
  output::Any
end

function makesession(model, inputs; session = Session(Graph()))
  params, stacks, output = tograph(model, inputs...)
  run(session, initialize_all_variables())
  Model(model, session, params, stacks, inputs, output)
end

function makesession(model, n::Integer; session = Session(Graph()))
  makesession(model, [placeholder(Float32) for _ = 1:n], session = session)
end

tf(model) = makesession(model, 1)

function storeparams!(sess, params)
  for (p, t) in params
    p.x = run(sess, t)
  end
end

storeparams!(m::Model) = storeparams!(m.session, m.params)

function runmodel(m::Model, args...)
  @assert length(args) == length(m.inputs)
  run(m.session, m.output, Dict(zip(m.inputs, args)))
end

using Flux: runrawbatched

function (m::Model)(x)
  @tferr m.stacks runrawbatched(convertel(Float32, x)) do x
    output = runmodel(m, x)
  end
end

for f in :[back!, update!].args
  @eval function Flux.$f(m::Model, args...)
    error($(string(f)) * " is not yet supported on TensorFlow models")
  end
end

import Juno: info

function Flux.train!(m::Model, train, test=[]; epoch = 1, η = 0.1,
                     loss = (y, y′) -> reduce_sum((y - y′).^2)/2,
                     opt = TensorFlow.train.GradientDescentOptimizer(η))
  i = 0
  Y = placeholder(Float32)
  Loss = loss(m.output, Y)
  minimize_op = TensorFlow.train.minimize(opt, Loss)
  for e in 1:epoch
    info("Epoch $e\n")
    @progress for (x, y) in train
      y, cur_loss, _ = run(m.session, vcat(m.output, Loss, minimize_op),
                           Dict(m.inputs[1] => batchone(convertel(Float32, x)),
                                Y => batchone(convertel(Float32, y))))
      if i % 5000 == 0
        @show y
        @show accuracy(m, test)
      end
      i += 1
    end
  end
end
