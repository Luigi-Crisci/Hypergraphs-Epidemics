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