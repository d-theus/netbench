require 'socket'
require 'rubygems'
require 'ncurses'

module MyPerf
	M_INIT = "begin"
	M_DUMMY = "00000000000000000000000000000000"
	M_REPEAT = "repeat"
	M_COUNT = 10000
	M_END = "end"
	MsgSize = M_DUMMY.bytesize
	class Server
		@s
		@accepts
		@port
		def initialize(port, accepts)
			@accepts = accepts
			@port = port
			@s = Socket.new :INET, :STREAM, 0
			timeval = [1, 0].pack("l_2")
			@s.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval
			@s.bind(Addrinfo.tcp '127.0.0.1', @port)
			Signal.trap("INT") do
				puts "Shutting down"
				self.finalize
				exit
			end
		end
		def finalize 
			@s.close unless @s.nil?
		end
		def start
			puts "This is MyPerf server. TCP-based bandwidth tester."
			puts "Listening on port #{@port}. Accepting up to #{@accepts} clients."
			threads = []
			#@s.listen(@accepts.to_i)
			@s.listen(10)
			while true
				begin
					cs, ca = @s.accept
					th =  Thread.new(cs, ca) do |cs, ca|
						puts "New client: #{ca.ip_address} : #{ca.ip_port}"
						while true
							unless cs.closed?
								cs.puts M_INIT
								M_COUNT.times do
									cs.puts M_DUMMY
								end
								cs.puts M_END
								repl = cs.gets
								break if (repl =~ /#{M_REPEAT}/).nil?
									sleep 0.5
							end
						end
						puts "End"
					end
					threads << th
					th.join
				rescue Errno::EBADF
				rescue Errno::ECONNRESET, Errno::EPIPE, IOError
					cs.close unless cs.nil?
				end
			end
		end
	end

	class Client
		@s
		@ip
		@port
		def initialize(ip, port)
			@s = Socket.new :INET, :STREAM, 0
			@ip = ip
			@port = port
			begin
				@s = TCPSocket.new ip, port
				timeval = [1, 0].pack("l_2")
				@s.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval
				Signal.trap("INT") do
					self.finalize
					puts "Quitting"
					exit
				end
			rescue Errno::ETIMEDOUT
				puts "Server not responding"
			end
		end

		def finalize
			sleep 0.5
			Ncurses.echo
			Ncurses.nocbreak
			Ncurses.nl
			Ncurses.endwin
			@s.close unless @s.closed? unless @s.nil?
		end

		def test 
			Ncurses.initscr
			Ncurses.cbreak           # provide unbuffered input
			Ncurses.noecho           # turn off input echoing
			Ncurses.nonl             # turn off newline translation
			Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
			Ncurses.stdscr.keypad(true)     # turn on keypad mode
			Ncurses.refresh
			Ncurses.mvaddstr 1,1, "MyPerf client. Connected to #{@ip}:#{@port}"
			while true
				begin
					Ncurses.mvaddstr 5,5, " "*75
					unless @s.closed?
						msg = @s.gets || ""
						if !(msg.lstrip.rstrip =~ /#{MyPerf::M_INIT}/).nil? then
							tmstmp = Time::now
							while  (msg.lstrip.rstrip =~ /#{MyPerf::M_END}/).nil? 
								msg = @s.gets
							end
							tval = Time::now - tmstmp
							Ncurses.mvaddstr 5,5,"Avg. tranfer speed: #{(MyPerf::MsgSize * MyPerf::M_COUNT)/tval/1024} Kbps" + "\n"
							Ncurses.stdscr.refresh
							sleep 0.5
							@s.puts M_REPEAT unless @s.closed?
						else
							Ncurses.mvaddstr 5,5,"No initial sequence" + "\n"
							Ncurses.mvaddstr 6,5,"Most likely server is down, or desyncronized" + "\n"
							Ncurses.mvaddstr 7,5,"Press any key to quit" + "\n"
							Ncurses.stdscr.getch()
							finalize
							return
						end
					end
				rescue IOError
					return
				end
			end
			Ncurses.stdscr.getch()
			finalize
		end
	end
end 
