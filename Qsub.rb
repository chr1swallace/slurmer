
USER=ENV['USER']
# QDIR="/scratch/#{USER}/Q"
# load("/home/cew54/DIRS.txt")
HEADER_CONST='#!/bin/bash'
TAIL_CONST='. /etc/profile.d/modules.sh # Leave this line (enables the module command)
module purge                # Removes all modules still loaded
module load default-impi    # REQUIRED - loads the basic environment
. /home/cew54/.modules
  # module load gcc/5.3.0
# module load zlib/1.2.8
# module load R/3.3.2 # latest R
# module load rstudio/0.99/rstudio-0.99 # to match interactive session
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
TAIL_CDS3='. /etc/profile.d/modules.sh # Leave this line (enables the module command)
module purge                # Removes all modules still loaded
module load rhel7/default-peta4            # REQUIRED - loads the basic environment
. /home/cew54/.modules-cds3 
# module load r-3.4.1-gcc-5.4.0-uj5r3tk
# module load rstudio/0.99/rstudio-0.99 # to match interactive session
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
HOSTS= { 'MRC-BSU-SL2' => 'mrc-bsu-sand',
         'MRC-BSU-SL2-GPU' => 'mrc-bsu-tesla',
         'CWALLACE-SL2-CPU' => 'skylake',
         'CWALLACE-SL3-CPU' => 'skylake',
         'TODD-SL3-CPU' => 'skylake',
         'MRC-BSU-SL3-CPU' => 'skylake',
         # 'CWALLACE-SL3' => 'skylake',
         # 'MRC-BSU-SL3' => 'skylake',
         'CWALLACE-SL2' => 'sandybridge',
         # 'CWALLACE-SL3' => 'sandybridge',
         # 'MRC-BSU-SL3' => 'sandybridge',
       }

class Qsub
  def initialize(file="runme.sh", opts = {})
    defaults={:job=>'rubyjob',:account=>ACCOUNT.upcase,:nodes=>'1',:tasks=>'16',:time=>TIME,:mail=>'FAIL,TIME_LIMIT',
              :p=>HOSTS[ACCOUNT.upcase],
              #:p=>ENV["SLURMHOST"],
              :excl=>" ",:autorun=>false,:array=>''}
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
    @counter_outer=0
    @counter_inner=0
    @jobfile=File.open(jobfile_name(),"w")
    @mem= (63900/ (@tasks.to_i) ).floor
    @autorun=opts[:autorun] || defaults[:autorun]
    @array=opts[:array] || defaults[:array]
    ## tesla is special
    if @account.eql?('tesla') then
      @account = "MRC-BSU-SL2-GPU"
    end
    if @account.eql?('MRC-BSU-SL2-GPU')  && @cpus.eql?('16') then
      @cpus='12'
    end
    if @account.eql?('MRC-BSU-SL2-GPU')  && @tasks.eql?('16') then
      @tasks='12'
    end
    ## check
    if(@account.nil?)
      raise "environment variable SLURMACCOUNT not set"      
    end
    # @p=opts[:p] || defaults[:p]
    @p=HOSTS[ @account.upcase ]
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
    qroot = '~/scratch/Q'
    comm = 'srun'
    if @p.eql?('skylake') then
      qroot = '~/rds/hpc-work/Q'
      comm = 'mpirun'
    end
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
      @file.puts("sbatch -o #{qroot}/slurm-%j.out " + jobfile_name())
      init_job()
    end
    @jobfile.puts 'echo "running" ' + command + "\n"
    @jobfile.puts comm  + #@excl +
                  ' ' + command + " &\n"
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

    if @array!=''
      @jobfile.puts "#SBATCH --array=#{@array}"
      @jobfile.puts "#SBATCH --output=#{@job}-%A_%a.out"
    else
      @jobfile.puts "#SBATCH --output=#{@job}-%A.out"
    end
    if @p.eql?('skylake') then
      @jobfile.puts(TAIL_CDS3)
    else
      @jobfile.puts(TAIL_CONST)
    end
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
  if ACCOUNT.eql?('CWALLACE-SL2-CPU') then
    qroot = "/rds/user/cew54/hpc-work/Q"
    comm = 'mpirun'
  else
    qroot = "~/scratch/Q"
    comm = 'srun -n1'
  end
  q=Qsub.new("#{qroot}/#{filestub}.sh",args)
  q.add("#{command} > #{qroot}/#{filestub}.out 2>&1")
  q.close()
end
