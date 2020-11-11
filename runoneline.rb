#!/bin/env ruby
require 'optimist'
options = Optimist::options do
  banner <<-EOS
submit one line from a file of commands to the q

file should contain commands to be run, one line per command, no extraneous text

Usage:
      runoneline [ -l linenumber] [ -g groupsize ] file

EOS

  opt :line,
      "line to run",
      :default => 1

  opt :group,
      "number of lines to run at once (lines l, l+1, l+2, ..., l+g-1 will be run)",
      :default => 1
end

f = ARGV[0]
# p options

puts "reading commands from #{f}"
lines = File.readlines(f)
st=(options[:line]-1)*options[:group]
en=(options[:line])*options[:group] - 1

if lines.length < st
  puts "Only #{lines.length} lines found, which is < the line requested, #{st}"
else
  i=st
  j=[en , lines.length-1].min
  (i..j).each { |idx|
    puts "Running " + lines[ idx ].to_str
    system(lines[ idx ])
  }
end

exit 0





  

   
