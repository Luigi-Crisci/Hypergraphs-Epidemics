function analyze_partecipant_data(common_dataset::String,extra_dataset::String)
	df_common = CSV.File(common_dataset) |> DataFrame
	df_extra = CSV.File(extra_dataset) |> DataFrame

	df_result = @from r1 in df_common begin
				@join r2 in df_extra on r1.part_id equals r2.part_id
				@select {r1.part_id,r1.part_age,r1.part_gender,r2.part_occupation}
				@collect DataFrame
	end

	CSV.write("resources/processed_dataset.csv",df_result)

	# get_metadata(df_result)
end

function calculate_age(exact,min,max)
	return exact != -1 ? exact : (min == -1 || max == -1 ? -1 : floor(Int,(min+max)/2) )
end

function analyze_contact_data(partecipand_dataset::String,contact_dataset::String)
	df_partecipant = CSV.File(partecipand_dataset) |> DataFrame
	df_contact = CSV.File(contact_dataset,missingstring="NA") |> DataFrame

	replace!(df_contact.cnt_age_exact, missing => -1)
	replace!(df_contact.cnt_age_est_max, missing => -1)
	replace!(df_contact.cnt_age_est_min, missing => -1)
	
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
				@select {r1.part_id,r2.cont_id,r1.part_age,r2.age,r1.part_gender,r2.cnt_home,r2.cnt_work,r2.cnt_school,r2.cnt_transport,r2.cnt_leisure,r2.cnt_otherplace,r2.frequency_multi,r2.phys_contact,r2.duration_multi}
				@collect DataFrame
	end
				
	CSV.write("resources/processed_dataset_contact.csv",df_result)

	get_contact_metadata(df_result)
end

function get_contact_metadata(df::DataFrame)
	min_age, max_age = extrema(df.age)
	df_result = DataFrame(min_age = Int[],max_age = Int[],size = Int[],home_perc = Float32[],work_perc= Float32[], 
				school_perc= Float32[],transport_perc= Float32[],leisure_perc= Float32[],otherplace_perc= Float32[])
	
	for i in range(0,next_10_multiple(max_age) - 10,step=10)
		size,cnt_home,cnt_work,cnt_school,cnt_transport,cnt_leisure,cnt_otherplace = analyze_contact_per_age(df,i,i+10)
		perc = 100/size
		push!(df_result,(i,i+10,size,cnt_home*perc,cnt_work*perc,cnt_school*perc,cnt_transport*perc,
									cnt_leisure*perc,cnt_otherplace*perc))
	end

	CSV.write("resources/processed_dataset_contact_metadata.csv",df_result)
end

function analyze_contact_per_age(df::DataFrame, min_age::Int, max_age::Int)
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

	return size(df_result,1),cnt_home,cnt_work,cnt_school,cnt_transport,cnt_leisure,cnt_otherplace

end





