function _prob_contact(contact_mean::Int, num_persons::Int, num_places::Int)
    return contact_mean / (num_persons / num_places) * 100
end

function _get_random_size(range::String, max::Int)
    intervals = split(range, '-')
    if contains(intervals[1], "+")
        intervals[1] = intervals[1][1:(length(intervals[1])-1)]
        intervals = parse.(Int, intervals)
        push!(intervals, max)
    else
        intervals = parse.(Int, intervals)
    end
    return rand(intervals[1]:intervals[2])
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

function _get_school_level(age, levels)
    for level in levels
        intervals = split(level[1], '-')
        if contains(intervals[1], "+")
            intervals[1] = intervals[1][1:(length(intervals[1])-1)]
            intervals = parse.(Int, intervals)
            if age >= intervals[1]
                return level[2]
            end
        else
            intervals = parse.(Int, intervals)
            if age >= intervals[1] && age <= intervals[2]
                return level[2]
            end
        end
    end
end

function _get_school_work_place(
    age::Int,
    occupation::Int,
    companies::Set{Company},
    schools::Dict{String,Array{Int,1}},
    levels,
)
    if occupation == UNEMPLOYED
        return -1
    elseif occupation == SCHOOL
        school_level = _get_school_level(age, levels)
        return rand(schools[school_level])
    else
        company = rand(companies)
        company.current_size += 1
        return company.id
    end
end

function _add_person_to_right_set(person::Person, students, employeds, unemployeds)
    occupation = person.occupation
    if occupation == SCHOOL
        push!(students, person)
    elseif occupation == WORKING
        push!(employeds, person)
    elseif occupation == UNEMPLOYED
        push!(unemployeds, person)
    end
end

"""
Write an household vector as a CSV dataset
"""
function _write_households(households, output_path::String)
    output_path = output_path * "dataset.csv"
    table = DataFrame(
        household_id = Int[],
        person_id = Int[],
        age = Int[],
        occupation = Int[],
        work_school_place = Int[],
    )
    mutex = ReentrantLock()
    Threads.@threads for household in households
        people = household.workers ∪ household.students ∪ household.unemployeds
        for person in people
            lock(mutex) do
                push!(
                    table,
                    [
                        household.id,
                        person.id,
                        person.age,
                        person.occupation,
                        person.work_school_place,
                    ],
                )
            end
        end
    end
    table |> CSV.write(output_path)
end

function _write_dict(input,output_path::String,filename::String)
    output_path = output_path * filename *".json"
    open(output_path,"w+") do io
        JSON3.write(io,input)
    end
end

function _read_household_dataset(dataset_path::String)
    households = Array{Household,1}()
    df = CSV.File(dataset_path) |> DataFrame
    gdf = groupby(df, :household_id)
    mutex = ReentrantLock()
    Threads.@threads for group_idx = 1:length(gdf)
        group = gdf[group_idx]
        household = Household(group.household_id[1], 0)
        for record in eachrow(group)
            if record.occupation == WORKING
                push!(
                    household.workers,
                    Person(
                        record.person_id,
                        record.age,
                        record.occupation,
                        record.work_school_place,
                        -1,
                    ),
                )
            elseif record.occupation == SCHOOL
                push!(
                    household.students,
                    Person(
                        record.person_id,
                        record.age,
                        record.occupation,
                        record.work_school_place,
                        -1,
                    ),
                )
            else
                push!(
                    household.unemployeds,
                    Person(
                        record.person_id,
                        record.age,
                        record.occupation,
                        record.work_school_place,
                        -1,
                    ),
                )
            end
            household.num_components += 1
        end
        lock(mutex) do
            push!(households, household)
        end
    end
    return households
end

