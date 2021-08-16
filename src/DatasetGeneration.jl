"""
- 0-4: 4.3%
- 5-14. 10.2%
- 15-19: 5.7%
- 20-39: 25%
- 40-64: 36%
- 65-74: 10%
- 75-84: 6.3%
- 85+: 2.5%

"""



"""
Get the person class, given the age

**Arguments**
- *age*: The person age

"""
function _get_person_class(age::Int)
	if 0 < age <= 4
		return 0
	elseif 4 < age <= 14
		return 1
	elseif 14 < age <= 19
		return 2
	elseif 19 < age <= 39
		return 3
	elseif 39 < age <= 64
		return 4
	elseif 64 < age <= 74
		return 5
	elseif 74 < age <= 85
		return 6
	else
		return 7
	end
end


"""
Get the company related class, given the size

**Arguments**
- *size*: The company employer size

"""
function _get_company_class(size::Int)
	if 0 < size <= 9
		return 0 
	elseif 9 < size < 49
		return 1
	elseif 49 < size <= 249
		return 2
	else
		return 3
	end
end


"""
Get a person age, given the person age class  

**Arguments**
- *class*: The person integer class (from 1 to 8)

"""
function _get_random_person_age(class::Int)
	if class == 1
		return rand(1:4)
	elseif class == 2
		return rand(5:14)
	elseif class == 3
		return rand(15:19)
	elseif class == 4
		return rand(20:39)
	elseif class == 5
		return rand(40:64)
	elseif class == 6
		return rand(65:74)
	elseif class == 7
		return rand(75:85)
	else
		return rand(86:100)
	end
end

"""
Get a workplace size, given the class of the workplace  

**Arguments**
- *class*: The workplace integer class (from 1 to 4)

"""
function _get_random_workplace_size(class::Int)
	if class == 1
		return rand(1:9)
	elseif class == 2
		return rand(10:49)
	elseif class == 3
		return rand(50:249)
	else
		return rand(250:1000)
	end
end

function _get_occupation_by_age(age::Int)
	p_quit_school = 0.17
	p_unoccupied = 0.17
	p_unoccupied_15_29 = 0.32

	if age <= 17
		return SCHOOL
	elseif 18 <= age <= 24
		if rand() > p_quit_school
			return SCHOOL
		else
			if rand() > p_unoccupied_15_29
				return WORKING
			else
				return UNEMPLOYED
			end
		end
	elseif 25 <= age <= 29
		if rand() > p_unoccupied_15_29
			return WORKING
		else
			return UNEMPLOYED
		end
	elseif age < 65
		if rand() > p_unoccupied
			return WORKING
		else
			return UNEMPLOYED
		end
	else
		return UNEMPLOYED
	end
end

function _get_school_work_place(occupation::Int,companies::Set{Company},num_schools::Int)
	if occupation == UNEMPLOYED
		return -1
	elseif occupation == SCHOOL
		return rand(1:num_schools)
	else
		company = rand(companies)
		company.current_size+=1
		return company.id
	end
end

function _add_person_to_right_set(person::Person,students,employeds,unemployeds)
	occupation = person.occupation
	if occupation == SCHOOL
		push!(students,person)
	elseif occupation == WORKING
		push!(employeds,person)
	elseif occupation == UNEMPLOYED
		push!(unemployeds,person)
	end
end

"""
Write an household vector as a CSV dataset
"""
function _write_households(households,output_path::String)
	table = DataFrame(household_id = Int[], person_id = Int[], age = Int[], occupation = Int[], work_school_place = Int[])
	mutex = ReentrantLock()
	Threads.@threads for household in households
		people = household.workers ∪ household.students ∪ household.unemployeds
		for person in people
			lock(mutex) do
				push!(table, [household.id,person.id,person.age,person.occupation,person.work_school_place])
			end
		end
	end
	table |> CSV.write(output_path)
end

