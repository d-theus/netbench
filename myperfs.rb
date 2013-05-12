#! /usr/bin/ruby
#
require 'optparse'
load './myperf.rb'


if __FILE__ == $0 then
	options = {}
	optparse = OptionParser.new do |opts|
		opts.banner = "Usage: #{$0} [opts]\n-h or --help to see help message"
		opts.on('-c COUNT', '--clients', "Maximum number of clients") do |o|
			options[:c] = o
		end

		opts.on('-p PORT', '--port', "Set port to listen on") do |o|
			options[:p] = o
		end

		opts.on_tail( '-h', '--help', 'Display this screen' ) do
			puts opts
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
		s = MyPerf::Server.new options[:p]||3333, options[:c]||10
		s.start
	rescue Errno::EADDRINUSE, Errno::EPIPE => e
		s.finalize unless s.nil?
		puts e
	end
end
