
USER=ENV['USER']
QDIR="/scratch/#{USER}/Q"
HEADER_CONST='#!/bin/bash'
TAIL_CONST='. /etc/profile.d/modules.sh # Leave this line (enables the module command)
module purge                # Removes all modules still loaded
module load default-impi    # REQUIRED - loads the basic environment
module load R/3.3.0 # latest R
module load rstudio/0.99/rstudio-0.99 # to match interactive session
export I_MPI_PIN_ORDER=scatter # Adjacent domains have minimal sharing of caches/sockets
JOBID=$SLURM_JOB_ID
echo -e JobID: $JOBID
echo Time: `date`
echo Running on master node: `hostname`
echo Current directory: `pwd`
if [ "$SLURM_JOB_NODELIST" ]; then
        #! Create a machine file:
        export NODEFILE=`generate_pbs_nodefile`
        cat $NODEFILE | uniq > machine.file.$JOBID
        echo -e "\nNodes allocated:\n================"
        echo `cat machine.file.$JOBID | sed -e \'s/\..*$//g\'`
fi

'

## DEFAULTS
ACCOUNT=ENV["SLURMACCOUNT"]
TIME='01:00:00' # hh:mm:ss

class Qsub
  def initialize(file="runme.sh", opts = {})
    defaults={:job=>'rubyjob',:account=>ACCOUNT,:nodes=>'1',:tasks=>'16',:time=>TIME,:mail=>'FAIL,TIME_LIMIT',:p=>ENV["SLURMHOST"],:excl=>" ",:autorun=>false}
    p opts
    @file_name=file
    @file = File.open(file,"w")
    @job=opts[:job] || defaults[:job]
    @account=opts[:account] || defaults[:account]
    @excl=opts[:excl] || defaults[:excl]
    @nodes=(opts[:nodes] || defaults[:nodes]).to_s
    @tasks=(opts[:tasks] || defaults[:tasks]).to_s
#    @cpus=(@tasks.to_i == 1 && opts[:p] == 'sandybridge' ? '16' : '1')
    @cpus= (opts[:cpus] || (16 / (@tasks.to_i)) ).to_s
    @time=opts[:time] || defaults[:time]
    @mail=opts[:mail] || defaults[:mail]
    @p=opts[:p] || defaults[:p]
    @counter_outer=0
    @counter_inner=0
    @jobfile=File.open(jobfile_name(),"w")
    @mem= (63900/ (@tasks.to_i) ).floor
    @autorun=opts[:autorun] || defaults[:autorun]
    ## check
    if(@account.nil?)
      raise "environment variable SLURMACCOUNT not set"      
    end
    if(@p.nil?)
      raise "environment variable SLURMHOST not set"      
    end
  end
  def jobfile_name()
    @file_name + @counter_outer.to_s
  end
  def add_header(text)
    @jobfile.puts(text)
  end
  def add(command)
    if @counter_inner == @tasks.to_i
      @jobfile.puts("wait\n")
      @jobfile.close()
      @counter_outer += 1
      @counter_inner = 0
    end
    if @counter_inner == 0
      if @counter_outer > 0
        @jobfile=File.open(jobfile_name(),"w")
      end
      @file.puts("sbatch " + jobfile_name())
      init_job()
    end
    @jobfile.puts 'echo "running" ' + command + "\n"
    @jobfile.puts 'srun -n1 ' + @excl + ' ' + command + " &\n"
    @counter_inner += 1
  end
  def init_job()
    @jobfile.puts(HEADER_CONST)
    @jobfile.puts '#SBATCH -J ' + @job
    @jobfile.puts '#SBATCH -A ' + @account
    @jobfile.puts '#SBATCH --nodes ' + @nodes
    @jobfile.puts '#SBATCH --ntasks ' + @tasks
    @jobfile.puts '#SBATCH --cpus-per-task ' + @cpus
    @jobfile.puts '#SBATCH --time ' + @time
    @jobfile.puts '#SBATCH --mail-type ' + @mail
#    @jobfile.puts '#SBATCH --mem ' + @mem.to_s
    @jobfile.puts '#SBATCH -p ' + @p
    @jobfile.puts(TAIL_CONST)
  end
  def close
    @jobfile.puts("wait\n")
    @jobfile.close()
    @file.close()
    if @autorun
      system("bash -l " + @file_name)
    else
      puts "now run"
      puts "bash -l " + @file_name
    end
  end
end

def qone(command,args,filestub)
  q=Qsub.new("#{QDIR}/#{filestub}.sh",args)
  q.add("#{command} > #{QDIR}/#{filestub}.out 2>&1")
  q.close()
end
