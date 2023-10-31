process ASSEMBLY_STATS {
    tag "$meta"
    publishDir "${params.output_dir}", mode:'copy'

    input:
    tuple val(meta), path(assemblies), path(refcsvfile)
    

    output:
  //  tuple val(meta), path("*")
    tuple val(meta), path("${meta}/*.bestref.tsv"), emit: best_ref_ch
    tuple val(meta), path("${meta}/${meta}.report.tsv") , emit: report_ch
    tuple val(meta), path("${meta}/${meta}.log") , emit: log_ch
    tuple val(meta), path("${meta}/dnadiff") , emit: dnadiff_ch
    tuple val(meta), path("${meta}/*.fa") , emit: assembly_ch
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    
    """
    touch ${meta}.log
    assembly_stats.py -f $assemblies -r $refcsvfile -o ${meta} &> ${meta}.log
    
    cp ${meta}/report.tsv ${meta}/${meta}.report.tsv
    cp ${meta}.log ${meta}/${meta}.log

    """

}


