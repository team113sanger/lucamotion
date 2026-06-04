#!/usr/bin/env nextflow
nextflow.enable.types = true

include { INPUT_MANIFEST } from './subworkflows/local/input_crams/main'
include { GUIDE_COUNTING } from './subworkflows/local/guide_counting/main'
include { AGGREGATE_COUNTS } from './modules/local/aggregate_counts/main'

workflow CRISPR_PIPELINE {
    main:
    def manifest_path = file(params.input_manifest, checkIfExists: true)

    INPUT_MANIFEST(manifest_path)
    def guide_input_ch = INPUT_MANIFEST.out

    GUIDE_COUNTING(
        guide_input_ch,
        file(params.reference_genome, checkIfExists: true),
        file(params.experiment_file, checkIfExists: true),
        file(params.library_file_directory, checkIfExists: true)
    )

    if (params.run_aggregate_counts) {
        // Collect all (id, counts file) pairs into a single list, then split into two
        // aligned lists. Files are kept as Path (not String) so Nextflow stages them
        // into the AGGREGATE_COUNTS work dir — required for cluster/cloud executors.
        def counts_for_aggregation = GUIDE_COUNTING.out.combination_counts
            .map { meta, counts_tsv -> [meta.id as String, counts_tsv] }
            .toList()
            .multiMap { rows ->
                ids:   rows.collect { row -> row[0] }
                files: rows.collect { row -> row[1] }
            }

        AGGREGATE_COUNTS(counts_for_aggregation.ids, counts_for_aggregation.files)
    }

    emit:
    counts: Channel<Tuple<Map,Path>> = GUIDE_COUNTING.out.counts
    configs: Channel<Tuple<Map,Path>> = GUIDE_COUNTING.out.configs
    combination_counts: Channel<Tuple<Map,Path>> = GUIDE_COUNTING.out.combination_counts
    aggregate_matrix = params.run_aggregate_counts ? AGGREGATE_COUNTS.out.matrix : channel.empty()
    aggregate_metadata = params.run_aggregate_counts ? AGGREGATE_COUNTS.out.metadata : channel.empty()
}

workflow {
    CRISPR_PIPELINE()
}
