using BelgianDataset, Dates, SimpleHypergraphs
# using CSV, DataFrames, Query

BelgianDataset.analyze_contact_data(
    "resources/2010_Willem_BELGIUM_participant_common.csv",
    "resources/2010_Willem_BELGIUM_participant_extra.csv",
    "resources/2010_Willem_BELGIUM_contact_common.csv",
    "resources/2010_Willem_BELGIUM_contact_extra.csv",
)

# df_partecipant = BelgianDataset.join_partecipant_common_and_extra_datasets(
#     "resources/2010_Willem_BELGIUM_participant_common.csv",
#     "resources/2010_Willem_BELGIUM_participant_extra.csv",
# )

# occupation_distribution = BelgianDataset.get_occupation_distribution(df_partecipant, x -> x != 6 ? true : false)

# 	filter = (age,occupation,distribution) -> occupation == 6 ?  BelgianDataset.get_occupation_single_person(age,distribution) : occupation

# 	transform!(df_partecipant,[:part_age,:part_occupation] => ((x,y) -> filter.(x,y,occupation_distribution)) => :part_occupation)


# df_extra = BelgianDataset.join_contact_common_and_extra_datasets("resources/2010_Willem_BELGIUM_contact_common.csv",
# 																 "resources/2010_Willem_BELGIUM_contact_extra.csv")

# df = CSV.File("resources/processed_contact_with_occupation.csv") |> DataFrame

# gdf = groupby(df,:cnt_occupation)
# length(occupation_distribution[1])



# df_extra = BelgianDataset.join_contact_common_and_extra_datasets(
#     "resources/2010_Willem_BELGIUM_contact_common.csv",
#     "resources/2010_Willem_BELGIUM_contact_extra.csv",
# )

# df = CSV.File("resources/processed_contact_with_occupation.csv") |> DataFrame

# gdf = groupby(df, :cnt_occupation)

# combine(gdf, nrow)

# ######################
# Check-in definition

using CSV, DataFrames

df = CSV.File("resources/processed_partecipant_and_contact.csv") |> DataFrame
gdf = groupby(df, :hh_id)

f = (x, y) -> if x == 6
    return x + 1
else
    return 0
end


df2 = transform!(df, [:part_age, :part_occupation] => ByRow(f) => :part_occupation)


parameter = Contact_simulation_options(3, 3, 3, 3)

households = BelgianDataset.start_simulation(
    "resources/processed_partecipant_and_contact.csv",
    parameter
)


# ########### Validation ################
using JuliaDB, BelgianDataset, Dates, SimpleHypergraphs, CSV, DataFrames, Query


df_generated_model, intervals, user2vertex, loc2he = BelgianDataset.generate_model_data(
                                        "resources/generated_contact.csv",
                                        [:Time, :Id, :position], #Column list
                                        :Id, #userid column
                                        :position, #venue column
                                        :Time, #Check in column
                                        "yyyy-mm-ddTHH:MM:SS", #Date format
                                        Δ = Dates.Millisecond(86400000), # 24 hours
                                        δ = Dates.Millisecond(600000), # minutes
                                        # limit = 10000 # limit
)
df_partecipant = CSV.File("resources/processed_partecipant_and_contact.csv") |> DataFrame

#### Param config ####
δ = Dates.Millisecond(600000)
users = unique(df_generated_model.userid)
t = table(df_generated_model,pkey = :userid)
contact_num_dict = Dict{Int,Int}()

lk = ReentrantLock()
current_user_count = Threads.Atomic{Int}(0)
for user in users # For all users
    
    Threads.atomic_add!(current_user_count,1)
    println("Current user: $current_user_count")
    
    cont = 0
    uid = user
    ucontacts = filter(r -> r.userid == uid, t)
    
    for uc in ucontacts #For each user check in
        for r in t #For each check in of this day
            if uc.userid != r.userid # If I'm not checking with myself
                if uc.venueid == r.venueid # If we have been in the same place
                    if abs(uc.timestamp - r.timestamp) <= δ # If the interval is small
                        # Direct contact
                        cont = cont + 1
                    end
                end
            end
        end
    end

    lock(lk) do
        push!(contact_num_dict, user => cont) # Update contact num of this user
    end
end


sorted_contact_num_dict = sort(contact_num_dict)
sorted_df = sort(df_generated_model)

contact_num = DataFrame(id = collect(keys(sorted_contact_num_dict)), num_contact = collect(values(sorted_contact_num_dict)), age = sorted_df.part_age, occupation = sorted_df.part_occupation)

CSV.write("contact_num.csv",contact_num)

# @time distr = BelgianDataset.evaluate_direct_contacts_distribution(intervals,df,Dates.Millisecond(600000))


# h = BelgianDataset.generatehg!(
#         nothing, # Generate a new Hypergraph
#         df, # Check in dataset
#         intervals[1][1], # mindate
#         intervals[1][2], # maxdate
#         user2vertex,
#         loc2he,
#         zeros(Int, length(unique(df.userid))), # 1 for each user: indicate if a new position for the given user must be evaluated
#         0
# )

# h