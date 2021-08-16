p_school  = 0.3
p_work 	  = 0.03
p_leisure = 0.003

function start_contact_generation(df::DataFrame, parameters::Contact_simulation_options)
	# Create the check-in writer
	event_writer = EventWriter("resources/generated_contact.csv")
	# Define simulation start time
	day = 1
	month = 1
	year = 2021
	simulation_day = DateTime(year,month,day)
	households = get_households(df,parameters)
	cont = 0
	simulation_num_days = parameters.days

	for day in 1:simulation_num_days
		############ CONTACT WITH HOUSEHOLD ###########
		workers = Set{Person}()
		students = Set{Person}()
		all_people = Set{Person}()
		for household in households
			workers = workers ∪ household.workers
			students = students ∪ household.students
			family = union(household.workers,household.students,household.unemployeds)
			all_people = all_people ∪ family
			for person in family
				add_event(event_writer,Event(person.id,household.id,PLACE_HOME,DateTime(year,month,day,DAY_START)))
				cont += 1
			end
		end
		write_events(event_writer)

		println("|People| = $(length(all_people)) - |students| = $(length(students)) - |workers| = $(length(workers))")

		# ########## WORK CONTACT #############
		if !_is_holiday(simulation_day)
			cont = 0
			for workplace in 1:parameters.work_place_num
				workers_same_workplace = filter(w -> w.work_school_place == workplace,workers)
				println("Workplace $workplace: |Size| = $(length(workers_same_workplace))")
	
				combinations_iterator = combinations(collect(workers_same_workplace),2)
				for couple in combinations_iterator
					if rand() > p_work
						continue
					end
					worker_1 = couple[1]
					worker_2 = couple[2]
					contact_hour = rand(WORK_START:WORK_END)
					add_event(event_writer,Event(worker_1.id,worker_1.work_school_place,PLACE_WORK, simulation_day + Dates.Hour(contact_hour)))
					add_event(event_writer,Event(worker_2.id,worker_2.work_school_place,PLACE_WORK, simulation_day + Dates.Hour(contact_hour)))
					cont += 2
				end
				write_events(event_writer)
			end
			println("Work contact: $(cont)")
		end

		# pre_school_students, primary_students, secondary_students, higher_students = divide_students_by_age(students)

		######### SCHOOL CONTACT #############	
		if !_is_holiday(simulation_day)
			cont = 0
			for school in 1:parameters.school_place_num
				students_same_school = filter(s -> s.work_school_place == school, students)
				println("School $school: |Size| = $(length(students_same_school))")
	
				combinations_iterator = combinations(collect(students_same_school), 2)
				for couple in combinations_iterator
						if rand() > p_school #Skip if the probability check fails
							continue
						end
						student_1 = couple[1]
						student_2 = couple[2]
						contact_hour = rand(SCHOOL_START:SCHOOL_END)
						add_event(event_writer,Event(student_1.id,student_1.work_school_place,PLACE_SCHOOL,simulation_day + Dates.Hour(contact_hour)))
						add_event(event_writer,Event(student_2.id,student_2.work_school_place,PLACE_SCHOOL,simulation_day + Dates.Hour(contact_hour)))
						cont += 2
				end
				write_events(event_writer)
			end	
			println("School contact: $(cont)")
		end

		######### LEISURE CONTACT #############
		println(" |Size| = $(length(all_people))")

		combinations_iterator = combinations(collect(all_people),2)
		cont = 0
		for couple in combinations_iterator
			if rand() > p_leisure
				continue
			end

			person_1 = couple[1]
			person_2 = couple[2]

			if !_is_holiday(simulation_day) && (person_1 ∈ workers || person_2 ∈ workers)
				contact_hour = rand(WORK_END:DAY_END)
			elseif !_is_holiday(simulation_day) && (person_1 ∈ students || person_2 ∈ students)
				contact_hour = rand(SCHOOL_END:DAY_END)
			else
				contact_hour = rand((DAY_START+1):DAY_END)
			end

			contact_place = rand(1:parameters.leisure_place_num)
			add_event(event_writer,Event(person_1.id,contact_place,PLACE_LEISURE,simulation_day + Dates.Hour(contact_hour)))
			add_event(event_writer,Event(person_2.id,contact_place,PLACE_LEISURE,simulation_day + Dates.Hour(contact_hour)))
			cont += 2
		end
		println("Leisure contact: $(cont)")
		
		simulation_day = simulation_day + Dates.Day(1)
	end

	close_writer(event_writer)
end

function get_random_subset(origin::Set, num::Int)
	tmp = origin
	subset = Set()
	for i in 1:num
		elem = rand(tmp,1)[1];
		push!(subset,elem)
		tmp = setdiff(tmp,[elem])
	end
	subset
end

function equalize_sets(set1::Set, set2::Set, bucket::Set)
	while length(set1) < length(set2)
		push!(set1,rand(setdiff(bucket,set1 ∪ set2)))
	end
end