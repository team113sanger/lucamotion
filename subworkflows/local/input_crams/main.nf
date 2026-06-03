#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

workflow INPUT_MANIFEST {
    take:
    input_manifest

    main:
    Channel
        .fromPath(input_manifest, checkIfExists: true)
        .splitText()
        .filter { line -> line && !line.toLowerCase().startsWith('filepath') && !line.toLowerCase().startsWith('file') }
        .map { line ->
            def fields = line.trim().split(/[,\t]/)
            if (fields.size() < 1) {
                error "Invalid input manifest row: ${line}"
            }
            def alignment = fields[0]
            def index = fields.size() > 1 ? fields[1] : ''
            def sample_id = file(alignment).baseName
                .replaceFirst(/\.cram$/, '')
                .replaceFirst(/\.bam$/, '')
            tuple([id: sample_id], file(alignment, checkIfExists: true), index)
        }
        .set { input_alignments_ch }

    emit:
    input_alignments = input_alignments_ch
}
