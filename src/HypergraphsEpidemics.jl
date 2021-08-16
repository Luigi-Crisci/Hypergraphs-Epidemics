module HypergraphsEpidemics

using CSV
using DataFrames
using Query
using Tables
using Dates
using DataStructures
using Distributions
using SimpleHypergraphs
using Statistics
using Combinatorics
using Pipe: @pipe
using Random

export Person
export Household
export Company
export Contact_simulation_options

export generate_dataset
export start_simulation

include("common/Constants.jl")
include("common/EventWriter.jl")
include("common/utils.jl")
include("common/structs.jl")
include("RoutineAutomaton.jl")
include("DatasetGeneration.jl")
include("Simulation.jl")

include("../deps/HGEpidemics/src/HGEpidemics.jl")

using .HGEpidemics

end