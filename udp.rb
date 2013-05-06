require 'socket'
if __FILE__ ==  $0 then
	threads = []
	for port in 8000..8080
		threads << Thread.new(port) do |p|
			sleep(0.2)
			s = UDPSocket.new
			10000.times do |i|
				s.send "message to R", 0, "192.168.1.1",p
				puts "sending message #{i} from port #{p}"
			end
			s.close
		end
	end
	threads.each{|th| th.join}
end
