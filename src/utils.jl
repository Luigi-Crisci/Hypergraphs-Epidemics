mutable struct Contact_simulation_options
	work_place_num::Int
	school_place_num::Int
	transport_place_num::Int
	leisure_place_num::Int
end


function next_10_multiple(x::Int)
	while x % 10 != 0
		x = x + 1
	end
	return x
end

function is_working_end_time(time::DateTime)
	return Dates.hour(time) >= WORK_END
end

function is_school_end_time(time::DateTime)
	return Dates.hour(time) >= SCHOOL_END
end

function _is_morning(time::DateTime)
	return DAY_START <= Dates.hour(time) < DAY_MEDIAN
end

function _is_afternoon(time::DateTime)
	return DAY_MEDIAN <= Dates.hour(time) < WORK_END
end

function _is_evening(time::DateTime)
	return WORK_END <= Dates.hour(time) < DAY_END
end

function _get_day_phase(time::DateTime)
	if _is_morning(time)
		return MORNING
	elseif _is_afternoon(time)
		return AFTERNOON
	elseif _is_evening(time)
		return EVENING
	end
end

"""
	Return exact age, or the Integer mean between min and max age
"""
function calculate_age(exact,min,max)
	return exact != -1 ? exact : (min == -1 || max == -1 ? -1 : floor(Int,(min+max)/2) )
end