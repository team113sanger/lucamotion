#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process CRISPR_LIBRARY_MATCHING {
    publishDir "${params.outdir}", mode: "copy"
    input: 
    tuple val(meta), path(cram), path(crai)
    path(reference_genome)
    path(lib_dir)
    path(experiment_file)

    output: 
    path ("*.tsv"), emit: counts 

    script: 
    """
    crispr-lib-matching \
    -s $cram \
    -l $lib_dir
    -r $reference_genome
    --count-mm-reads  
    """

}

workflow {
    reference_genome =  file(params.reference_genome, checkIfExists: true)
    experiment =  file(params.experiment_file, checkIfExists: true)
    libraries = file(params.library_file_directory, checkIfExists:true)
    Channel.fromPath(params.samples, checkIfExists: true)
    | map { file -> 
            index = file + ".crai"
            tuple(file, index)}
    | map { file, index ->
        tuple(file.baseName.replace(".cram", ""), file, index)}
    | set { indexed_crams } 



    CRISPR_LIBRARY_MATCHING(indexed_crams, 
                            reference_genome, 
                            experiment
                            libraries)
                            
}