function _read_household_dataset(dataset_path::String)
	households = Array{Household,1}()
	df = CSV.File(dataset_path) |> DataFrame
	gdf = groupby(df,:household_id)
	mutex = ReentrantLock()
	Threads.@threads for group_idx in 1:length(gdf)
		group = gdf[group_idx]
		household = Household(group.household_id[1],0)
		for record in eachrow(group)
			if record.occupation == WORKING
				push!(household.workers, Person(record.person_id,record.age,record.occupation,record.work_school_place,-1))
			elseif record.occupation == SCHOOL
				push!(household.students, Person(record.person_id,record.age,record.occupation,record.work_school_place,-1))
			else
				push!(household.unemployeds, Person(record.person_id,record.age,record.occupation,record.work_school_place,-1))
			end
			household.num_components += 1
		end 
		lock(mutex) do 
			push!(households,household)
		end
	end
	return households
end

function generate_dataset(output_path::String, num_people::Int, num_company::Int, num_schools::Int)
	Random.seed!(0)
	#TODO Fixed data from Salerno population
	population_distribution = [4.3,10.2,5.7,25,36,10,6.3,2.5]
	company_distribution = [95.93,3.64,0.37,0.1]
	households = []
	companies = Set{Company}()
	companies_full = Set{Company}()

	students = Set{Person}()
	employeds = Set{Person}()
	unemployeds = Set{Person}()

	min_workplace_size = 66.7 # Percentage
	id = 0
	for company_class in 1:length(company_distribution)
		num_company_to_generate = ceil(Int,num_company * company_distribution[company_class] / 100)
		while num_company_to_generate > 0
			num_company_to_generate-=1
			size = _get_random_workplace_size(company_class)
			company = Company(id,size)
			push!(companies,company)
			id += 1
		end
	end
	next_id = id

	id = 0
	for population_class in 1:length(population_distribution)
		num_people_to_generate = floor(Int,num_people * population_distribution[population_class] / 100)
		println("$(population_class) -> $(num_people_to_generate)")
		while num_people_to_generate > 0
			num_people_to_generate-=1
			age = _get_random_person_age(population_class)
			occupation = _get_occupation_by_age(age)
			school_work_place = _get_school_work_place(occupation,companies,num_schools)

			if occupation == WORKING 
				company = first(filter(c -> c.id == school_work_place,companies))
				if company.max_size == company.current_size
					delete!(companies,company)
					push!(companies_full,company)
				end
			end

			person = Person(id,age,occupation,school_work_place,-1)
			_add_person_to_right_set(person,students,employeds,unemployeds)
	
			id += 1
		end
	end

	id = next_id #Because household ids are also used in the simulation, they must be unique
	p_one_adult = 0.3
	p_more_adults = 0.2
	μ = 2.5 # Medium househol size
	σ = 0.5 # Minum size 1
	households_size_distribution = Normal(μ,σ)
	age_difference = 15
	remaining_people = num_people

	Adult = employeds ∪ unemployeds
	Children = students

	while remaining_people > 0
		person_added = 0
		household_size = max(1,round(Int,rand(households_size_distribution)))
		household = Household(id,household_size)
		
		adult_1 = rand(Adult)
		_add_person_to_right_set(adult_1,household.students,household.workers,household.unemployeds)
		delete!(Adult,adult_1)
		person_added+=1

		if household_size > 1
			if !isempty(Adult) && rand() > p_one_adult
				Adult_close_age = filter(person -> max(CHILD_AGE,person.age-age_difference) <= person.age <= person.age + age_difference,Adult)
				adult_2 = rand(Adult_close_age)
				_add_person_to_right_set(adult_2,household.students,household.workers,household.unemployeds)
				delete!(Adult,adult_2)
				person_added += 1
			end

			if !isempty(Children)
				while person_added < household_size && !isempty(Children)
					child = rand(Children)
					_add_person_to_right_set(child,household.students,household.workers,household.unemployeds)
					delete!(Children,child)
					person_added += 1
				end
			elseif !isempty(Adult) 
				while person_added < household_size && rand() > p_more_adults && !isempty(Adult)
					adult_2 = rand(Adult)
					_add_person_to_right_set(adult_2,household.students,household.workers,household.unemployeds)
					delete!(Adult,adult_2)
					person_added += 1
				end
			end

			
		end
		remaining_people -= person_added
		household.num_components = person_added # When some sets are empty, these values can be different
		push!(households,household)
		id += 1
	end

	_write_households(households,output_path)
	return households
end