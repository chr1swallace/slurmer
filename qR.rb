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

options = ARGV.getopts("t:","a:")
if(!options["a"]) then
  options["a"] = ACCOUNT
end
if(!options["t"]) then
  options["t"] = TIME
end

p options

## put "gzip argv" on the Q for each thing in @ARGV
t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-R-#{t}.sh",
           :tasks=>'1',
           :time=>options["t"],
           :account=>options["a"])

q.add( "R CMD BATCH " + ARGV.join(" ") )

q.close()

