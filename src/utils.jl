function next_10_multiple(x::Int)
	while x % 10 != 0
		x = x + 1
	end
	return x
end

"""
	Return exact age, or the Integer mean between min and max age
"""
function calculate_age(exact,min,max)
	return exact != -1 ? exact : (min == -1 || max == -1 ? -1 : floor(Int,(min+max)/2) )
end
