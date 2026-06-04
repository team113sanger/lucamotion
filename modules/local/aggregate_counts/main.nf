#!/usr/bin/env nextflow
nextflow.enable.types = true

process AGGREGATE_COUNTS {
    tag "aggregate_counts"
    label 'process_low'

    publishDir "${params.outdir}/aggregated_counts", mode: params.publish_dir_mode

    input:
    ids: List<String>
    files: List<Path>

    output:
    matrix: Path = file('combination_matrix.tsv')
    metadata: Path = file('combination_metadata.tsv')

    script:
    // Pair each id with its staged file's basename (files are staged into the work
    // dir, so they are opened by name rather than by an absolute upstream path).
    def entries = [ids, files.collect { f -> f.name }].transpose()
    def entries_json = groovy.json.JsonOutput.toJson(entries)
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
