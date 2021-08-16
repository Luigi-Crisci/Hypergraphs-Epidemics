using BelgianDataset
using CSV, DataFrames, Query
using Dates
using SimpleHypergraphs

df_generated_model, intervals, user2vertex, loc2he = BelgianDataset.generate_model_data(
                                        "resources/generated_contact.csv",
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



BelgianDataset.HGEpidemics.simulate(
    BelgianDataset.HGEpidemics.SIS(),
    df_generated_model,
    intervals,
    user2vertex,
    loc2he,
    Dates.Millisecond(600000)
)



# intervals = sort(intervals)

