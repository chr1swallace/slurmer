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

options = ARGV.getopts("t:","c:","a:","j:","x","h","r","p:")
if(!options["j"]) then
  options["j"] = "qCom"
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

p options

## put "argv" on the Q for each thing in @ARGV
t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-#{t}.sh",
           :job=>options["j"],
           :tasks=>'1',
           :cpus=>options["c"].to_s,
           :time=>options["t"],
           :account=>options["a"],
           :excl=>options["x"],
           :autorun=>options["r"],
           :p=>options["p"])

q.add( ARGV.join(" ") )

q.close()
