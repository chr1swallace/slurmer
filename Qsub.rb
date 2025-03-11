
USER=ENV['USER']
# QDIR="/scratch/#{USER}/Q"
# load("/home/cew54/DIRS.txt")
HEADER_CONST='#!/bin/bash'

## removed these two lines, because machine.files are annoying and have not been useful yet.
#echo `cat machine.file.$JOBID | sed -e \'s/\..*$//g\'`

MODULES_ICELAKE='. /etc/profile.d/modules.sh # Leave this line (enables the module command)
module purge                # Removes all modules still loaded
module load rhel8/default-icl            # REQUIRED - loads the basic environment
. /home/cew54/.modules-ice'
MODULES_SKYLAKE='. /etc/profile.d/modules.sh # Leave this line (enables the module command)
module purge                # Removes all modules still loaded
module load rhel7/default-peta4            # REQUIRED - loads the basic environment
. /home/cew54/.modules-cds3'
MODULES_CCLAKE='. /etc/profile.d/modules.sh # Leave this line (enables the module command)
module purge                # Removes all modules still loaded
module load rhel7/default-ccl            # REQUIRED - loads the basic environment
. /home/cew54/.modules-cds3
#! Number of nodes and tasks per node allocated by SLURM (do not change):
numnodes=$SLURM_JOB_NUM_NODES
numtasks=$SLURM_NTASKS
mpi_tasks_per_node=$(echo "$SLURM_TASKS_PER_NODE" | sed -e  \'s/^\([0-9][0-9]*\).*$/\1/\')
#! Are you using OpenMP (NB this is unrelated to OpenMPI)? If so increase this
#! safe value to no more than 56:
export OMP_NUM_THREADS=1

#! Number of MPI tasks to be started by the application per node and in total (do not change):
np=$[${numnodes}*${mpi_tasks_per_node}]

#! The following variables define a sensible pinning strategy for Intel MPI tasks -
#! this should be suitable for both pure MPI and hybrid MPI/OpenMP jobs:
export I_MPI_PIN_DOMAIN=omp:compact # Domains are $OMP_NUM_THREADS cores in size
export I_MPI_PIN_ORDER=scatter # Adjacent domains have minimal sharing of caches/sockets
#! Notes:
#! 1. These variables influence Intel MPI only.
#! 2. Domains are non-overlapping sets of cores which map 1-1 to MPI tasks.
#! 3. I_MPI_PIN_PROCESSOR_LIST is ignored if I_MPI_PIN_DOMAIN is set.
#! 4. If MPI tasks perform better when sharing caches/sockets, try I_MPI_PIN_ORDER=compact.
'
TAIL='export I_MPI_PIN_ORDER=scatter # Adjacent domains have minimal sharing of caches/sockets

export PATH="/home/cew54/locali/bin:$PATH"
JOBID=$SLURM_JOB_ID
        echo $JOBID >> jobids
echo -e JobID: $JOBID
echo Time: `date`
echo Running on master node: `hostname`
echo `module list`
echo Current directory: `pwd`
echo PATH: $PATH
if [ "$SLURM_JOB_NODELIST" ]; then
        #! Create a machine file:
        export NODEFILE=`generate_pbs_nodefile`
        echo -e "\nNodes allocated:\n================"
        echo `cat $NODEFILE | uniq`
fi

'

## DEFAULTS
ACCOUNT=ENV["SLURMACCOUNT"]
TIME='01:00:00' # hh:mm:ss
HOSTS= {
    # 'MRC-BSU-SL2' => 'mrc-bsu-sand',
    # 'MRC-BSU-SL2-GPU' => 'mrc-bsu-tesla',
    # 'CWALLACE-SL2-CPU' => 'skylake,skylake-himem',
    'CWALLACE-SL2-CPU' => 'icelake',
    # 'CWALLACE-SL3-CPU' => 'skylake',
    # 'TODD-SL3-CPU' => 'skylake',
    # 'MRC-BSU-SL3-CPU' => 'skylake',
    # 'MRC-BSU-SL3-GPU' => 'pascal',
    # # 'MRC-BSU-SL2-CPU' => 'skylake,skylake-himem',
    'MRC-BSU-SL2-CPU' => 'cclake',
    'MRC-BSU-SL2-GPU' => 'pascal',
    # 'CWALLACE-SL3' => 'skylake',
    # 'MRC-BSU-SL3' => 'skylake',
    # 'CWALLACE-SL2' => 'sandybridge',
    # 'CWALLACE-SL3' => 'sandybridge',
    # 'MRC-BSU-SL3' => 'sandybridge',
}

class Qsub
    def defaults
        { :job=>'rubyjob',
            :account=>ACCOUNT.upcase,
            :nodes=>'1',
            :tasks=>'16',
            :cpus => '1',
            :time=>TIME,
            :mail=>'FAIL,TIME_LIMIT',
            # :p=>HOSTS[ACCOUNT.upcase], # never used, because we use @account to set
            :dependency=>'',
            :excl=>" ",
            :autorun=>false,
            :interactiverun=>false,
            :array=>'' }
    end

    def initialize(file="runme.sh", opts = {})
        p opts

        ## check and set host
        @account=opts[:account] || defaults[:account]
        raise "environment variable SLURMACCOUNT not set" if @account.nil?
        ## tesla is special
        @account = "MRC-BSU-SL2-GPU" if @account.eql?('tesla')
        if @account.eql?('MRC-BSU-SL2-GPU')  && @cpus.eql?('16') then
            @cpus='12'
            @tasks='12'
        end
        @p=opts[:p] || HOSTS[ @account.upcase ]
        raise "host not set" if @p.nil?

        @file_name=file
        @job=opts[:job] || defaults[:job]
        @excl=opts[:excl] || defaults[:excl]
        @nodes=(opts[:nodes] || defaults[:nodes]).to_s
        @tasks=(opts[:tasks] || defaults[:tasks]).to_s
        #    @cpus=(@tasks.to_i == 1 && opts[:p] == 'sandybridge' ? '16' : '1')
        @cpus=(opts[:cpus] || defaults[:cpus]).to_s #(16 / (@tasks.to_i))
        @time=opts[:time] || defaults[:time]
        @dependency=opts[:dependency] || defaults[:dependency]
        @mail=opts[:mail] || defaults[:mail]
        @counter_outer=0
        @counter_inner=0
        @file = File.open(file,"w") # will contain sbatch instruction
        @jobfile=File.open(jobfile_name(),"w") # the file called by sbatch
        @mem=@p.eql?('cclake') ? 3420 : (63900/ (@tasks.to_i) ).floor
        @autorun=opts[:autorun] || defaults[:autorun]
        @interactiverun=opts[:interactiverun] || defaults[:interactiverun]
        @array=opts[:array] || defaults[:array]
        @qroot = "/rds/user/cew54/hpc-work/Q"
        @comm = 'mpirun'
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
            @jobfile=File.open(jobfile_name(),"w") if @counter_outer > 0
            @file.puts("sbatch #{@dependency} -o #{@qroot}/%j.out " + jobfile_name())
            init_job()
        end
        @jobfile.puts 'echo "running ' + command + '"' + "\n"
        @jobfile.puts "#{@comm} #{command} &\n"
        @counter_inner += 1
    end

    def init_job()
        @jobfile.puts %{#{HEADER_CONST}
#SBATCH -J #{@job}
#SBATCH -A #{@account}
#SBATCH --nodes #{@nodes}
#SBATCH --ntasks #{@tasks}
#SBATCH --cpus-per-task #{@cpus}
#SBATCH --time #{@time}
#SBATCH --mail-type #{@mail}
#SBATCH -p #{@p}
}
        # '#SBATCH --mem ' + @mem.to_s
        if @array!=''
            @jobfile.puts "#SBATCH --array=#{@array}"
            @jobfile.puts "#SBATCH --output=#{@job}-%A_%a.out"
            # @jobfile.puts "#SBATCH --error=#{@job}-%A_%a.err"
        else
            @jobfile.puts "#SBATCH --output=#{@job}-%A.out"
            # @jobfile.puts "#SBATCH --error=#{@job}-%A.err"
        end
        if @p.eql?('cclake')
                @jobfile.puts MODULES_CCLAKE
        else
                @jobfile.puts MODULES_ICELAKE
        end
        @jobfile.puts TAIL
    end

    def close
        @jobfile.puts "wait\n"
        @jobfile.close()
        @file.close()
        if @interactiverun
            system("bash " + jobfile_name())
        elsif @autorun
            system("bash -l " + @file_name)
        else
            puts "now run"
            puts "bash -l " + @file_name
        end
    end
end

def qone(command,args,filestub)
    q=Qsub.new("#{filestub}.sh",args)
    q.add("#{command} > #{filestub}.out 2>&1")
    q.close()
end

def qarray(commands,args,filestub)
        q=Qsub.new("#{@qroot}/#{filestub}.sh",args)
        commands.each do |command|
                q.add("#{command} > #{@qroot}/#{filestub}.out 2>&1")
        end
        q.close()
end

def qwait(str)
        n=`squeue -u cew54 -n #{str} --noheader | wc -l`.to_i
        while n > 0 do
                sleep 600
                n=`squeue -u cew54 -n #{str} --noheader | wc -l`
        end
end
