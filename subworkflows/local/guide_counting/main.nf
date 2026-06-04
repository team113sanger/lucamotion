#!/usr/bin/env nextflow
nextflow.enable.types = true

include { LUCA_COUNT } from '../../../modules/local/luca_count/main'

workflow GUIDE_COUNTING {
    take:
    input_alignments: Channel<Tuple<Map,Path,String>>
    reference_genome: Path
    experiment_file: Path
    library_dir: Path

    main:
    LUCA_COUNT(input_alignments, reference_genome, experiment_file, library_dir)

    emit:
    counts: Channel<Tuple<Map,Path>> = LUCA_COUNT.out.counts
    configs: Channel<Tuple<Map,Path>> = LUCA_COUNT.out.configs
    combination_counts: Channel<Tuple<Map,Path>> = LUCA_COUNT.out.combination_counts
}
