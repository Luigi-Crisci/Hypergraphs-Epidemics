"""
	Join partecipant common and extra dataset
"""
function join_partecipant_common_and_extra_datasets(common_dataset::String,extra_dataset::String)
	df_common = CSV.File(common_dataset,missingstring="NA") |> DataFrame
	df_extra = CSV.File(extra_dataset,missingstring="NA") |> DataFrame

	df_result = @from r1 in df_common begin
				@join r2 in df_extra on r1.part_id equals r2.part_id
				@select {r1.part_id,r1.hh_id,r1.part_age,r1.part_gender,r2.part_occupation}
				@collect DataFrame
	end

	replace!(df_result.part_occupation, missing => 6) #TODO: Semplification, should be assigned to a proper label

	CSV.write("resources/processed_partecipant_extra.csv",df_result)

	return df_result
end

function join_contact_common_and_extra_datasets(common_dataset::String,extra_dataset::String)
	df_common = CSV.File(common_dataset,missingstring="NA") |> DataFrame 
	df_extra = CSV.File(extra_dataset,missingstring="NA") |> DataFrame

	df_result = @from r1 in df_common begin
				@join r2 in df_extra on r1.cont_id equals r2.cont_id
				@select {r1.cont_id,r1.part_id,r1.cnt_age_exact,r1.cnt_age_est_min,r1.cnt_age_est_max,r1.cnt_gender,
				r1.cnt_home,r1.cnt_work,r1.cnt_school,r1.cnt_transport,r1.cnt_leisure,r1.cnt_otherplace,
				r1.frequency_multi,r1.phys_contact,r1.duration_multi,r2.cnt_otherplace_family,r2.cnt_otherplace_grandparents,r2.cnt_hh_member}
				@collect DataFrame
	end

	CSV.write("resources/processed_contact_extra.csv",df_result)

	return df_result
end


"""
	Join partecipant and contact datasets, and gets some metadata
"""
function analyze_contact_data(partecipand_dataset::String,partecipant_extra_dataset::String,contact_dataset::String,contact_extra_dataset::String)
	df_partecipant = join_partecipant_common_and_extra_datasets(partecipand_dataset,partecipant_extra_dataset)
	df_contact = join_contact_common_and_extra_datasets(contact_dataset,contact_extra_dataset)

	#TODO: collapse all this replaces into a single function
	replace!(df_contact.cnt_age_exact, missing => -1)
	replace!(df_contact.cnt_age_est_max, missing => -1)
	replace!(df_contact.cnt_age_est_min, missing => -1)
	replace!(df_contact.cnt_hh_member, missing => "N")
	replace!(df_partecipant.part_occupation, RETIRED => HOME) #Replace "retired" with "working"
	
	df_contact.cnt_home = convert.(Int,df_contact.cnt_home)
	df_contact.cnt_work = convert.(Int,df_contact.cnt_work)
	df_contact.cnt_school = convert.(Int,df_contact.cnt_school)
	df_contact.cnt_transport = convert.(Int,df_contact.cnt_transport)
	df_contact.cnt_leisure = convert.(Int,df_contact.cnt_leisure)
	df_contact.cnt_otherplace = convert.(Int,df_contact.cnt_otherplace)

	transform!(df_contact, [:cnt_age_exact,:cnt_age_est_min,:cnt_age_est_max] => (x,y,z) -> calculate_age.(x,y,z))
	rename!(df_contact,:cnt_age_exact_cnt_age_est_min_cnt_age_est_max_function => :age)	
	
	df_result = @from r1 in df_partecipant begin
				@join r2 in df_contact on r1.part_id equals r2.part_id
				@where r1.part_age != -1 && r2.age != -1 #Remove contacs with no age
				@select {r1.part_id,r1.hh_id,r2.cont_id,r1.part_age,r2.age,r1.part_gender,r2.cnt_gender,
						 r2.cnt_home,r2.cnt_work,r2.cnt_school,r2.cnt_transport,r2.cnt_leisure,
						 r2.cnt_otherplace,r2.frequency_multi,r2.phys_contact,r2.duration_multi,
						 r2.cnt_otherplace_family,r2.cnt_otherplace_grandparents,r2.cnt_hh_member}
				@collect DataFrame
	end
				
	CSV.write("resources/processed_partecipant_contact.csv",df_result)

	#### Generate occupation and household for each contact
	occupation_distribution = get_occupation_distribution(df_partecipant)
	transform!(df_result,[:age] => x -> get_occupation(x,occupation_distribution), [:part_id,:cont_id,:hh_id,:cnt_hh_member,:cnt_otherplace_family,:cnt_otherplace_grandparents] => (a,b,c,d,e,f) -> get_household.(a,b,c,d,e,f) )
	rename!(df_result, :part_id_cont_id_etc_function => :cnt_household_id)
	rename!(df_result, :age_function => :cnt_occupation)
	CSV.write("resources/processed_contact_with_occupation.csv",df_result)

	### Append the resulted contact dataset to the partecipant one
	df_contact_to_partecipant = df_result |> @select(:cont_id,:cnt_household_id,:cnt_occupation,:cnt_gender,:age) |>
										   	 @rename(:cont_id => :part_id, :cnt_household_id => :hh_id, :age => :part_age, :cnt_occupation => :part_occupation, :cnt_gender => :part_gender) |>
										   	 DataFrame
	replace!(df_contact_to_partecipant.part_gender, missing => "NA")

	append!(df_partecipant,df_contact_to_partecipant)
	CSV.write("resources/processed_partecipant_and_contact.csv",df_partecipant)
	

