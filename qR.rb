#!/home/cew54/localc/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/slurmer/Qsub.rb'
require 'pry'
require 'optimist'
options = Optimist::options do
  banner <<-EOS
qR.rb to submit Rscript jobcs to the queue

Usage:
       qR.rb [options] Rscript_file.R [--args Rscript args]

where [options] are:
EOS

  opt :args,
      "arguments passed to Rscript, in the form arg1=value1 arg2=value2"
  opt :account,
      "account, optional, default is environment variable SLURMACCOUNT",
      :default => ACCOUNT
  opt :jobname,
      "job name, optional",
      :default => "qlines"
  opt :logfile,
      "log file for directing output, optional",
      :short => 'l',
      :type => :string
  opt :time,
      "job time, format hh:mm:ss default is 01:00:00 (1 hour)",
      :short => 't',
      :default => TIME
  # p.option :exclusive,
  #          "by default, this script assumes you want one core per line.  If you
  #  want to parallelise within your job and want one node per line, use
  #  the -x flag to use the --exclusive option for srun",
  #          :short => "x"
  opt :cpus,
      "number of cpus per task",
      :short => 'c',
      :default => 1
  opt :array,
      "sets BATCH --array ARG. Eg -y 0-9 to iterate over values 0-9",
      :short => 'y',
      :default => ''
  opt :arrayname,
      "array argument name - default 'taskid'",
      :short => 'n',
      :default => 'taskid'
opt :autorun,
      "autoRun (or autoqueue) - use with caution",
      :short => 'r'
  opt :host,
      "host defaults to sensible choice based on accounts. But if you want to specify, eg, skylake-himem, add -p skylake-himem",
      :short => 'p',
      :default => HOSTS[ACCOUNT.upcase]
  opt :dependency,
      "dependency arguments that will be added to sbatch command line as --dependency ARGUMENTHERE. eg use -d after:jobid",
      :type => :string
end
Optimist::die "need at least one filename" if ARGV.empty?

## dependency
options[:dependency] = "--dependency #{options[:dependency]}" unless options[:dependency].nil?

## exclusive
# if(!options["x"]) then
#   options["x"] = " "
# else
#   options["x"] = "--exclusive"
# end


# require 'optparse'
# options = ARGV.getopts("t:","a:","j:","l:","h","r","c:","y:","n:","p:")
# if(options["h"]) then
#   puts "Usage:
# qR.rb [-a account] [-t time] [-h] [-r] [-l logfile] Rscript.file [Rscript args]

# -a account
#    If not supplied, account will be found from the environment variable SLURMACCOUNT
# -t time
#    format hh:mm:ss
#    default is 01:00:00 (1 hour)
# -h
#    print this message and exit
# -j
#    jobname
# -l
#    logfile
# -r
#    autoRun (or autoqueue) - use with caution
# -c
#    ncpu-per-task (default 1)

# -y arraycom
#    array - sets SBATCH --array ARG.  Eg -y 0-9 to iterate over values 0-9

# -n
#    array argument name - otherwise set to 'taskid'

# -p host defaults to sensible choice based on accounts.  But if you
#    want to specify, eg, skylake-himem, add -p skylake-himem

# Rscript will be run on the queue (`R CMD BATCH Rscript [Rscript args]`), with 16 cores booked, so using parallelisation with 16 cores within the script is recommended."
#   exit
# end
# if(!options["a"]) then
#   options["a"] = ACCOUNT
# end
# if(!options["t"]) then
#   options["t"] = TIME
# end
# if(!options["r"]) then
#   options["r"] = false
# end
# if(!options["c"]) then
#   options["c"] = '1'
# end
# if(!options["j"]) then
#   options["j"] = 'qR'
# end
# if(!options["n"]) then
#   options["n"] = "taskid"
# end
# if(!options["n"]) then
#   options["n"] = "taskid"
# end
# # if(!options["l"]) then
# #   options["l"] = ""
# # end

# p options
# binding.pry

t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-R-#{t}.sh",
           :tasks=>'1',
           :time=>options[:time],
           :account=>options[:account],
           :array=>options[:array],
           :cpus=>options[:cpus],
           :job=>options[:jobname],
           :autorun=>options[:autorun],
           :p=>options[:host])

## script file
Rscript_file=ARGV.shift

## deal with arguments
args = options[:args] ? "--args #{ARGV.join(" ")}" : ''

## add array?
if(options[:array] != '')
  # /--args/ =~ args || args = args + " --args "
  args = " --args " unless options[:args]
  args = args + " #{options[:arrayname]}=$SLURM_ARRAY_TASK_ID "
end

## add logfile?
args = args + " >& #{options[:logfile]} " unless options[:logfile].nil?

q.add( "Rscript #{Rscript_file} #{args}" )

q.close()
