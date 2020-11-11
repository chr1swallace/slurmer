#!/home/cew54/localc/bin/ruby

## files to zip in ARGV

require ENV["HOME"] + '/slurmer/Qsub.rb'

## put "gzip argv" on the Q for each thing in @ARGV
now = Time.now
now = now.strftime("%Y%m%d")

require 'optimist'
options = Optimist::options do
#   require 'micro-optparse'
# options = Parser.new do |p|
  banner <<-EOS
qlines_asarray.rb to submit an array job to the q

Usage:
       qlines_asarray.rb [options] <filename>

where [options] are:
EOS

  opt :account,
      "account, optional, default is environment variable SLURMACCOUNT",
      :default => ACCOUNT
  opt :jobname,
      "job name, optional",
      :default => "qlines"
  opt :group,
      "Default is 1 = run one line per job. Can also group, so -g 3 would run 3 lines per job",
      :default => 1
  opt :time,
      "job time, format hh:mm:ss",
      :default => TIME
  # p.option :exclusive,
  #          "by default, this script assumes you want one core per line.  If you
  #  want to parallelise within your job and want one node per line, use
  #  the -x flag to use the --exclusive option for srun",
  #          :short => "x"
  opt :cpus,
      "number of cpus per task",
      :default => 1
  opt :autorun,
      "autoRun (or autoqueue) - use with caution",
      :short => 'r',
      :default => false
  opt :host,
      "host defaults to sensible choice based on accounts. But if you want to specify, eg, skylake-himem, add -p skylake-himem",
      :short => 'p',
      :default => HOSTS[ACCOUNT.upcase]
  opt :dependency,
      "dependency arguments that will be added to sbatch command line as --dependency ARGUMENTHERE. eg use -d after:jobid",
      :default => ''
  # opt :file,
  #     "filename, file should contain commands to be run on the queue, one line per command, no extraneous text"
end
Optimist::die "need at least one filename" if ARGV.empty?

## dependency
options[:dependency] = "--dependency #{options[:dependency]}" if options[:dependency] != ''
## exclusive
# if(!options["x"]) then
#   options["x"] = " "
# else
#   options["x"] = "--exclusive"
# end

p options

## how many tasks
f = ARGV[0]
lines = File.readlines(f)
puts lines.length
puts options[:group]
njobs= (lines.length / options[:group]).ceil

q=Qsub.new("slurm-lines-#{now}.sh",
           :job=>options[:jobname],
           :tasks=>'1',
           :cpus=>options[:cpus].to_s,
           :time=>options[:time],
           :array=>"1-#{njobs}",
           :account=>options[:account],
           :group=>options[:group],
           # :excl=>options["x"],
           :dependency=>options[:dependency],
           :autorun=>options[:autorun],
           :p=>options[:host])

q.add( "runoneline.rb -l $SLURM_ARRAY_TASK_ID -g #{options[:group]} #{f}" )
## read lines from a file, then add them to the jobs list
# puts "reading commands one line at a time from #{f}"
# lines.each do |line|
#   puts line
#   q.add(line.chomp)
# end
q.close()

