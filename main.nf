#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process CRISPR_LIBRARY_MATCHING {
    container 'crisprlibmatching:latest'
    publishDir "${params.outdir}", mode: "copy"
    input: 
    tuple val(meta), path(cram), path(crai)
    path(reference_genome)
    path(experiment_file)
    path(lib_dir)

    output: 
    path ("*.tsv"), emit: counts 

    script: 
    """
    crispr-lib-matching \
    -l $lib_dir \
    $experiment_file \
    $cram \
    -r $reference_genome \
    -o . \
    --count-mm-reads
    """

}

workflow {
    experiment =  file(params.experiment_file, checkIfExists: true)
    libraries = file(params.library_file_directory, checkIfExists:true)
    reference_genome = file(params.reference_genome, checkIfExists: true)
    
    Channel.fromPath(params.samples, checkIfExists: true)
    | map { file -> 
            index = file + ".crai"
            tuple(file, index)}
    | map { file, index ->
        tuple(file.baseName.replace(".cram", ""), file, index)}
    | set { indexed_crams } 

    CRISPR_LIBRARY_MATCHING(indexed_crams, 
                            reference_genome, 
                            experiment,
                            libraries)
                            
}