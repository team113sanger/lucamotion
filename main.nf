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
        // Each sample emits a list of <id>.combination.<N>.counts.tsv files. Regroup them
        // *by combination index N* so that combination N from every sample is aggregated
        // into a single matrix: flatten one file per item, parse N from the filename, then
        // groupTuple by N. Files are kept as Path (not String) so Nextflow stages them into
        // the AGGREGATE_COUNTS work dir — required for cluster/cloud executors.
        def counts_by_combination = GUIDE_COUNTING.out.combination_counts
            .flatMap { meta, counts_files ->
                counts_files.collect { counts_tsv ->
                    def index = (counts_tsv.name =~ /\.combination\.(\d+)\.counts\.tsv$/)[0][1] as Integer
                    tuple(index, meta.id as String, counts_tsv)
                }
            }
            .groupTuple()

        AGGREGATE_COUNTS(counts_by_combination)
    }

    emit:
    counts: Channel<Tuple<Map,List<Path>>> = GUIDE_COUNTING.out.counts
    configs: Channel<Tuple<Map,List<Path>>> = GUIDE_COUNTING.out.configs
    combination_counts: Channel<Tuple<Map,List<Path>>> = GUIDE_COUNTING.out.combination_counts
    aggregate_matrix = params.run_aggregate_counts ? AGGREGATE_COUNTS.out.matrix : channel.empty()
    aggregate_metadata = params.run_aggregate_counts ? AGGREGATE_COUNTS.out.metadata : channel.empty()
}

workflow {
    CRISPR_PIPELINE()
}
