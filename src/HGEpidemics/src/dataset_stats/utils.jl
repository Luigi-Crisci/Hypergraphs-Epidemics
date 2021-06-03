"""
    A bunch of helper functions to study
    some stats about the data sets to analyze.
"""


"""
    find_intervals!(mintime::DateTime, maxtime::DateTime, Δₘ::Dates.Millisecond)

Evaluate the total amount of intervals to analyze together with their
starting and ending date from `mintime` to `maxtime`.

The number of intervals is given by the following formula:
(maxdate - mindate)/Δₘ

Return a dict where each entry is in the form
    interval_id -> (start_date, end_date)
"""
function find_intervals(mintime::DateTime, maxtime::DateTime, Δ::Dates.Millisecond)
    # interval_id -> (start_date, end_date)
    intervals = Dict{Int, Pair{DateTime, DateTime}}()

    # Evaluating the total number of time slots
    # within the observation period (maxtime - mintime)
    # using Δₘ as discretization param
    nintervals = ceil(Int,(maxtime - mintime)/Δ)

    for i=1:nintervals
        offset = mintime + Δ > maxtime ?  maxtime + Dates.Millisecond(1) :  mintime + Δ
        get!(
            intervals,
            i,
            Pair{DateTime, DateTime}(convert(Dates.DateTime, (mintime)), convert(Dates.DateTime, (offset)))
        )

        mintime = offset
    end

    intervals
end



"""
    evaluate_checkin_density(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame)

Evaluate the checkin density per time interval, counting the number of check-ins
within an interval.

Return a dict where each entry is in the form
    interval_id -> Number of check-ins
"""
function evaluate_checkin_density(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame)
    checkins_per_interval = Dict{Int, Int}()

    for interval in intervals
        currdf = filter(
            r -> ((r.UTCtime >= (interval.second.first)) && (r.UTCtime < (interval.second.second))),
            df
        )
        push!(
            checkins_per_interval,
            interval.first => nrow(currdf)
        )
    end

    checkins_per_interval
end



"""
    evaluate_checkin_distribution(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame)

Evaluate the distribution of the differences (in seconds) between
two consecutive check-ins within the same location.
"""
function evaluate_checkins_distribution(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame)
    diff_within_intervals = Dict{Int, Array{Any, 1}}()

    for interval in intervals
        currdf = filter(
            r -> ((r.UTCtime >= (interval.second.first)) && (r.UTCtime < (interval.second.second))),
            df
        )

        get!(diff_within_intervals, interval.first, Array{Int, 1}())

        for r₁ in eachrow(currdf)
            for r₂ in eachrow(currdf)
                if rownumber(r₁) != rownumber(r₂)
                    if r₁.userid != r₂.userid && r₁.venueid == r₂.venueid
                        push!(
                            get!(diff_within_intervals, interval.first, Array{Int, 1}()),
                            convert(Dates.Second, abs(r₁.UTCtime - r₂.UTCtime)).value
                        )
                    end
                end
            end
        end
    end

    diff_within_intervals
end



"""
    evaluate_direct_contacts_distribution!(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame, δ::Dates.Milliseconds)

 Evaluate the distribution of direct contacts within each time interval.
"""
function evaluate_direct_contacts_distribution(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame, δ::Dates.Millisecond)
    dc_distr = Dict{Int, Dict{Int,Int}}()

    for interval in intervals
        
        #Leave only the day of this interval
        currdf = filter(
            r -> ((r.timestamp >= (interval.second.first)) && (r.timestamp < (interval.second.second))),
            df
        )

        current_dict = get!(dc_distr, interval.first, Dict{Int,Int}())

        cross_df =  crossjoin(currdf,currdf,makeunique=true)
        print("Cross join done!\nFiltering....\n")
        filter!(r -> (r.Id != r.Id_1) && (r.venueid != r.venueid_1) && abs(r.timestamp - r.timestamp_1) <= δ, cross_df)
        print("Filtering done!\nGrouping...\n")
        grouped_cross_df = groupby(cross_df,:Id)
        
        for user in grouped_cross_df
            push!(current_dict, user.Id[1] => length(user.Id)) # Update contact num of this user
        end

    end
    return dc_distr
end


"""
    evaluate_location_distribution!(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame)

 Evaluate the distribution of indirect contacts within each time interval.
"""
function evaluate_location_distribution(intervals::Dict{Int, Pair{DateTime, DateTime}}, df::DataFrame)
    loc_distr = Dict{Int, Array{Any, 1}}()

    for interval in intervals
        currdf = filter(
            r -> ((r.UTCtime >= (interval.second.first)) && (r.UTCtime < (interval.second.second))),
            df
        )

        get!(loc_distr, interval.first, Array{Int, 1}())

        users = unique(currdf, :userid)

        for u in eachrow(users)
            uid = u.userid
            ucontacts = filter(r -> r.userid == uid, currdf)

            push!(
                get!(loc_distr, interval.first, Array{Int, 1}()),
                nrow(unique(ucontacts, :venueid))
            )
        end
    end

    loc_distr
end










# users = unique(currdf, :userid)#[!, :userid]

# current_user_count = Threads.Atomic{Int}(1)
# Threads.@threads for u in eachrow(users) # For all users
    
#     println("Current user: $current_user_count")
#     Threads.atomic_add!(current_user_count,1)

#     cont = 0
#     uid = u.userid
#     ucontacts = filter(r -> r.userid == uid, currdf)
#     current_dict = get!(dc_distr, interval.first, Dict{Int,Int}())

#     for uc in eachrow(ucontacts) #For each user check in
#         for r in eachrow(currdf) #For each check in of this day 
#             if uc.userid != r.userid # If I'm not checking with myself
#                 if uc.venueid == r.venueid # If we have been in the same place
#                     if abs(uc.timestamp - r.timestamp) <= δ # If the interval is small
#                         # Direct contact
#                         cont = cont + 1
#                     end
#                 end
#             end
#         end
#     end
#     push!(current_dict, uid => cont) # Update contact num of this user
# end
# end

# dc_distr