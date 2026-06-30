#!/usr/bin/env nextflow
nextflow.enable.types = true

workflow INPUT_MANIFEST {
    take:
    input_manifest: Path

    main:
    samples = channel.of(input_manifest)
        .splitCsv(header: true)
        .map { row ->
            if (!row.sample_id || !row.file) {
                error "Invalid input manifest row: ${row}"
            }
            tuple(
                [id: row.sample_id],
                file(row.file, checkIfExists: true),
                row.index ?: ''
            )
        }

    emit:
    samples
}
