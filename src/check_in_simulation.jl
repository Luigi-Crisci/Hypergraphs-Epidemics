mutable struct Contact_simulation_options
	work_place_num::Int
	school_place_num::Int
	transport_place_num::Int
	leisure_place_num::Int
end


function start_simulation(dataset_path::String, parameters::Contact_simulation_options)
	# Create the check-in writer
	event_writer = EventWriter("resources/generated_contact.csv")
	# Define simulation start time
	simulation_time = DateTime(0) + Dates.Hour(DAY_START)
	simulation_time_end = DateTime(0000,1,2) #TODO: 1 days, just to try
	households = get_households(dataset_path,parameters)

	while simulation_time < simulation_time_end
		for household in households 
			for worker in household.workers
				_simulate_worker(worker,household.id,parameters,simulation_time,event_writer)
			end
			for student in household.students
				_simulate_student(student,household.id,parameters,simulation_time,event_writer)
			end
			for other in household.homes
				_simulate_home(other,household.id,parameters,simulation_time,event_writer) 
			end
			write_events(event_writer)

		end

		simulation_time += Dates.Hour(1)
		if Dates.hour(simulation_time) > DAY_END
			simulation_time += Dates.Hour(DAY_START)
		end
	end

	close_writer(event_writer)
end

function _simulate_worker(worker::Person, household_id::Int,parameters::Contact_simulation_options,time,event_writer::EventWriter)
	if _worker_next_step(time,worker)
		if worker.movement_state == 1 # Home
			event = Event(worker.id,household_id,PLACE_HOME,time)
		end
		if worker.movement_state == 2 # Transport
			event = Event(worker.id,worker.transport,PLACE_TRANSPORT,time)
		end
		if worker.movement_state == 3 # Work
			event = Event(worker.id,worker.work_school_place,PLACE_WORK,time)
		end
		if worker.movement_state == 4 # Transport
			event = Event(worker.id,worker.transport,PLACE_TRANSPORT,time)
		end
		if worker.movement_state == 5 # Home
			event = Event(worker.id,household_id,PLACE_HOME,time)
		end
		if worker.movement_state == 6 # leisure
			leisure_place = rand(1:parameters.leisure_place_num)
			event = Event(worker.id,leisure_place,PLACE_LEISURE,time)
		end
		add_event(event_writer,event)
	end
end

function _simulate_student(student::Person, household_id::Int,parameters::Contact_simulation_options,time,event_writer::EventWriter)
	if _student_next_step(time,student)
		if student.movement_state == 1 # Home
			event = Event(student.id,household_id,PLACE_HOME,time)
		end
		if student.movement_state == 2 # Transport
			event = Event(student.id,student.transport,PLACE_TRANSPORT,time)
		end
		if student.movement_state == 3 # Work
			event = Event(student.id,student.work_school_place,PLACE_WORK,time)
		end
		if student.movement_state == 4 # Transport
			event = Event(student.id,student.transport,PLACE_TRANSPORT,time)
		end
		if student.movement_state == 5 # Home
			event = Event(student.id,household_id,PLACE_HOME,time)
		end
		if student.movement_state == 6 # leisure
			leisure_place = rand(1:parameters.leisure_place_num)
			event = Event(student.id,leisure_place,PLACE_LEISURE,time)
		end
		add_event(event_writer,event)
	end
end

function _simulate_home(home::Person, household_id::Int,parameters::Contact_simulation_options,time,event_writer::EventWriter)
	if _home_next_step(time,home)
		if home.movement_state == 1 # Home
			event = Event(home.id,household_id,PLACE_HOME,time)
		end 
		#TODO: Add transport state
		if home.movement_state == 2 # leisure
			leisure_place = rand(1:parameters.leisure_place_num)
			event = Event(home.id,leisure_place,PLACE_LEISURE,time)
		end
		add_event(event_writer,event)
	end
end

function get_households(dataset_path::String,parameters::Contact_simulation_options)::Array{Household,1}
	df_nodes = CSV.File(dataset_path) |> DataFrame
	households = Array{Household,1}()

	gdf_households = groupby(df_nodes, :hh_id)
	
	for household_record in gdf_households
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
				push!(household.homes,person)
			end
		end
		push!(households,household)
	end
	return households
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

