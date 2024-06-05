#!/bin/bash

f1="${snakemake_input[forward_short_reads]}"
f2="${snakemake_input[reverse_short_reads]}"
threads="${snakemake_resources[0]}"
outdir="${snakemake_output[0]}"

# Check if both input files exist
if [ ! -f "$f1" ] || [ ! -f "$f2" ]; then
  echo "Error: One or both input files do not exist."
  exit 1
fi

mkdir -p "$outdir"
# Check if the output directory exists
if [ ! -d "$outdir" ]; then
  echo "Error: Output directory '$outdir' does not exist."
  exit 1
fi

cd "$outdir"
# Ensure we're in the right directory
if [ "$(pwd)" != "$outdir" ]; then
  echo "Could not change to output directory '$outdir'"
  exit 1
fi

# Extract the filename without the directory path
filename=$(basename "$f1")

# Extract the extension
extension="${filename##*_1}"

# Replace _1.f*q* with _2 and append the original extension
f2="${f1%%1.f*q*}2$extension"

# Remove directory names and add fastq.gz as extensions for output files.
f1_out="${f1##*/}"; f1_out="${f1_out%%.*}.fastq.gz"
f2_out="${f2##*/}"; f2_out="${f2_out%%.*}.fastq.gz"

# Trim adapter sequences and filter by quality
trimmomatic PE -threads "$threads" -phred33 "$f1" "$f2" \
"forward_paired_${f1_out}" "forward_unpaired_${f1_out}" \
"reverse_paired_${f2_out}" "reverse_unpaired_${f2_out}" \
ILLUMINACLIP:../../resources/trimmomatic/TruSeq3-PE.fa:2:30:10 \
LEADING:20 TRAILING:20 SLIDINGWINDOW:6:28 MINLEN:50

# Check if Trimmomatic ran successfully
if [ $? -ne 0 ]; then
    echo "Error: Trimmomatic failed for pair ($f1, $f2)"
fi
