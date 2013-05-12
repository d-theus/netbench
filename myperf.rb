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
		def initialize(port, accepts)
			@accepts = accepts
			@s = Socket.new :INET, :STREAM, 0
			@s.bind(Addrinfo.tcp '127.0.0.1', port)
		end
		def start
			puts "This is MyPerf server. TCP-based bandwidth tester."
			threads = []
			@s.listen(@accepts)
			while true
				cs, ca = @s.accept
				th =  Thread.new(cs, ca) do |cs, ca|
					puts "New client: #{ca.ip_address} : #{ca.ip_port}"
					while true
						cs.puts M_INIT
						M_COUNT.times do
							cs.puts M_DUMMY
						end
						cs.puts M_END
						repl = cs.gets
						break if (repl =~ /#{M_REPEAT}/).nil?
						sleep 0.5
					end
					puts "End"
				end
				th.join
				threads << th
			end
		end
	end

	class Client
		@s
		def initialize(ip, port)
			@s = Socket.new :INET, :STREAM, 0
			Ncurses.initscr
			Ncurses.cbreak           # provide unbuffered input
			Ncurses.noecho           # turn off input echoing
			Ncurses.nonl             # turn off newline translation
			Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
			Ncurses.stdscr.keypad(true)     # turn on keypad mode
			Ncurses.refresh
			Ncurses.mvaddstr 1,1, "MyPerf client. Connected to #{ip}:#{port}"
			begin
				@s = TCPSocket.new ip, port
			rescue 
			end
		end

		def finalize
			Ncurses.echo
			Ncurses.nocbreak
			Ncurses.nl
			Ncurses.endwin
			@s.close
		end

		def test 
			while true
				Ncurses.mvaddstr 5,5, " "*75
				msg = @s.gets
				if !(msg.lstrip.rstrip =~ /#{MyPerf::M_INIT}/).nil? then
					tmstmp = Time::now
					while  (msg.lstrip.rstrip =~ /#{MyPerf::M_END}/).nil? 
						msg = @s.gets
					end
					tval = Time::now - tmstmp
					Ncurses.mvaddstr 5,5,"Avg. tranfer speed: #{(MyPerf::MsgSize * MyPerf::M_COUNT)/tval/1024} Kbps" + "\n"
					Ncurses.stdscr.refresh
					sleep 0.5
					@s.puts M_REPEAT
				else
					Ncurses.mvaddstr 5,5,"No initial sequence" + "\n"
					Ncurses.stdscr.getch()
					finalize
					return
				end
			end
			Ncurses.stdscr.getch()
			finalize
		end
	end
end

