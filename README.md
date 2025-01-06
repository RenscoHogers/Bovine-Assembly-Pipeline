Reference genome and annotation can be downloaded using the following links:
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/263/795/GCF_002263795.3_ARS-UCD2.0/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/263/795/GCF_002263795.3_ARS-UCD2.0/GCF_002263795.3_ARS-UCD2.0_genomic.gff.gz
Make sure they are downloaded in the following location:
Bovine-Assembly-Pipeline/resources/genomes/
Other references can be used, but make sure to update their location/name in the config file.

Pipeline can be run from the main directory using the following command:
snakemake --profile myprofile
Profiles are found in the following directory on your device:
~/.config/snakemake/

Example of profile:
cluster:
  mkdir -p ../logs/{rule} &&
  sbatch
    --cpus-per-task={threads}
    --mem={resources.mem_mb}
    --time={resources.time}
    --job-name={rule}-{wildcards}
    --output=../logs/{rule}/{rule}-%j.out
    --partition={resources.partition}
    --gpus={resources.gpus}
default-resources:
  - partition=main
  - mem_mb=1000
  - time="1-00:00:00"
  - gpus=0
restart-times: 3
max-jobs-per-second: 1
max-status-checks-per-second: 1
local-cores: 1
latency-wait: 60
jobs: 10
keep-going: False
rerun-incomplete: True
printshellcmds: True

use-conda: true
conda-frontend: mamba
use-singularity: true
singularity-args: "--bind /lustre/nobackup/WUR/ABGC/"
