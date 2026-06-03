#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { INPUT_MANIFEST } from './subworkflows/local/input_crams/main'
include { GUIDE_COUNTING } from './subworkflows/local/guide_counting/main'
include { AGGREGATE_COUNTS } from './modules/local/aggregate_counts/main'

workflow CRISPR_PIPELINE {
    main:
    def manifest_path = params.input_manifest ?: params.samples
    if (!manifest_path) {
        error "Provide either --input_manifest or --samples"
    }

    INPUT_MANIFEST(manifest_path)
    guide_input_ch = INPUT_MANIFEST.out.input_alignments

    GUIDE_COUNTING(
        guide_input_ch,
        file(params.reference_genome, checkIfExists: true),
        file(params.experiment_file, checkIfExists: true),
        file(params.library_file_directory, checkIfExists: true)
    )

    if (params.run_aggregate_counts) {
        GUIDE_COUNTING.out.combination_counts
            .map { meta, counts_tsv -> [meta.id as String, counts_tsv.toString()] }
            .collect()
            .set { counts_for_aggregation }

        AGGREGATE_COUNTS(counts_for_aggregation)
    }

    emit:
    counts = GUIDE_COUNTING.out.counts
    configs = GUIDE_COUNTING.out.configs
    combination_counts = GUIDE_COUNTING.out.combination_counts
    aggregate_matrix = params.run_aggregate_counts ? AGGREGATE_COUNTS.out.matrix : Channel.empty()
    aggregate_metadata = params.run_aggregate_counts ? AGGREGATE_COUNTS.out.metadata : Channel.empty()
}

workflow {
    CRISPR_PIPELINE()
}
