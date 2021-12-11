#!/usr/bin/env ruby

require 'benchmark'
require_relative '../lib/wexpr.rb'

require 'optparse'

options = {
	:filePath => nil,
	:iterations => 1
}

OptionParser.new do |opts|
	opts.banner = "Usage: benchmarkFile.rb [options]"

	opts.on("-f", "--file=FILE", "The file to use") do |v|
		options[:filePath] = v
	end

	opts.on("-i", "--iterations=ITERATIONS", "The number of iterations to run") do |v|
		options[:iterations] = v.to_i
	end
end.parse!

if options[:filePath] == nil
	STDERR.puts "Provide a file via -f"
	exit
end

str = File.read(options[:filePath])

time = Benchmark.measure {
	options[:iterations].times do
		Wexpr.load(str)
	end
}

STDERR.puts time

