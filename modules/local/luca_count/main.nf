#!/usr/bin/env nextflow
nextflow.enable.types = true

process LUCA_COUNT {
    tag "${meta.id}"
    label 'process_medium'

    // Closure form is required under typed syntax so `meta` is resolved per-task.
    // Files are renamed with an `<id>.` prefix in the script (so downstream staging
    // sees unique names); saveAs strips that prefix to publish under original names.
    publishDir(
        path: { "${params.outdir}/guide_count_${meta.id}" },
        mode: params.publish_dir_mode,
        saveAs: { fn -> fn.startsWith("${meta.id}.") ? fn.substring("${meta.id}.".length()) : fn }
    )

    input:
    tuple(meta: Map, alignment: Path, index_file: Path)
    reference_genome: Path
    experiment_file: Path
    lib_dir: Path

    output:
    counts: Tuple<Map,Path> = tuple(meta, file('*.tsv'))
    configs: Tuple<Map,Path> = tuple(meta, file('*.json'))
    combination_counts: Tuple<Map,Path> = tuple(meta, file("${meta.id}.combination.0.counts.tsv", optional: true))

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

    for f in *.tsv *.json; do
        [ -e "\$f" ] || continue
        case "\$f" in
            ${meta.id}.*) ;;
            *) mv "\$f" "${meta.id}.\$f" ;;
        esac
    done
    """
}
