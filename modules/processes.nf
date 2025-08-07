process ASSEMBLY_STATS {
    tag "$meta"
    publishDir "${params.output_dir}/assembly_stats", mode:'copy'

    input:
    tuple val(meta), path(assemblies), path(refcsvfile)

    output:
    tuple val(meta), path("${meta}/*.bestref.tsv"), emit: best_ref_ch
    // tuple val(meta), path("${meta}/${meta}.report.tsv") , emit: report_ch
    path("${meta}/${meta}.report.tsv") , emit: report_ch
    tuple val(meta), path("${meta}/${meta}.log") , emit: log_ch
    tuple val(meta), path("${meta}/dnadiff") , emit: dnadiff_ch
    tuple val(meta), path("${meta}/*.fa") , emit: assembly_ch
    tuple val(meta), path("${meta}/qcoords/*.qcoords"), emit: qcoords_ch

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
    mkdir -p ${meta}/qcoords
    cp *.qcoords ${meta}/qcoords/

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


process ASSIGN_BEST_REFERENCE {
    tag "$meta"
    publishDir "${params.output_dir}/BEST_REF", mode:'copy'

    input:
    tuple val(meta), path(qcoords)

    output:
    tuple val(meta), path("${meta}.bestref.tsv"), emit: best_ref_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    assign_best_reference_from_nucmer_output.py $qcoords -o ${meta}.bestref.tsv

    """

}

process EXTRACT_BEST_CONTIG_PER_REFERENCE {
    tag "$meta"
    publishDir "${params.output_dir}/extract_best_contig_per_reference_and_merge", mode:'copy'

    input:
    tuple val(meta), path(tsv), path(assembly)

    output:
    tuple val(meta), path("${meta}/*.fasta"), emit: best_contig_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    extract_best_contigsv2.py $tsv $assembly -o ${meta}

    """

}


process NUCMER_FROM_BEST_CONTIGS {
    tag "$meta"
    publishDir "${params.output_dir}/nucmer_from_best_contigs", mode:'copy'

    input:
    tuple val(ref), val(meta), path(merged_contigs), path(reference)

    output:
    tuple val(meta), val("${meta}.${ref}"), path("${meta}/*.delta"), emit: nucmer_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"

    """
    mkdir ${meta}
    nucmer --maxmatch -t 1 -p ${meta}.${ref} ${reference} ${merged_contigs}
    mv *.delta ${meta}/
    """

}

process DELTA_FROM_BEST_CONTIGS {
    tag "$meta"
    publishDir "${params.output_dir}/delta_from_best_contigs", mode:'copy'

    input:
    tuple val(meta), val(prefix), path(delta)

    output:
    tuple val(meta), path("${meta}/*"), emit: delta_ch
    tuple val(meta), path("${meta}/*.report"), emit: report_ch
    tuple val(meta), path("${meta}/*.qdiff"), emit: qdiff_ch
    tuple val(meta), path("${meta}/*.rdiff"), emit: rdiff_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mkdir ${meta}
    dnadiff -p ${prefix} -d ${delta}
    
    mv *.*  ${meta}/
    """

}

process COPY_FASTAS {
    tag "$meta"
    publishDir "${params.output_dir}/delta_from_best_contigs", mode:'copy'

    input:
    tuple val(meta), val(reference), path(asm_fasta) 

    output:
    tuple val(meta), path("${meta}/${meta}.${reference}.fasta"), emit: fasta_ch
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mkdir -p ${meta}
    cp ${asm_fasta} ${meta}/${meta}.${reference}.fasta
    """

}

process FINAL_REPORT {
    tag "$meta"
    publishDir "${params.output_dir}/final_report", mode:'copy'

    input:
    tuple val(meta), path(collected_report), path(reference_file), path(collected_fastas), path(collected_qdiff), path(collected_rdiff)

    output:
    tuple val(meta), path("${meta}.tsv"), emit: final_ch
    
    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''

    """
    assembly_stats_parse_report.py --reports ${collected_report} --reflist ${reference_file} --outfile ${meta}.tsv
    """

}