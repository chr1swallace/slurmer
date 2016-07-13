#!/usr/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/slurmer/Qsub.rb'

## put "gzip argv" on the Q for each thing in @ARGV
now = Time.now
now = now.strftime("%Y%m%d")

require 'optparse'
options = ARGV.getopts("t:","a:","x","h")
if(options["h"]) then
  puts "Usage:
qlines.rb [-a account] [-t time] [-x] [-h] file

-a account
   If not supplied, account will be found from the environment variable SLURMACCOUNT
-t time
   format hh:mm:ss
   default is 01:00:00 (1 hour)
-x 
   by default, this script assumes you want one CPU per line.  If you want to parallelise within your job and want one node per line, use the -x flag to use the --exclusive option for srun
-h
   print this message and exit

file should contain commands to be run on the queue, one line per command, no extraneous text
"
  exit
end

if(!options["a"]) then
  options["a"] = ACCOUNT
end
if(!options["t"]) then
  options["t"] = TIME
end
if(!options["x"]) then
  options["x"] = "--exclusive"
else
  options["x"] = " "
end

# require 'Trollop'
# opts = Trollop::options do
#   opt :quiet, "Use minimal output", :short => 'q'
#   opt :interactive, "Be interactive"
#   opt :filename, "File to process", :type => String
# end

p options

## how many tasks
f = ARGV[0]

q=Qsub.new("slurm-lines-#{now}.sh",
           :tasks=>'16',
           :time=>options["t"],
           :account=>options["a"],
           :excl=>options["x"])

## read lines from a file, then add them to the jobs list
puts "reading commands one line at a time from #{f}"
lines = File.readlines(f)
lines.each do |line|
  puts line
  q.add(line.chomp)
end
q.close()

