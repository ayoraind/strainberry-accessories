process ASSEMBLY_STATS {
    tag "$meta"
    publishDir "${params.output_dir}", mode:'copy'

    input:
    tuple val(meta), path(assemblies), path(refcsvfile)

    output:
    tuple val(meta), path("${meta}/*.bestref.tsv"), emit: best_ref_ch
    // tuple val(meta), path("${meta}/${meta}.report.tsv") , emit: report_ch
    path("${meta}/${meta}.report.tsv") , emit: report_ch
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

   # cp ${meta}/report.tsv ${meta}/${meta}.report.tsv
    cp ${meta}.log ${meta}/${meta}.log

    HEADER=\$(echo "Directory\tref_id\tseq_num\tref_size\tasm_size\tN50\tunaligned_ref\tunaligned_asm\tANI\tdup_ratio\tdup_bases\tcmp_bases\tsnps\tinversions\trelocations\ttransloc") 
    
    echo "\${HEADER}" > ${meta}/${meta}.report.tsv

    echo "\$(awk -v dir="$meta" 'NR > 1 {print dir "\\t" \$0}' ${meta}/report.tsv)" >> ${meta}/${meta}.report.tsv

    """

}


process COMBINE_ASSEMBLY_STATS_REPORT {
    publishDir "${params.output_dir}", mode:'copy'
    tag { 'combine assembly statistics files'}


    input:
    path(assembly_statistics_files)


    output:
    path("combined_assembly_report.txt"), emit: assembly_comb_stats_ch


    script:
    """
    ASSEMBLY_STATISTICS_FILES=(${assembly_statistics_files})

    for index in \${!ASSEMBLY_STATISTICS_FILES[@]}; do
    ASSEMBLY_STATISTICS_FILE=\${ASSEMBLY_STATISTICS_FILES[\$index]}

    # add header line if first file
    if [[ \$index -eq 0 ]]; then
      echo "\$(head -1 \${ASSEMBLY_STATISTICS_FILE})" >> combined_assembly_report.txt
    fi
    echo "\$(awk 'FNR > 1 {print}' \${ASSEMBLY_STATISTICS_FILE})" >> combined_assembly_report.txt
    done

    """
}
