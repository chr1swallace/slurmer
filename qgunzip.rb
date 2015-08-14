#!/usr/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/bin/Qsub.rb'

## put "gunzip argv" on the Q for each thing in @ARGV
t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-gzip-#{t}.sh", :account=>ENV["SLURMACCOUNT"])
ARGV.each do |a|
  q.add("gunzip " + a)
end
q.close()

