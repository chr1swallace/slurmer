#!/usr/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/slurmer/Qsub.rb'

## put "gzip argv" on the Q for each thing in @ARGV
t = Time.now
t = t.strftime("%Y%m%d")
q=Qsub.new("slurm-R-#{t}.sh",:tasks=>'1')

q.add( "R CMD BATCH " + ARGV.join(" ") )

q.close()

