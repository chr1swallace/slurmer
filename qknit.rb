#!/usr/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/slurmer/Qsub.rb'

# require 'getoptlong'
# options = GetoptLong.new(
#   [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
#   [ '--time', '-t', GetoptLong::REQUIRED_ARGUMENT ],
#   [ '--account', '-a', GetoptLong::REQUIRED_ARGUMENT ]
# )

# opts.each do |opt, arg|
#   case opt
#   when '--time'
#     time = arg
#   when '--account'
#     account = arg
#   end
# end

# p time
# p account

require 'optparse'
options = ARGV.getopts("t:","a:","h","r")
if(options["h"]) then
  puts "Usage:
qknit.rb [-a account] [-t time] [-h] [-r] file.Rmd

-a account
   If not supplied, account will be found from the environment variable SLURMACCOUNT
-t time
   format hh:mm:ss
   default is 01:00:00 (1 hour)
-h
   print this message and exit
-r
   autoRun (or autoqueue) - use with caution

Rscript will be run on the queue (`Rscript [Rscript args]`), with 16 cores booked, so using parallelisation with 16 cores within the script is recommended."
  exit
end
if(!options["a"]) then
  options["a"] = ACCOUNT
end
if(!options["t"]) then
  options["t"] = TIME
end
if(!options["r"]) then
  options["r"] = false
end

p options

## put "gzip argv" on the Q for each thing in @ARGV
t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-R-#{t}.sh",
           :tasks=>'16',
           :time=>options["t"],
           :account=>options["a"],
           :autorun=>options["r"])


q.add( "Rscript -e \"library(knitr);knit('" + ARGV[0] + "')\"") #.join(" ") )
#q.add( ARGV.join(" ") )

q.close()

