Reference genome and annotation can be downloaded using the following links:
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/263/795/GCF_002263795.3_ARS-UCD2.0/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/263/795/GCF_002263795.3_ARS-UCD2.0/GCF_002263795.3_ARS-UCD2.0_genomic.gff.gz
Make sure they are downloaded in the following location:
Bovine-Assembly-Pipeline/resources/genomes/
Other references can be used, but make sure to update their location/name in the config file.

Pipeline can be run from the workflow directory using the following command:
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


If the optional genome annotation is used, be mindful to select your own data in the config file.
If no RNA-Seq is available, it is recommended to use the data associated with the ARS-UCD2.0 genome assembly.
Which can be downloaded using the following links:
https://trace.ncbi.nlm.nih.gov/Traces/?view=run_browser&acc=SRR5363147&display=download (RNA-Seq).
The RNA-Seq data can be downloaded and used locally, but if it is found in the SRA (NCBI) databases, it can be used directly without downloading.
The SRA_ID for the RNA-Seq of ARS-UCD2.0 is provided in the workflow, so if you use your own data please adjust the workflow file accordingly.


For protein hints an own database can be used, but OrthoDB is recommended. There are several clades available, recommended is to use vertebrata:
https://bioinf.uni-greifswald.de/bioinf/partitioned_odb12/Vertebrata.fa.gz.
