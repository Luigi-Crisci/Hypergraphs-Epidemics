function next_10_multiple(x::Int)
	while x % 10 != 0
		x = x + 1
	end
	return x
end

"""
	Return occupation distribution
"""
function get_occupation_distribution_index(age::Int)
	return age >= 10 ? age / 10 : -1
end