#! /usr/bin/ruby
load './myperf.rb'

s = MyPerf::Server.new 3333, 100
s.start

