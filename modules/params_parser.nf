include { check_mandatory_parameter; check_optional_parameters; check_parameter_value } from './params_utilities.nf'

def default_params(){
    /***************** Setup inputs and channels ************************/
    def params = [:] as nextflow.script.ScriptBinding$ParamsMap
    // Defaults for configurable variables
    params.help = false
    params.version = false
    params.reference_file = false
    params.assemblies = false
    params.output_dir = false
    return params
}

def check_params(Map params) { 
    final_params = params
    
    // set up assembly files
    final_params.assemblies = check_mandatory_parameter(params, 'assemblies')
    
    // set up reference file
    final_params.reference_file = check_mandatory_parameter(params, 'reference_file')
     
    // set up output directory
    final_params.output_dir = check_mandatory_parameter(params, 'output_dir') - ~/\/$/
     
    return final_params
}

