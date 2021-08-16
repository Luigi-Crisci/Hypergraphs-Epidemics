function _next_10_multiple(x::Int)
	while x % 10 != 0
		x = x + 1
	end
	return x
end

function _is_working_end_time(time::DateTime)
	return Dates.hour(time) >= WORK_END
end

function _is_school_end_time(time::DateTime)
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

function _is_holiday(time::DateTime)
	return Dates.issaturday(time) || Dates.issunday(time)
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



function is_student(p)
	return p.part_occupation == SCHOOL
end

function is_worker(p)
	return p.part_occupation == WORKING
end

function is_home(p)
	return p.part_occupation == UNEMPLOYED
end

# function divide_students_by_age(students)
# 	pre_school_students = []
# 	primary_students = []
# 	secondary_students = []
# 	higher_students = []
# 	for student in students
# 		if student.age <= PRE_SCHOOL_LIMIT
# 			push!(pre_school_students,student)
# 		elseif student.age <= PRIMARY_SCHOOL_LIMIT
# 			push!(primary_students,student)
# 		elseif student.age <= SECONDARY_SCHOOL_LIMIT
# 			push!(secondary_students,student)
# 		else
# 			push!(higher_students,student)
# 		end
# 	end

# 	return pre_school_students,primary_students, secondary_students, higher_students
# end