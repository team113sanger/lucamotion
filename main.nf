#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process CRISPR_LIBRARY_MATCHING {
    publishDir "${params.outdir}/${meta.id}", mode: "copy"
    label 'process_medium'


    input: 
    tuple val(meta), path(cram), path(crai)
    path(reference_genome)
    path(experiment_file)
    path(lib_dir)

    output: 
    tuple val(meta), path ("*.tsv"), emit: counts 
    tuple val(meta), path ("*.json"), emit: config 

    script: 
    """
    luca count \
    --library-dir $lib_dir \
    $experiment_file \
    $cram \
    --reference $reference_genome \
    --output . \
    --count-mm-reads \
    --cpus 0
    """

}

workflow {
    
    experiment =  file(params.experiment_file, checkIfExists: true)
    libraries = file(params.library_file_directory, checkIfExists:true)
    reference_genome = file(params.reference_genome, checkIfExists: true)
    
    // Add index files to crams as a tuple
    Channel.fromPath(params.samples, checkIfExists: true)
    | map { file -> 
            index = file + ".crai"
            tuple(file, index)}
    | map { file, index ->
        tuple([id: file.baseName.replace(".cram", "")], file, index)}
    | set { indexed_crams } 

    CRISPR_LIBRARY_MATCHING(indexed_crams, 
                            reference_genome, 
                            experiment,
                            libraries)
                            
}

