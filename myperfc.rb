#! /usr/bin/ruby
load './myperf.rb'
require 'optparse'

if __FILE__ == $0 then
	options = {}
	optparse = OptionParser.new do |opts|
		opts.banner = "Usage: #{$0} <server ip> [opts]\n-h or --help to see help message"

		opts.on('-p PORT', '--port', "Set port to connect to") do |o|
			options[:p] = o
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

	unless ARGV[0] == "-h" || ARGV[0] == "--help"
		if 0 == (ARGV[0] =~ /\A(\d{1,3}\.){3}\d{1,3}$/) then
			dest_ip = ARGV[0]
		else
			puts "invalid dest ip: #{ARGV[0]}"
			puts optparse.banner
			exit
		end
	end

	begin optparse.parse(ARGV)
	rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
		puts e
		puts optparse.banner
		exit
	end

	begin
	c = MyPerf::Client.new ARGV[0], options[:p]||3333 
	c.test
	rescue Errno::EPIPE, Errno::ECONNREFUSED, Errno::ENOTCONN => e
		c.finalize unless c.nil?
		puts e
	end
end
