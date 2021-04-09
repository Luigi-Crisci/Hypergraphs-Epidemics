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

	# df_contact = Missings.replace(df_contact,-1)
	
	
	# df_contact = df_contact |> @mutate(cnt_age_exact = typeof(_.cnt_age_exact) == Missing ? 
	# (typeof(_.cnt_age_est_min) == Missing || typeof(_.cnt_age_est_max) == Missing ? -1 : floor(Int64,(parse(Int64,_.cnt_age_est_min) + parse(Int64,_.cnt_age_est_max))/2) )
	# : (_.cnt_age_exact)) |> DataFrame
	
	transform!(df_contact, [:cnt_age_exact,:cnt_age_est_min,:cnt_age_est_max] => (x,y,z) -> calculate_age.(x,y,z))
	rename!(df_contact,:cnt_age_exact_cnt_age_est_min_cnt_age_est_max_function => :age)
	
	print(first(select(df_contact,14:16),4))
	

	df_result = @from r1 in df_partecipant begin
				@join r2 in df_contact on r1.part_id equals r2.part_id
				@select {r1.part_id,r2.cont_id,r1.part_age,r2.age,r1.part_gender,r2.cnt_home,r2.cnt_work,r2.cnt_school,r2.cnt_transport,r2.cnt_leisure,r2.cnt_otherplace,r2.frequency_multi,r2.phys_contact,r2.duration_multi}
				@collect DataFrame
	end
				
	CSV.write("resources/processed_dataset_contact.csv",df_result)

	# get_metadata(df_result)
end





