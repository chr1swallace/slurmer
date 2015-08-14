#!/usr/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/slurmer/Qsub.rb'

## put "gzip argv" on the Q for each thing in @ARGV
t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-gzip-#{t}.sh")
ARGV.each do |a|
  q.add("gzip " + a)
end
q.close()

