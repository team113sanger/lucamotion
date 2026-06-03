#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process LUCA_COUNT {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/guide_count_${meta.id}", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(alignment), val(index_file)
    path(reference_genome)
    path(experiment_file)
    path(lib_dir)

    output:
    tuple val(meta), path("*.tsv"), emit: counts
    tuple val(meta), path("*.json"), emit: configs
    tuple val(meta), path("combination.0.counts.tsv"), optional: true, emit: combination_counts

    when:
    task.ext.when == null || task.ext.when

    script:
    def mm_reads_arg = params.luca_count_mm_reads ? '--count-mm-reads' : ''
    def sort_mm_arg = params.luca_sort_mm_read_counts ? '--sort-mm-read-counts' : ''
    def extra_args = params.luca_extra_args ?: ''
    def is_cram = alignment.name.toLowerCase().endsWith('.cram')
    def reference_arg = is_cram ? "--reference ${reference_genome}" : ''
    """
    luca count \
      --library-dir ${lib_dir} \
      ${reference_arg} \
      --output . \
      ${mm_reads_arg} \
      ${sort_mm_arg} \
      --cpus ${task.cpus} \
      ${extra_args} \
      ${experiment_file} \
      ${alignment}
    """
}
