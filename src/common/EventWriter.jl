struct Event
	id_node::Int
	position_node::Int
	position_type::Int
	time::DateTime
end

struct EventWriter
	file::IOStream
	queue::Queue{Event}

	function EventWriter(filename::String)
		file = open(filename,"w+")
		queue = Queue{Event}()
		_write_header(file)
		new(file,queue)
	end
end

function _write_header(file)
	write(file,"Time,Id,position\n")
end

function add_event(event_writer::EventWriter,event::Event)
	#FIXME: Just a way to handle null event. Must be substituted by a better structure
	if event.id_node == -1
		return 
	end
	enqueue!(event_writer.queue,event)
end

function write_events(event_writer::EventWriter)
	for event in event_writer.queue
		write(event_writer.file,"$(event.time),$(event.id_node),$(event.position_node)\n")
		dequeue!(event_writer.queue)
	end
end

function close_writer(event_writer::EventWriter)
	write_events(event_writer)
	close(event_writer.file)
end