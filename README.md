# slurmer
Interact with slurm on darwin

## qlines.rb -h

```
Usage:
qlines.rb [-a account] [-t time] [-h] file

-a account
   If not supplied, account will be found from the environment variable SLURMACCOUNT
-t time
   format hh:mm:ss
   default is 01:00:00 (1 hour)
-x 
   by default, this script assumes you want one CPU per line.  If you want to 
   parallelise within your job and want one node per line, use the -x flag to 
   use the --exclusive option for srun
-h
   print this message and exit

file should contain commands to be run on the queue, one line per command, no extraneous text
```

## qR.rb
```
qlines.rb [-a account] [-t time] [-h] Rscript [Rscript args]

-a account
   If not supplied, account will be found from the environment variable SLURMACCOUNT
-t time
   format hh:mm:ss
   default is 01:00:00 (1 hour)
-h
   print this message and exit

Rscript will be run on the queue (`R CMD BATCH Rscript [Rscript args]`), with 16 cores booked, so using parallelisation with 16 cores within the script is recommended.
```

## Test

Can we submit a job and produce output.  This will produce a file =testf.txt= with 32 commands, each of which will echo a numbered line and datestamp to test.out and sleep.  If sequentially run, the numbers will be consecutive (1/17 .. 2/18 ...) and the date stamps will be 2 seconds apart.  Otherwise, if run in parallel, they will be all over the place, because run simultaneously.

Code assumes environment variables =SLURMACCOUNT= and =SLURMHOST= are set.

Parallel
``` bash
[ -e test.out ] && rm test.out
[ -e testf.txt ] && rm testf.txt
for i in `seq 1 32`; do
echo "echo run$i \`date\` >> test.out && sleep 2" >> testf.txt
done
d=`date +%Y%m%d`
./qlines.rb testf.txt
bash -l slurm-lines-$d.sh
# wait until complete
cat test.out
```

Sequential
``` bash
[ -e test.out ] && rm test.out
[ -e testf.txt ] && rm testf.txt
for i in `seq 1 32`; do
echo "echo run$i \`date\` >> test.out && sleep 2" >> testf.txt
done
d=`date +%Y%m%d`
./qlines.rb -x testf.txt
bash -l slurm-lines-$d.sh
# wait until complete
cat test.out
```

