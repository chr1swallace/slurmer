#!/usr/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/slurmer/Qsub.rb'

## put "gzip argv" on the Q for each thing in @ARGV
now = Time.now
now = now.strftime("%Y%m%d")

require 'optparse'
options = ARGV.getopts("t:","c:","a:","j:","x","h","r")
if(options["h"]) then
  puts "Usage:

qlines.rb [-a account] [-j jobname] [-t time] [-x] [-h] [-r] file

-a account
   If not supplied, account will be found from the environment
   variable SLURMACCOUNT

-j jobname
   If not supplied, jobname will be set to qlines

-t time
   format hh:mm:ss
   default is 01:00:00 (1 hour)

-x 
   by default, this script assumes you want one core per line.  If you
   want to parallelise within your job and want one node per line, use
   the -x flag to use the --exclusive option for srun

-c (number of) cpus per task
   by default, this script assumes you want one core per line.  If you 
   want more, eg to expand memory, set -c to a number > 1 and <=16.   

-h
   print this message and exit

-r
   autoRun (or autoqueue) - use with caution

-f file 
   file should contain commands to be run on the queue, one line per
   command, no extraneous text

command 
"
  exit
end

# args= { :job => "qlines",
#         :tasks => '16',
#         :excl => " " }
# options[:j] = options[:j] if options[:j]
# args[:time] = options[:t] if options[:t]
# args[:account] = options[:a] if options[:a]
# args[:excl] = "--exclusive" if options[:x]
if(!options["j"]) then
  options["j"] = "qlines"
end
if(!options["a"]) then
  options["a"] = ACCOUNT
end
if(!options["t"]) then
  options["t"] = TIME
end
if(!options["c"]) then
  options["c"] = "1"
end
if(!options["x"]) then
  options["x"] = " "
else
  options["x"] = "--exclusive"
end
if(!options["r"]) then
  options["r"] = false
end
# require 'Trollop'
# opts = Trollop::options do
#   opt :quiet, "Use minimal output", :short => 'q'
#   opt :interactive, "Be interactive"
#   opt :filename, "File to process", :type => String
# end

p options

## how many tasks
#f = ARGV[0]


q=Qsub.new("slurm-lines-#{now}.sh",
           :job=>options["j"],
           :tasks=>'1',
           :cpus=>options["c"].to_s,
           :time=>options["t"],
           :account=>options["a"],
           :excl=>options["x"],
           :autorun=>options["r"])

## read lines from a file, then add them to the jobs list
if(options["f"]) then
  f=options["f"]
  puts "reading commands one line at a time from #{f}"
  lines = File.readlines(f)
  lines.each do |line|
    puts line
    q.add(line.chomp)
  end
else
  q.add( ARGV.join(" ") )
end
q.close()