function generate_dataset(config_file::String, output_path::String)
    Random.seed!(0)
    config = JSON.parsefile(config_file)

    households = []
    companies = Set{Company}()
    companies_full = Set{Company}()
    schools = Dict{String,Array{Int,1}}()
    num_people = config["people"]
    num_companies = config["workplaces"]
    num_schools = sum([pair[2] for pair in config["schools"]])
	probs = Dict{Int,Float16}() # Probability dict
    info = Dict{String,Int}() # Useful information dict


    students = Set{Person}()
    employeds = Set{Person}()
    unemployeds = Set{Person}()

    min_workplace_size = 66.7 # Percentage
    id = 1
    push!(info,WORKPLACES_START_ID => id) # Save where the ids starts
    for company_class in config["companies_size"]
        num_company_to_generate = ceil(Int, num_companies * company_class[2] / 100)
        while num_company_to_generate > 0
            num_company_to_generate -= 1
            size = _get_random_size(company_class[1], config["companies_max_size"])
            company = Company(id, size)
            push!(companies, company)
			push!(probs,id => config["company_probs"][company_class[1]])
            id += 1
        end
    end

    # Get the ids for the schools
    push!(info,SCHOOLS_START_ID => id) # Save where the ids starts
    for school_class in config["schools"]
        cur_school_ids = Array{Int,1}()
        cur_school_num = school_class[2]
        for i = 1:cur_school_num
            push!(cur_school_ids, id)
			push!(probs,id => config["school_probs"][school_class[1]])
            id += 1
        end
        push!(schools, school_class[1] => cur_school_ids)
    end
    next_id = id

    id = 1
    for population_class in config["population_dist"]
        num_people_to_generate = floor(Int, num_people * population_class[2] / 100)
        println("$(population_class) -> $(num_people_to_generate)")
        while num_people_to_generate > 0
            num_people_to_generate -= 1
            age = _get_random_size(population_class[1], config["person_max_age"])
            occupation = _get_occupation_by_age(age)
            school_work_place = _get_school_work_place(
                age,
                occupation,
                companies,
                schools,
                config["students_school"],
            )

            if occupation == WORKING
                company = first(filter(c -> c.id == school_work_place, companies))
                if company.max_size == company.current_size
                    delete!(companies, company)
                    push!(companies_full, company)
                end
            end

            person = Person(id, age, occupation, school_work_place, -1)
            _add_person_to_right_set(person, students, employeds, unemployeds)

            id += 1
        end
    end

    id = next_id #Because household ids are also used in the simulation, they must be unique
    push!(info,HOUSEHOLDS_START_ID => id) # Save where the ids starts
    p_one_adult = 0.3
    p_more_adults = 0.2
    μ = 2.5 # Medium househol size
    σ = 0.5 # Minum size 1
    households_size_distribution = Normal(μ, σ)
    age_difference = 15 # max age difference between two person in a household
    remaining_people = num_people

    Adult = employeds ∪ unemployeds
    Children = students

    while remaining_people > 0
        person_added = 0
        household_size = max(1, round(Int, rand(households_size_distribution)))
        household = Household(id, household_size)

        adult_1 = rand(Adult)
        _add_person_to_right_set(
            adult_1,
            household.students,
            household.workers,
            household.unemployeds,
        )
        delete!(Adult, adult_1)
        person_added += 1

        if household_size > 1
            if !isempty(Adult) && rand() > p_one_adult
                Adult_close_age = filter(
                    person ->
                        max(CHILD_AGE, person.age - age_difference) <=
                        person.age <=
                        person.age + age_difference,
                    Adult,
                )
                adult_2 = rand(Adult_close_age)
                _add_person_to_right_set(
                    adult_2,
                    household.students,
                    household.workers,
                    household.unemployeds,
                )
                delete!(Adult, adult_2)
                person_added += 1
            end

            if !isempty(Children)
                while person_added < household_size && !isempty(Children)
                    child = rand(Children)
                    _add_person_to_right_set(
                        child,
                        household.students,
                        household.workers,
                        household.unemployeds,
                    )
                    delete!(Children, child)
                    person_added += 1
                end
            elseif !isempty(Adult)
                while person_added < household_size &&
                          rand() > p_more_adults &&
                          !isempty(Adult)
                    adult_2 = rand(Adult)
                    _add_person_to_right_set(
                        adult_2,
                        household.students,
                        household.workers,
                        household.unemployeds,
                    )
                    delete!(Adult, adult_2)
                    person_added += 1
                end
            end


        end
        remaining_people -= person_added
        household.num_components = person_added # When some sets are empty, these values can be different
        push!(probs,id => 1) # Contact prob inside household is always 1
        push!(households, household)
        id += 1
    end

    #Transports are placed at the end
    push!(info,TRANSPORTS_START_ID => id) # Save where the ids starts
    for i in id:id+config["transports"]
        push!(probs,i => config["transports_prob"])
    end

    _write_households(households, output_path)
    _write_dict(probs,output_path,"probs")
    _write_dict(info,output_path,"info")
	

    return households
end
