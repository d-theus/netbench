#! /usr/bin/ruby
#
require 'socket'
require 'optparse'

def generate_traffic(dest_ip, th_count, m_count, dest_lowest_port, dest_hi_port)
	th_count = th_count || 10
	m_count = m_count || 10
	dest_lowest_port = dest_lowest_port || 50000
	dest_hi_port = dest_hi_port || 60000

	threads = []
	th_count.times do
		threads << Thread.new() do 
			s = UDPSocket.new
			m_count.times do 
				s.send "udp payload", 0, dest_ip, rand(dest_lowest_port..dest_hi_port)
			end
			s.close
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
		opts.on('-m COUNT', '--message-count', "Message count") do |o|
			options[:m] = o
		end
		opts.on('-l BOUND', '--lower', "Destination port lower bound") do |o|
			options[:l] = o
		end
		opts.on('-u BOUND', '--upper', "Destination port highter bound") do |o|
			options[:u] = o
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

	if 0 == (ARGV[0] =~ /\A(\d{1,3}\.){3}\d{1,3}$/) then
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

	generate_traffic(dest_ip, options[:t],options[:m],options[:l],options[:u])
	
end
