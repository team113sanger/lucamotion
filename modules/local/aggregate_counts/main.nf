#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process AGGREGATE_COUNTS {
    tag "aggregate_counts"
    label 'process_low'

    publishDir "${params.outdir}/aggregated_counts", mode: params.publish_dir_mode

    input:
    val(count_entries)

    output:
    path("combination_matrix.tsv"), emit: matrix
    path("combination_metadata.tsv"), emit: metadata

    when:
    task.ext.when == null || task.ext.when

    script:
    def entries_json = groovy.json.JsonOutput.toJson(count_entries)
    """
    python3 - <<'PY'
    import csv
    import json
    from collections import defaultdict

    counts_files = json.loads('''${entries_json}''')
    matrix = defaultdict(dict)
    sample_ids = []

    for sample_id, source_file in counts_files:
        sample_ids.append(sample_id)
        with open(source_file) as f:
            reader = csv.reader(f, delimiter='\\t')
            for row in reader:
                if len(row) < 3:
                    continue
                key = f"{row[0]}|{row[1]}"
                matrix[key][sample_id] = row[2]

    with open('combination_matrix.tsv', 'w', newline='') as out:
        writer = csv.writer(out, delimiter='\\t')
        writer.writerow(['combination_id'] + sample_ids)
        for combo in sorted(matrix):
            writer.writerow([combo] + [matrix[combo].get(s, '0') for s in sample_ids])

    with open('combination_metadata.tsv', 'w', newline='') as out:
        writer = csv.writer(out, delimiter='\\t')
        writer.writerow(['sample_id', 'source_file'])
        for sample_id, source_file in counts_files:
            writer.writerow([sample_id, source_file])
    PY
    """
}
