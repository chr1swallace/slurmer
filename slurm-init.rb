#!/usr/bin/ruby

require 'optparse'

## standard text
first_line='#!/bin/bash'
tail='. /etc/profile.d/modules.sh # Leave this line (enables the module command)
module purge                # Removes all modules still loaded
module load default-impi    # REQUIRED - loads the basic environment
export I_MPI_PIN_ORDER=scatter # Adjacent domains have minimal sharing of caches/sockets
JOBID=$SLURM_JOB_ID
echo -e "JobID: $JOBID
echo "Time: `date`
echo "Running on master node: `hostname`
echo "Current directory: `pwd`
if [ "$SLURM_JOB_NODELIST" ]; then
        #! Create a machine file:
        export NODEFILE=`generate_pbs_nodefile`
        cat $NODEFILE | uniq > machine.file.$JOBID
        echo -e "\nNodes allocated:\n================"
        echo `cat machine.file.$JOBID | sed -e \'s/\..*$//g\'`
fi

'

## defaults
options = {  
  :J => 'slurmjob',
  :A => ENV["SLURMACCOUNT"],
  :nodes => '1',
  :ntasks  => '16',
  :time => '01:00:00',
  :mail => 'ALL',
  :p => ENV["SLURMHOST"]
}
optnames = {  
  :J => '-J',
  :A => '-A',
  :nodes => '--nodes',
  :ntasks  => '--ntasks',
  :time => '--time',
  :mail => '--mail-type',
  :p => '-p'
}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: slurm-init.rb [options]"

  opts.on('-J', '--jobname NAME', 'Job name') { |v| options[:J] = v }
  opts.on('-A', '--account NAME', 'Account') { |v| options[:A] = v }
  opts.on('-n', '--nodes NODES', 'Nodes') { |v| options[:nodes] = v }
  opts.on('--tasks TASKS', 'Ntasks') { |v| options[:ntasks] = v }
  opts.on('-t TIME', '--time', 'hh:mm:ss') { |v| options[:time] = v }
  opts.on('--mail MAIL', 'mail-type') { |v| options[:mail] = v }
  opts.on('-p', '--host NAME', 'Host') { |v| options[:p] = v }

  # This displays the help screen, all programs are  assumed to have this option.   
  opts.on( '-h', '--help', 'Display this screen' ) { 
    puts opts
    exit   
  }
end.parse!

p options

## initialize file
ofile=File.open(ARGV[0], 'w')
ofile.puts(first_line)

# write options
options.each do |key, array|
  ofile.write '#SBATCH ' + optnames[key] + ' ' + array + "\n"
end

## tail
ofile.puts(tail)
