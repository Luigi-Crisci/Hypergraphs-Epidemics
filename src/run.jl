using BelgianDataset
using CSV, DataFrames, Query
using Dates
using SimpleHypergraphs



BelgianDataset.analyze_contact_data(
    "resources/2010_Willem_BELGIUM_participant_common.csv",
    "resources/2010_Willem_BELGIUM_participant_extra.csv",
    "resources/2010_Willem_BELGIUM_contact_common.csv",
    "resources/2010_Willem_BELGIUM_contact_extra.csv",
)

# # df_partecipant = BelgianDataset.join_partecipant_common_and_extra_datasets(
# #     "resources/2010_Willem_BELGIUM_participant_common.csv",
# #     "resources/2010_Willem_BELGIUM_participant_extra.csv",
# # )

# # occupation_distribution = BelgianDataset.get_occupation_distribution(df_partecipant, x -> x != 6 ? true : false)

# # 	filter = (age,occupation,distribution) -> occupation == 6 ?  BelgianDataset.get_occupation_single_person(age,distribution) : occupation

# # 	transform!(df_partecipant,[:part_age,:part_occupation] => ((x,y) -> filter.(x,y,occupation_distribution)) => :part_occupation)


# # df_extra = BelgianDataset.join_contact_common_and_extra_datasets("resources/2010_Willem_BELGIUM_contact_common.csv",
# # 																 "resources/2010_Willem_BELGIUM_contact_extra.csv")

# # df = CSV.File("resources/processed_contact_with_occupation.csv") |> DataFrame

# # gdf = groupby(df,:cnt_occupation)
# # length(occupation_distribution[1])



# # df_extra = BelgianDataset.join_contact_common_and_extra_datasets(
# #     "resources/2010_Willem_BELGIUM_contact_common.csv",
# #     "resources/2010_Willem_BELGIUM_contact_extra.csv",
# # )

# # df = CSV.File("resources/processed_contact_with_occupation.csv") |> DataFrame

# # gdf = groupby(df, :cnt_occupation)

# # combine(gdf, nrow)

# # ######################
# # Check-in definition

# using BelgianDataset, Dates, SimpleHypergraphs, CSV, DataFrames

# df = CSV.File("resources/processed_partecipant_and_contact_normalized.csv") |> DataFrame
# gdf = DataFrames.groupby(df, :hh_id)

# f = (x, y) -> if x == 6
#     return x + 1
# else
#     return 0
# end


# df2 = transform!(df, [:part_age, :part_occupation] => ByRow(f) => :part_occupation)

# #TODO: Check number of school nelle fiandre
# parameter = Contact_simulation_options(700, 200, 8000 , 900)

# households = BelgianDataset.start_simulation(
#     "resources/processed_partecipant_and_contact_normalized.csv",
#     parameter
# )


# # ########### Validation ################
# using JuliaDB, BelgianDataset, Dates, SimpleHypergraphs, CSV, DataFrames, Query, Statistics, DataFramesMeta


# df_generated_model, intervals, user2vertex, loc2he = BelgianDataset.generate_model_data(
#                                         "resources/generated_contact.csv",
#                                         [:Time, :Id, :position], #Column list
#                                         :Id, #userid column
#                                         :position, #venue column
#                                         :Time, #Check in column
#                                         "yyyy-mm-ddTHH:MM:SS", #Date format
#                                         Δ = Dates.Millisecond(86400000), # 24 hours
#                                         δ = Dates.Millisecond(600000), # minutes
#                                         # limit = 10000 # limit
# )
# intervals = sort(intervals)
# df_partecipant = CSV.File("resources/processed_partecipant_and_contact_normalized.csv") |> DataFrame

# df_contact = CSV.File("resources/generated_contact.csv") |> DataFrame

# #### Param config ####
# δ = Dates.Millisecond(600000)
# users = unique(df_generated_model.userid)

