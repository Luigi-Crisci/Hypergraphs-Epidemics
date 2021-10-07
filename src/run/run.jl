using HypergraphsEpidemics
using DataStructures
using SimpleHypergraphs
using Dates


function foo(iter = 1, kwargs...)
    println(typeof(kwargs))
    foo2(kwargs...)
end

function foo2(iter = 1, kwargs...)
    println(haskey(d,:a))
end

d = OrderedDict{Symbol,Any}(:a => 1, :b => 3)
println(typeof(d))
foo(1, d...)

households = generate_dataset("resources/gen_settings/Salerno/gen_param.json","resources/datasets/Salerno/")

# mean = sum(h -> h.num_components, households) / length(households)



start_simulation(
    "resources/datasets/Salerno/dataset.csv",
    "resources/datasets/Salerno/contacts.csv",
    "resources/gen_settings/Salerno/gen_param.json",
    "resources/datasets/Salerno/info.json"
)
    
df_generated_model, intervals, user2vertex, loc2he = HypergraphsEpidemics.generate_model_data(
                                            "resources/datasets/Salerno/contacts.csv",
                                            [:Time, :Id, :position], #Column list
                                            :Id, #userid column
                                            :position, #venue column
                                            :Time, #Check in column
                                            "yyyy-mm-ddTHH:MM:SS", #Date format
                                            Δ = Dates.Millisecond(86400000), # 24 hours
                                            δ = Dates.Millisecond(900000), # minutes
                                            datarow = 2 # Data starts at second row
                                            # limit = 10000 # limit
    )
    
length(keys(loc2he))