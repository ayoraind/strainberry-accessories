## Pre-assembly QC workflow.
### Usage

```

=======================================================================
  POST-ASSEMBLY QC: TAPIR Pipeline version 1.0dev
=======================================================================
 The typical command for running the pipeline is as follows:
        nextflow run main.nf --assemblies "PathToReadFile(s)" --reference_file "PathtoCSVFile" --output_dir "PathToOutputDir"  

        Mandatory arguments:
         --assemblies                   FASTA file to be mapped against references (e.g., "/MIGE/01_DATA/03_ASSEMBLY/T055-8-*_FLYE/T055-8-*.fastq.gz")
         --reference_file               A headerless comma-separated (csv) containing ref_id in the first column and ref_fasta_path in the second column
         --output_dir                   Output directory to place output (e.g., "/MIGE/04_PROJECTS/STRAIN_RESOLUTION")

         
        Optional arguments:
         --help                         This usage statement.
         --version                      Version statement

```


## Introduction
This pipeline generates post-assembly QC information. A large percentage of this pipeline was adapted from the [Strainberry github page](https://github.com/rvicedomini/strainberry) and the [Strainberry analysis page](https://github.com/rvicedomini/strainberry-analyses/tree/main). 


## Sample command
An example of a command to run this pipeline is:

```
nextflow run main.nf --reads "Sample_files/*.fasta" --reference_file "reference_file.csv" --output_dir "test2"
```

## Project
This is an ongoing project at the Microbial Genome Analysis Group, Institute for Infection Prevention and Hospital Epidemiology, Üniversitätsklinikum, Freiburg. The project is funded by BMBF, Germany, and is led by [Dr. Sandra Reuter](https://www.uniklinik-freiburg.de/iuk-en/infection-prevention-and-hospital-epidemiology/research-group-reuter.html).


## Authors and acknowledgment
The TAPIR (Track Acquisition of Pathogens In Real-time) team.