# lk = ReentrantLock()
# contact_per_interval = []
# for interval in intervals
#     contact_num_dict = Dict{Int,Int}()
#     current_user_count = Threads.Atomic{Int}(0)
#     t = table(filter(r -> r.timestamp > interval[2][1] && r.timestamp < interval[2][2],df_generated_model),pkey = :userid)

# Threads.@threads for user in users # For all users
#         seen = Set{Int}()
#         Threads.atomic_add!(current_user_count,1)
#         println("Current user: $current_user_count")
        
#         cont = 0
#         uid = user
#         ucontacts = filter(r -> r.userid == uid, t)
        
#         for uc in ucontacts #For each user check in
#             for r in t #For each check in of this day
#                 if uc.userid != r.userid # If I'm not checking with myself
#                     if uc.venueid == r.venueid # If we have been in the same place
#                         if abs(uc.timestamp - r.timestamp) <= δ  && r.userid ∉ seen # If the interval is small and if I haven't seen him yet
#                             # Direct contact
#                             if rand() > 0.6 #Only in 40% of the cases, they actually meet
#                                 cont = cont + 1
#                                 push!(seen,r.userid)
#                             end
#                         end
#                     end
#                 end
#             end
#         end

#         lock(lk) do
#             push!(contact_num_dict, user => cont) # Update contact num of this user
#         end
#     end

#     push!(contact_per_interval,contact_num_dict)
# end

# function normalize_age(age::Int)
#     if 18 <= age <= 29
#         return 1
#     elseif 30 <= age <= 39
#         return 2
#     elseif 40 <= age <= 49
#         return 3
#     elseif 50 <= age <= 59
#         return 4
#     elseif 60 <= age <= 69
#         return 5
#     else
#         return 6
#     end
# end

# function get_age_interval_from_normalized(age::Int)
#     if age == 1
#         return "18-29"
#     elseif age == 2
#         return "30-39"
#     elseif age == 3
#         return "40-49"
#     elseif age == 4
#         return "50-59"
#     elseif age == 5
#         return "60-69"
#     else
#         return "70+"
#     end
# end


# for i in 1:length(contact_per_interval)
#     current_dict = contact_per_interval[i]
#     sorted_contact_num_dict = sort(current_dict)

#     filtered_df_partecipant = filter(r ->  in(r.part_id,collect(keys(sorted_contact_num_dict))),df_partecipant)
#     sorted_df_partecipant = sort(filtered_df_partecipant)
    
#     contact_num = DataFrame(id = collect(keys(sorted_contact_num_dict)), num_contact = collect(values(sorted_contact_num_dict)), age = sorted_df_partecipant.part_age, occupation = sorted_df_partecipant.part_occupation)
#     CSV.write("contact_num_$(i)_$(parameter.work_place_num)_$(parameter.school_place_num)_$(parameter.transport_place_num)_$(parameter.leisure_place_num)_.csv",contact_num)
    
#     contact_num = @linq contact_num |> where(:age .> 17) 
# transform!(contact_num,:age => (age -> normalize_age.(age)) => :age_normalized)
# contact_mean_per_age = DataFrame(age = [], contact_mean = [])
# for g in DataFrames.groupby(contact_num,:age_normalized)
#     push!(contact_mean_per_age,[get_age_interval_from_normalized(g.age_normalized[1]), mean(g.num_contact)])
# end

# CSV.write("contact_mean_per_age_$(i)_$(parameter.work_place_num)_$(parameter.school_place_num)_$(parameter.transport_place_num)_$(parameter.leisure_place_num).csv",sort(contact_mean_per_age))

# end

# contact_num = CSV.File("contact_num_1_700_200_8000_900_.csv") |> DataFrame

# @time distr = BelgianDataset.evaluate_direct_contacts_distribution(intervals,df,Dates.Millisecond(600000))

parameter = Contact_simulation_options(20, 3, 8000 , 900)

df = CSV.File("resources/processed_partecipant_and_contact_normalized.csv") |> DataFrame

subset_df = get_dataframe_subset(df,5000,[70,10,20],1)

BelgianDataset.start_contact_generation(
    subset_df,
    parameter
)

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
