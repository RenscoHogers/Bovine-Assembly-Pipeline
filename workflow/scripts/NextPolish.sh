#!/bin/bash

long_reads="${snakemake_input[0]}"
short_reads_directory="${snakemake_input[1]}"
input="${snakemake_input[2]}/assembly.fasta"
outdir="$(dirname "${snakemake_output[0]}")"

# Set general input and parameters.
round_count=2
threads="${snakemake_resources[0]}"
mem_gb="$((snakemake_resources[2] / threads / 1000))";
nextpolish_install_dir="$(dirname "$(dirname "$(realpath -s "$(command -v nextPolish)")")")"
long_read_type="ont"

# Define long-read mapping options.
declare -A -r LONG_READ_MAPPING_OPTIONS=(
    [clr]="map-pb"
    [hifi]="asm20"
    [ont]="map-ont"
)

# Check if commands exist before using them.
if ! command -v minimap2 &>/dev/null || ! command -v samtools &>/dev/null || ! command -v bwa-mem2 &>/dev/null; then
    echo "One or more required commands not found. Exiting..."
    exit 1
fi

# Function to clean up temporary files.
cleanup() {
  rm -f "${outdir}"/sgs*.fa* "${outdir}"/*.sam* "${outdir}"/*.bam* "${outdir}"/*.fofn "${outdir}"/genome.nextpolish_short-read_tmp.fa* "${outdir}"/genome.nextpolish_long-read*.fa* "${outdir}"/*.fai;
}

# Run long-read polishing.
for ((round=1; round<="${round_count}";round++)); do
    echo "Long-read polishing round ${round} of ${round_count}";

    # Map long-reads against assembly.
    minimap2 -ax "${LONG_READ_MAPPING_OPTIONS[$long_read_type]}" -t "${threads}" -o "${outdir}/lgs.sam" --sam-hit-only -2 "${input}" "${long_reads}";

    # Sort the sam file and transform it into a .bam file.
    samtools sort -m "${mem_gb}"g --threads "${threads}" -O BAM -o "${outdir}/lgs.sorted.bam" "${outdir}/lgs.sam";

    # Index the .bam file.
    samtools index "${outdir}/lgs.sorted.bam";

    # Create .fofn file with the .bam file, as is needed for NextPolish.
    ls "${outdir}/lgs.sorted.bam" > "${outdir}/lgs.fofn";

    # Run NextPolish.
    python "${nextpolish_install_dir}/share/nextpolish-1.4.1/lib/nextpolish2.py" -g "${input}" -l "${outdir}/lgs.fofn" -r "${long_read_type}" -p "${threads}" -sp -o "${outdir}/genome.nextpolish_long-read.fa";

    # Set input for next round of for short-read polishing.
    if [[ round -ne "${round_count}" ]]; then
        mv "${outdir}/genome.nextpolish_long-read.fa" "${outdir}/genome.nextpolish_long-read_tmp.fa";
        input="${outdir}/genome.nextpolish_long-read_tmp.fa"
    elif [[ round -eq "${round_count}" ]]; then
        input="${outdir}/genome.nextpolish_long-read.fa"
    fi;

    rm "${outdir}"/*.sam* "${outdir}"/*.bam* "${outdir}"/*.fofn
done;

# Set short-read polishing input and parameters.
short_read_list1=($(find "${short_reads_directory}" -name 'forward_paired_temp_short_reads_1.fastq.gz'))
# Form the corresponding second read file names by replacing forward suffix with reverse and changing the suffix.
short_read_list2=($(find "${short_reads_directory}" -name 'reverse_paired_temp_short_reads_2.fastq.gz'))

# Run short-read polishing.
for ((round=1; round<="${round_count}";round++)); do
    for step in $(seq 1 2); do
        echo "Short-read polishing round ${round} of ${round_count}, step ${step} of 2";

        # Index the genome file and do alignment.
        bwa-mem2 index "${input}";
        bwa-mem2 mem -t "${threads}" "${input}" "${short_read_list1}" "${short_read_list2}" > "${outdir}/sgs.sam";
        samtools view --threads "${threads}" -F 0x4 -b -o "${outdir}/sgs.bam" "${outdir}/sgs.sam";
        samtools fixmate -m --threads "${threads}" -O bam "${outdir}/sgs.bam" "${outdir}/sgs_fixmate.bam";
        samtools sort -m "${mem_gb}g" --threads "${threads}" -O BAM -o "${outdir}/sgs.sorted.bam" "${outdir}/sgs_fixmate.bam";
        samtools markdup --threads "${threads}" -r "${outdir}/sgs.sorted.bam" "${outdir}/sgs.sorted.markdup.bam";
        # Index bam and genome files.
        samtools index -@ "${threads}" "${outdir}/sgs.sorted.markdup.bam";
        samtools faidx "${input}";
        # Polish genome file.
        python "${nextpolish_install_dir}/share/nextpolish-1.4.1/lib/nextpolish1.py" -g "${input}" -t "${step}" -p "${threads}" -s "${outdir}/sgs.sorted.markdup.bam" -o "${outdir}/genome.nextpolish.fa";
        if [[ round -eq "${round_count}" && step -eq 2 ]]; then
            input="${outdir}/genome.nextpolish.fa"
        else
            mv "${outdir}/genome.nextpolish.fa" "${outdir}/genome.nextpolish_short-read_tmp.fa";
            input="${outdir}/genome.nextpolish_short-read_tmp.fa"
        fi;

        rm "${outdir}"/*.sam* "${outdir}"/*.bam* "${outdir}"/*.fai
    done
done

# Bgzip the final output file.
bgzip -@ "${threads}" "${input}" > "${input}.gz"

# Remove intermediate files.
cleanup
