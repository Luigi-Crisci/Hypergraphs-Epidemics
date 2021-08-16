mutable struct Person
	id::Int
	age::Int
	occupation::Int

	movement_state::Int
	work_school_place::Int
	transport::Int
	time_spent_out::Int

	function Person(id::Int, age::Int, occupation::Int, work_school_place::Int, transport::Int)
		new(id,age,occupation,1,work_school_place,transport,0)
	end
end

mutable struct Household
	id::Int
	workers::Array{Person,1}
	students::Array{Person,1}
	unemployeds::Array{Person,1}
	num_components::Int

	function Household(id::Int,num_components::Int)
		new(id,[],[],[],num_components)
	end

end

mutable struct Company
	id::Int
	max_size::Int
	current_size::Int

	function Company(id::Int,max_size::Int)
		new(id,max_size,0)
	end
end

mutable struct Contact_simulation_options
	work_place_num::Int
	school_place_num::Int
	transport_place_num::Int
	leisure_place_num::Int
	days::Int
end

