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

``` bash
 SLURMACCOUNT="testaccount" SLURMHOST="testhost" ./qlines.rb testf.txt
```
