#! /usr/bin/ruby
#
require 'socket'
require 'optparse'

def generate_traffic(dest_ip, th_count, m_count, dest_lowest_port, dest_hi_port, amb_mode)
	th_count = (th_count || 10).to_i
	m_count = (m_count || 10).to_i
	dest_lowest_port = (dest_lowest_port || 50000).to_i
	dest_hi_port = (dest_hi_port || 60000).to_i
	amb_mode = amb_mode || false

	threads = []
	if not amb_mode
		th_count.times do
			threads << Thread.new() do 
				s = UDPSocket.new
				m_count.times do 
					s.send "udp burden", 0, dest_ip, rand(dest_lowest_port..dest_hi_port)
				end
				s.close
			end
		end
	else
		th_count.times do
			threads << Thread.new() do 
				s = UDPSocket.new
				while true
					s.send "udp burden", 0, dest_ip, rand(dest_lowest_port..dest_hi_port)
					sleep (1.0/m_count)
				end
				s.close
			end
		end
	end
	threads.each{|th| th.join}
end

if __FILE__ == $0 then
	options = {}
	optparse = OptionParser.new do |opts|
		opts.banner = "Usage: #{$0} <dest_ip> [opts]\n-h or --help to see help message"
		opts.on('-t COUNT', '--target', "Thread count") do |o|
			options[:t] = o
		end
		opts.on('-m COUNT', '--message-count', "Message count. Message per sec in amb mode") do |o|
			options[:m] = o
		end
		opts.on('-l BOUND', '--lower', "Destination port lower bound") do |o|
			options[:l] = o
		end
		opts.on('-u BOUND', '--upper', "Destination port highter bound") do |o|
			options[:u] = o
		end
		opts.on('-a', '--ambient', "Do not stop") do |o|
			options[:a] = o
		end

		opts.on_tail( '-h', '--help', 'Display this screen' ) do
			puts opts
			exit
		end
	end

	if ARGV[0].nil?
		puts optparse.banner
		exit
	end
	if ARGV[0] == '-h' or ARGV[0] == '--help'
		optparse.parse(ARGV)
	end


	if 0 == (ARGV[0] =~ /\A(\d{1,3}\.){3}\d{1,3}$/)
		dest_ip = ARGV[0]
	else
		puts "invalid dest ip: #{ARGV[0]}"
		puts optparse.banner
		exit
	end

	begin optparse.parse(ARGV.drop(1))
		rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
			puts e
			puts optparse.banner
			exit
	end

	generate_traffic(dest_ip, options[:t],options[:m],options[:l],options[:u], options[:a])
	
end
