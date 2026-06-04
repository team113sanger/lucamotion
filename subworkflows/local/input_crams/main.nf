#!/usr/bin/env nextflow
nextflow.enable.types = true

workflow INPUT_MANIFEST {
    take:
    input_manifest: Path

    emit:
    channel
        .of(input_manifest)
        .splitText()
        .filter { line -> line && !line.toLowerCase().startsWith('filepath') && !line.toLowerCase().startsWith('file') }
        .map { line ->
            def fields = line.trim().split(/[,\t]/)
            if (fields.size() < 1) {
                error "Invalid input manifest row: ${line}"
            }
            def sample_id = fields[0]
            def alignment = fields[1]
            def index = fields.size() > 2 ? fields[2] : ''

            tuple([id: sample_id], file(alignment, checkIfExists: true), index)
        }
}
