#!/bin/bash

#SBATCH --job-name shuffled_pagerank
#SBATCH -p shas
#SBATCH --time 24:00:00
#SBATCH --mem=16G
#SBATCH -o /scratch/summit/benheil@xsede.org/logs/shuffled_pagerank-%j.out

module purge
eval "$(conda shell.bash hook)"

conda activate indices

if [ "$#" -eq 0 ] 
then
    echo "At least one argument required, $# provided"
    exit 1
fi

echo "$@"

python indices/run_metric_on_graph.py --metric pagerank --out_dir /scratch/summit/benheil@xsede.org/indices/output/shuffle_results "$@" \
