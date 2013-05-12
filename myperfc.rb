#! /usr/bin/ruby
load './myperf.rb'

c = MyPerf::Client.new 'localhost', 3333
c.test
