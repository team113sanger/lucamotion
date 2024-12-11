# toy-crispr-pipeline
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.04.5-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

This is a simple bioinfromatics pipeline written in [Nextflow](http://www.nextflow.io) for mutliplexed crispr counting using [LUCA]((https://gitlab.internal.sanger.ac.uk/casm/crispr/crispr-lib-matching)) – CASM-IT's latest generation CRISPR-tool.

## Pipeline summary

In brief, the pipeline takes a set CRAM files containing CRISPR reads (alongside their indexes) a set of CRISPR library files containing guide sequences, and an experiment file and generates counts for each of the guides in the CRISPR library file.

## Inputs 
`samples`: Path to a set of CRAM files (`path/**.cram`)
`reference_genome`: Path to the reference genome used in generating CRAM files
`experiment_file`: Path to a CRISPR-lib-matching experiment file `.yaml`. See [LUCA](https://gitlab.internal.sanger.ac.uk/casm/crispr/crispr-lib-matching) for a more thorough explanation.
`library_file_directory`: Path to a directory containing the guide sequence files used in a screen
`outdir`: Path to output results.

## Usage 

The recommended way to launch this pipeline is using a wrapper script (e.g. `bsub < my_wrapper.sh`) that submits nextflow as a job and records the version (**e.g.** `-r 0.0.2`)  and the `.json` parameter file supplied for a run.

An example wrapper script:
```
#!/bin/bash
#BSUB -q oversubscribed
#BSUB -G team113
#BSUB -R "select[mem>2000] rusage[mem=2000] span[hosts=1]"
#BSUB -M 2000
#BSUB -oo nf_out.o
#BSUB -eo nf_out.e

PARAMS_FILE="/lustre/scratch125/casm/team113da/users/jb63/tests/testdata/example_params.json"

# Load module dependencies
module load nextflow-23.10.0
module load /software/modules/ISG/singularity/3.11.4

# Create a nextflow job that will spawn other jobs

nextflow run 'https://gitlab.internal.sanger.ac.uk/team113sanger/team113_crispr/toy-crispr-pipeline' \
-r 0.0.2 \
-params-file $PARAMS_FILE \
-profile farm22 
```

The pipeline can configured to run on either Sanger OpenStack secure-lustre instances or farm22 by changing the profile speicified:
`-profile secure_lustre` or `-profile farm22`. 

## Testing

This pipeline has been developed with the [nf-test](http://nf-test.com) testing framework. Unit tests and small test data are provided within the pipeline `test` subdirectory. A snapshot has been taken of the outputs of most steps in the pipeline to help detect regressions when editing. You can run all tests on openstack with:

```
nf-test test 
```
and individual tests with:
```
nf-test test tests/modules/ascat_exomes.nf.test
```

For faster testing of the flow of data through the pipeline **without running any of the tools involved**, stubs have been provided to mock the results of each succesful step.
```
nextflow run main.nf \
-params-file params.json \
-c tests/nextflow.config \
--stub-run
```

