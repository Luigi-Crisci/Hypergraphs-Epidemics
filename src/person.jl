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
	homes::Array{Person,1}
	num_components::Int

	function Household(id::Int,num_components::Int)
		new(id,[],[],[],num_components)
	end

end





