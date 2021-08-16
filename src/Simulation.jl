function start_simulation(dataset_path::String, parameters::Contact_simulation_options)
	# Create the check-in writer
	event_writer = EventWriter("resources/generated_contact.csv")
	# Define simulation start time
	simulation_time_start = DateTime(2021,1,1,DAY_START)
	simulation_time_end = simulation_time_start + Dates.Day(31)
	households = _read_household_dataset(dataset_path)

	leisure_places = rand(0:75,15) # A fraction of all the workplace are leisure place
	count = 0
	while simulation_time_start < simulation_time_end
		count = 0
		for household in households
			for worker in household.workers
				_simulate_worker(worker,household.id,parameters,simulation_time_start,event_writer,leisure_places)
				count+=1
			end
			for student in household.students
				_simulate_student(student,household.id,parameters,simulation_time_start,event_writer,leisure_places)
				count+=1
			end
			for other in household.unemployeds
				_simulate_home(other,household.id,parameters,simulation_time_start,event_writer,leisure_places) 
				count+=1
			end
			write_events(event_writer)

		end

		simulation_time_start += Dates.Hour(1)
		if Dates.hour(simulation_time_start) ==  0 
			simulation_time_start += Dates.Hour(DAY_START)
		end
	end

	close_writer(event_writer)
end

function _simulate_worker(worker::Person, household_id::Int,parameters::Contact_simulation_options,time,event_writer::EventWriter,leisure_places)
	# Handle morning
	if worker.movement_state == 1
		add_event(event_writer,Event(worker.id,household_id,PLACE_HOME,time - Dates.Hour(1))) # They wake up 1 hour before work
	end
	
	if _worker_next_step(time,worker)
		if worker.movement_state == 1 # Home
			event = Event(worker.id,household_id,PLACE_HOME,time)
		end
		if worker.movement_state == 2 # Transport
			event = Event(worker.id,rand(1:parameters.transport_place_num),PLACE_TRANSPORT,time)
		end
		if worker.movement_state == 3 # Work
			# Introduce an event each 4 hours
			local_time = time
			while Dates.hour(local_time) < WORK_END
				add_event(event_writer, Event(worker.id,worker.work_school_place,PLACE_WORK,local_time))
				local_time += Dates.Hour(4) # Time for indirect contact
			end
			event = Event(-1,-1,-1,DateTime(0000)) #FIXME: Null event, this can be easily avoided
		end
		if worker.movement_state == 4 # Transport
			event = Event(worker.id,rand(1:parameters.transport_place_num),PLACE_TRANSPORT,time)
		end
		if worker.movement_state == 5 # Home
			event = Event(worker.id,household_id,PLACE_HOME,time)
		end
		if worker.movement_state == 6 # leisure
			leisure_place = rand(leisure_places)
			event = Event(worker.id,leisure_place,PLACE_LEISURE,time)
			# event = Event(-1,-1,-1,DateTime(0000)) #FIXME: Null event, this can be easily avoided
		end
		add_event(event_writer,event)
	end
end

function _simulate_student(student::Person, household_id::Int,parameters::Contact_simulation_options,time,event_writer::EventWriter,leisure_places)
	# Handle morning 
	if student.movement_state == 1
		add_event(event_writer,Event(student.id,household_id,PLACE_HOME,time - Dates.Hour(1)))
	end
	
	if _student_next_step(time,student)
		if student.movement_state == 1 # Home
			event = Event(student.id,household_id,PLACE_HOME,time)
		end
		if student.movement_state == 2 # Transport
			event = Event(student.id,rand(1:parameters.transport_place_num),PLACE_TRANSPORT,time)
		end
		if student.movement_state == 3 # School
			event = Event(student.id,student.work_school_place,PLACE_WORK,time)
		end
		if student.movement_state == 4 # Transport
			event = Event(student.id,rand(1:parameters.transport_place_num),PLACE_TRANSPORT,time)
		end
		if student.movement_state == 5 # Home
			event = Event(student.id,household_id,PLACE_HOME,time)
		end
		if student.movement_state == 6 # leisure
			leisure_place = rand(leisure_places)
			event = Event(student.id,leisure_place,PLACE_LEISURE,time)
			# event = Event(-1,-1,-1,DateTime(0000)) #FIXME: Null event, this can be easily avoided
		end
		add_event(event_writer,event)
	end
end

function _simulate_home(home::Person, household_id::Int,parameters::Contact_simulation_options,time,event_writer::EventWriter,leisure_places)
	if home.movement_state == 1
		add_event(event_writer,Event(home.id,household_id,PLACE_HOME,time - Dates.Hour(1)))
	end

	if _home_next_step(time,home)
		if home.movement_state == 1 # Home
			event = Event(home.id,household_id,PLACE_HOME,time)
		end
		if home.movement_state == 2 # leisure
			leisure_place = rand(leisure_places)
			event = Event(home.id,leisure_place,PLACE_LEISURE,time)
			# event = Event(-1,-1,-1,DateTime(0000)) #FIXME: Null event, this can be easily avoided
		end
		add_event(event_writer,event)
	end
end

function get_households(df_nodes::DataFrame,parameters::Contact_simulation_options)::Array{Household,1}
	households = Array{Household,1}()
	gdf_households = groupby(df_nodes, :hh_id)
	
	lk = ReentrantLock()
	Threads.@threads for i in 1:length(gdf_households)
		household_record = gdf_households[i]
		id = household_record.part_id[1]
		household = Household(id,size(household_record,1))
		for person_record in eachrow(household_record)
			occupation = person_record.part_occupation
			if occupation == WORKING
				person = create_worker(parameters,person_record)
				push!(household.workers,person)
			elseif occupation == SCHOOL
				person = create_student(parameters,person_record)
				push!(household.students,person)
			else
				person = Person(person_record.part_id,person_record.part_age,person_record.part_occupation,-1,-1)
				push!(household.unemployeds,person)
			end
		end
		lock(lk) do 
			push!(households,household)
		end
	end
	return households
end

function get_households(dataset_path::String,parameters::Contact_simulation_options)::Array{Household,1}
	df_nodes = CSV.File(dataset_path) |> DataFrame
	return get_households(df_nodes,parameters)
end

function create_student(parameters::Contact_simulation_options,student_record)
	school_place = rand(1:parameters.school_place_num)
	transport = rand(1:parameters.transport_place_num)
	return Person(student_record.part_id, student_record.part_age, student_record.part_occupation, school_place, transport)
end

function create_worker(parameters::Contact_simulation_options,worker_record)
	work_place = rand(1:parameters.work_place_num)
	transport = rand(1:parameters.transport_place_num)
	return Person(worker_record.part_id, worker_record.part_age, worker_record.part_occupation, work_place, transport)
end

