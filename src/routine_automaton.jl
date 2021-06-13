function _worker_next_step(time::DateTime, person::Person)
    state = person.movement_state

    # Handle day end 
    if Dates.hour(time) == DAY_END
        person.movement_state = 1
        return true
    end

    if state == 1 # Morning state
        person.movement_state = 2
    elseif state == 2 # Transport before work state
        person.movement_state = 3
    elseif state == 3 && is_working_end_time(time) # Working state
        person.movement_state = 4
    elseif state == 4 # Transport after work state
        person.movement_state = 5
    elseif state == 5 # Home after work
        p = rand()
        if p < _worker_go_leisure(time)
            person.movement_state = 6
        end
    elseif state == 6 # Leisure place
        p = rand()
		person.time_spent_out += 1
        if p < _come_back_from_leisure(person.time_spent_out)
            person.movement_state = 5
			person.time_spent_out = 0
        end
    end

    return state != person.movement_state
end

function _student_next_step(time::DateTime, person::Person)
    state = person.movement_state

    # Handle day end 
    if Dates.hour(time) == DAY_END
        person.movement_state = 1
        return true
    end

    if state == 1 # Morning state
        person.movement_state = 2
    elseif state == 2 # Transport before work state
        person.movement_state = 3
    elseif state == 3 && is_school_end_time(time) # Working state
        person.movement_state = 4
    elseif state == 4 # Transport after work state
        person.movement_state = 5
    elseif state == 5 # Home after work
        p = rand()
        if p < _student_go_leisure(time)
            person.movement_state = 6
        end
    elseif state == 6 # Leisure place
        p = rand()
		person.time_spent_out += 1
        if p < _come_back_from_leisure(person.time_spent_out)
            person.movement_state = 5
			person.time_spent_out = 0
        end
    end

    return state != person.movement_state
end

function _home_next_step(time::DateTime, person::Person)
    state = person.movement_state

    # Handle day end 
    if Dates.hour(time) == DAY_END
        person.movement_state = 1
        return true
    end

    p = rand()
    if state == 1
		if p < _home_go_leisure(time)
        	person.movement_state = 2
		end
    elseif state == 2
		person.time_spent_out += 1
        if p < _come_back_from_leisure(person.time_spent_out)
            person.movement_state = 1
            person.time_spent_out = 0
        end
    end

    return state != person.movement_state
end


function _worker_go_leisure(time::DateTime)
    return (WORK_END + 1)^5 * 0.3 / Dates.hour(time)^5
end


function _student_go_leisure(time::DateTime)
    return pdf(Normal(20, 1.5), Dates.hour(time)) + 0.3
end

"""
	Get probability go to leisure for home persons, based on the day phase (morning, afternoon, evening)
"""
function _home_go_leisure(time::DateTime)
	μ = 0.0
	σ = 0.0
	if _is_morning(time)
		μ = mean([DAY_START, DAY_MEDIAN])
		σ = 0.8
	elseif _is_afternoon(time)
		μ = mean([DAY_MEDIAN, WORK_END])
		σ = 0.8
	elseif _is_evening(time)
		μ = mean([WORK_END, DAY_END])
		σ = 0.8
	end
	
	return pdf(Normal(μ, σ), Dates.hour(time))
end

"""
	Get the probability of stay in the current leisure place after x hour
	Made to have the following state:  
		f(1) ≈ 0.4
		f(2) ≈ 0.2
		f(3) ≈ 0.1
		f(4) ≈ 0
"""
function _stay_leisure(x::Int)
    return -0.3153951 + (1132000 - -0.3153951) / (1 + (x / 1.252143e-7)^0.8598911)
end

function _come_back_from_leisure(time_out::Int)
    return round(1 - _stay_leisure(time_out), digits = 2)
end
	
	
# function _worker_get_probability_stay_leisure(time::DateTime)
# 	return (WORK_END + 2)^10 * 0.8 / Dates.hour(time)^10
# end