end

function get_household(part_id,cnt_id,household_id,hh_member,family_cnt,grandparents_cnt)
	if hh_member == "Y" || family_cnt || grandparents_cnt
		return household_id
	else
		return string(part_id,cnt_id) # The concatenation of the 2 ids is used as key
	end
end

function get_occupation(age,occupation_distribution)
	result = []

	for i in 1:length(age)
		push!(result,get_occupation_single_person(age[i],occupation_distribution))
	end
	return result
end

"""
	Get occupation based on the occupation vector
	Special value return for age < CHILD_AGE && age > ELDER_AGE
"""
function get_occupation_single_person(age::Int, occupation_distribution)
	# Handle children
	if age < CHILD_AGE
		if age < INFANT
			return OTHER
		else
			return SCHOOL
		end
	end

	# Handle elder
	if age >= ELDER_AGE
		return HOME
	end

	index = floor(Int,age / 10) - 1
	calculated_prob_sum = rand()
	prob_sum = occupation_distribution[index][1][:num]
	
	# print("Age: ",age," - Index: ",index," - occupation_distribution size: ", length(occupation_distribution), "\n")
	for i in 1:length(occupation_distribution[index])
		#Handle cases where the float sum is not 1
		if i == length(occupation_distribution[index])
			return occupation_distribution[index][i][:Key]
		end
		if calculated_prob_sum < prob_sum
			return occupation_distribution[index][i][:Key]
		end
		calculated_prob_sum += occupation_distribution[index][i][:num]
		prob_sum += occupation_distribution[index][i][:num]
	end
end

"""
	Returns a DataFrame containing the number of contacts for each class and for each age interval  
"""
function get_contact_age_distribution(df::DataFrame)
	min_age, max_age = extrema(df.age)
	df_result = DataFrame(min_age = Int[],max_age = Int[],size = Int[],home_perc = Float32[],work_perc= Float32[], 
				school_perc= Float32[],transport_perc= Float32[],leisure_perc= Float32[],otherplace_perc= Float32[])
	
	for i in range(0,next_10_multiple(max_age) - 10,step=10)
		size,cnt_vector = get_contact_distribution_per_age(df,i,i+10)
		
		perc = 100/size
		cnt_vector = perc .* cnt_vector
		result = vcat(i,i+10,size,cnt_vector)

		push!(df_result,result)
	end

	return df_result
end

"""
	Gets, for the given age interval, the number of contacts for each class
"""
function get_contact_distribution_per_age(df::DataFrame, min_age::Int, max_age::Int)
	df_result = @from i in df begin
				@where i.age > min_age && i.age < max_age
				@select i
				@collect DataFrame
				end
	
	cnt_home = sum(df_result.cnt_home)
	cnt_work = sum(df_result.cnt_work)
	cnt_school = sum(df_result.cnt_school)
	cnt_transport = sum(df_result.cnt_transport)
	cnt_leisure = sum(df_result.cnt_leisure)
	cnt_otherplace = sum(df_result.cnt_otherplace)

	cnt_vector = [cnt_home,cnt_work,cnt_school,cnt_transport,cnt_leisure,cnt_otherplace]

	return sum(cnt_vector),cnt_vector
end

"""
	Return a multidimensional vector, where the position i contains the occupation distribution in the range i*10 - (i*10 + 10)
"""
function get_occupation_distribution(df::DataFrame)
	age_distribution = Array{Array{Any},1}()
	
	for i in range(CHILD_AGE,next_10_multiple(ELDER_AGE) - 10,step=10)
		push!(age_distribution, get_occupation_distribution_per_age(df,i,i+10))
	end

	return age_distribution
end

function get_occupation_distribution_per_age(df::DataFrame,min_age::Int,max_age::Int)
	df_result = df |> @filter(_.part_age >= min_age && _.part_age < max_age) |>
					  @groupby(_.part_occupation) |> 
					  @map({ Key = key(_), num = length(_)}) |> 
					  @orderby(_.Key) |>  
					  DataFrame

	df_result[!,:num] = df_result[!,:num] ./ sum(df_result[!,:num])

	return Tables.rowtable(df_result)
end