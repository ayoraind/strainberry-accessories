def help_message() {
  log.info """
        Usage:
        The typical command for running the pipeline is as follows:
        nextflow run main.nf --assemblies "PathToReadFile(s)" --reference_file "PathtoCSVFile" --output_dir "PathToOutputDir"  

        Mandatory arguments:
         --assemblies                   FASTA file to be mapped against references (e.g., "/MIGE/01_DATA/03_ASSEMBLY/T055-8-*_FLYE/T055-8-*.fasta")
	 --reference_file		A headerless comma-separated (csv) containing ref_id in the first column and ref_fasta_path in the second column
         --output_dir                   Output directory to place output (e.g., "/MIGE/04_PROJECTS/STRAIN_RESOLUTION")
         
        Optional arguments:
         --help                         This usage statement.
         --version                      Version statement
        """
}



def version_message(String version) {
      println(
            """
            ============================================================================
             POST-ASSEMBLY QC: TAPIR Pipeline version ${version}
            ============================================================================
            """.stripIndent()
        )

}


def pipeline_start_message(String version, Map params){
    log.info "===================================================================================="
    log.info " POST-ASSEMBLY QC: TAPIR Pipeline version ${version}"
    log.info "===================================================================================="
    log.info "Running version   : ${version}"
    log.info "Fasta inputs      : ${params.assemblies}"
    log.info "Reference file    : ${params.reference_file}"
    log.info ""
    log.info "-------------------------- Other parameters ----------------------------------------"
    params.sort{ it.key }.each{ k, v ->
        if (v){
            log.info "${k}: ${v}"
        }
    }
    log.info "===================================================================================="
    log.info "Outputs written to path '${params.output_dir}'"
    log.info "===================================================================================="

    log.info ""
}


def complete_message(Map params, nextflow.script.WorkflowMetadata workflow, String version){
    // Display complete message
    log.info ""
    log.info "Ran the workflow: ${workflow.scriptName} ${version}"
    log.info "Command line    : ${workflow.commandLine}"
    log.info "Completed at    : ${workflow.complete}"
    log.info "Duration        : ${workflow.duration}"
    log.info "Success         : ${workflow.success}"
    log.info "Work directory  : ${workflow.workDir}"
    log.info "Exit status     : ${workflow.exitStatus}"
    log.info ""
}

def error_message(nextflow.script.WorkflowMetadata workflow){
    // Display error message
    log.info ""
    log.info "Workflow execution stopped with the following message:"
    log.info "  " + workflow.errorMessage
}


