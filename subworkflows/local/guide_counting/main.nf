#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { LUCA_COUNT } from '../../../modules/local/luca_count/main'

workflow GUIDE_COUNTING {
    take:
    input_alignments
    reference_genome
    experiment_file
    library_dir

    main:
    LUCA_COUNT(input_alignments, reference_genome, experiment_file, library_dir)

    emit:
    counts = LUCA_COUNT.out.counts
    configs = LUCA_COUNT.out.configs
    combination_counts = LUCA_COUNT.out.combination_counts
}
