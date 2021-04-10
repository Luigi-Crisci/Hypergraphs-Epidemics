function next_10_multiple(x::Int)
	while x % 10 != 0
		x = x + 1
	end
	return x
end