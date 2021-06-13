p_work = 0.03
p_school = 0.3 
p_leisure = 0.003

function start_contact_generation(dataset_path::String, parameters::Contact_simulation_options)
	# Create the check-in writer
	event_writer = EventWriter("resources/generated_contact.csv")
	# Define simulation start time
	day = 1
	month = 1
	year = 2021
	households = get_households(dataset_path,parameters)

	############ CONTACT WITH HOUSEHOLD ###########
	workers = Set{Person}()
	students = Set{Person}()
	all_people = Set{Person}()
	for household in households
		workers = workers ∪ household.workers
		students = students ∪ household.students
		family = union(household.workers,household.students,household.homes)
		all_people = all_people ∪ family
		for person in family
			add_event(event_writer,Event(person.id,household.id,PLACE_HOME,DateTime(year,month,day,DAY_START)))
		end
	end
	# write_events(event_writer)

	########## WORK CONTACT #############
	for workplace in 1:parameters.work_place_num
		workers_same_workplace = filter(w -> w.work_school_place == workplace,workers)
		Workers_1 = filter(x -> rand() < p_work,workers_same_workplace)
		Workers_2 = filter(x -> rand() < p_work,setdiff(workers_same_workplace,Workers_1))
	
		for worker_1 in Workers_1
			for worker_2 in Workers_2
				contact_hour = rand(WORK_START:WORK_END)
				add_event(event_writer,Event(worker_1.id,worker_1.work_school_place,PLACE_WORK,DateTime(year,month,day,contact_hour)))
				add_event(event_writer,Event(worker_2.id,worker_2.work_school_place,PLACE_WORK,DateTime(year,month,day,contact_hour)))
			end
		end
		write_events(event_writer)
	end

	########## SCHOOL CONTACT #############	
	for school in 1:parameters.school_place_num
		students_same_school = filter(s -> s.work_school_place == school, students)
		Students_1 = filter(x -> rand() < p_school,students_same_school)
		Students_2 = filter(x -> rand() < p_school,setdiff(students_same_school,Students_1))
	
		for students_1 in Students_1
			for students_2 in Students_2
				contact_hour = rand(SCHOOL_START:SCHOOL_END)
				add_event(event_writer,Event(students_1.id,students_1.work_school_place,PLACE_SCHOOL,DateTime(year,month,day,contact_hour)))
				add_event(event_writer,Event(students_2.id,students_2.work_school_place,PLACE_SCHOOL,DateTime(year,month,day,contact_hour)))
			end
		end
		write_events(event_writer)
	end

	######### LEISURE CONTACT #############
	People_1 = filter(x -> rand() < p_leisure,all_people)
	People_2 = filter(x -> rand() < p_leisure,setdiff(all_people,People_1))

	for person_1 in People_1
		for person_2 in People_2
			if person_1 ∈ workers || person_2 ∈ workers
				contact_hour = rand(WORK_END:DAY_END)
			elseif person_1 ∈ students || person_2 ∈ students
				contact_hour = rand(SCHOOL_END:DAY_END)
			else
				contact_hour = rand((DAY_START+1):DAY_END)
			end
			contact_place = rand(1:parameters.leisure_place_num)
			add_event(event_writer,Event(person_1.id,contact_place,PLACE_LEISURE,DateTime(year,month,day,contact_hour)))
			add_event(event_writer,Event(person_2.id,contact_place,PLACE_LEISURE,DateTime(year,month,day,contact_hour)))
		end
	end
	write_events(event_writer)

	close_writer(event_writer)
end