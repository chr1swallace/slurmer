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
options = ARGV.getopts("t:","a:","j:","h","r","c:","y:","n:","p:")
if(options["h"]) then
  puts "Usage:
qR.rb [-a account] [-t time] [-h] [-r] Rscript.file [Rscript args]

-a account
   If not supplied, account will be found from the environment variable SLURMACCOUNT
-t time
   format hh:mm:ss
   default is 01:00:00 (1 hour)
-h
   print this message and exit
-j 
   jobname
-r
   autoRun (or autoqueue) - use with caution
-c
   ncpu-per-task (default 1)

-y arraycom
   array - sets SBATCH --array ARG.  Eg -y 0-9 to iterate over values 0-9

-n 
   array argument name - otherwise set to 'taskid'

-p host defaults to sensible choice based on accounts.  But if you
   want to specify, eg, skylake-himem, add -p skylake-himem

Rscript will be run on the queue (`R CMD BATCH Rscript [Rscript args]`), with 16 cores booked, so using parallelisation with 16 cores within the script is recommended."
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
if(!options["c"]) then
  options["c"] = '1'
end
if(!options["j"]) then
  options["j"] = 'qR'
end
if(!options["n"]) then
  options["n"] = "taskid"
end


p options

## put "gzip argv" on the Q for each thing in @ARGV
t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-R-#{t}.sh",
           :tasks=>'1',
           :time=>options["t"],
           :account=>options["a"],
           :array=>options['y'] || '',
	   :cpus=>options["c"],
           :job=>options['j'],
           :autorun=>options["r"],
           :p=>options["p"])

## create arguments
args = ARGV.join(" ")
## add array?
if(options['y'])
  /--args/ =~ args || args = args + " --args "
  args = args + " #{options['n']}=$SLURM_ARRAY_TASK_ID "
end

q.add( "Rscript " + args )

#q.add( ARGV.join(" ") )

q.close()

