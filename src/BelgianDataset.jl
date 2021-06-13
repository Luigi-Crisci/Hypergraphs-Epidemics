module BelgianDataset

using CSV
using DataFrames
using Query
using Tables
using Dates
using DataStructures
using Distributions
using SimpleHypergraphs
using Statistics

export Person
export Household
export Contact_simulation_options

export EventWriter
export Event
export add_event
export write_events
export close_writer

export get_households
export join_partecipant_common_and_extra_datasets
export analyze_contact_data
export next_10_multiple

export generate_model_data
export generatehg!
export evaluate_direct_contacts_distribution

include("Constants.jl")
include("event_writer.jl")
include("utils.jl")
include("person.jl")
include("routine_automaton.jl")
include("check_in_simulation.jl")
include("analyze_dataset.jl")
include("contact_generation.jl")

include("HGEpidemics/src/dataset_stats/utils.jl")
include("HGEpidemics/src/utils/loader.jl")
include("HGEpidemics/src/utils/builder.jl")

end