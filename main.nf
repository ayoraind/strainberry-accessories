#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// include non-process modules
include { help_message; version_message; complete_message; error_message; pipeline_start_message } from './modules/messages.nf'
include { default_params; check_params } from './modules/params_parser.nf'
include { help_or_version } from './modules/params_utilities.nf'

version = '1.0dev'

// setup default params
default_params = default_params()
// merge defaults with user params
merged_params = default_params + params

// help and version messages
help_or_version(merged_params, version)
final_params = check_params(merged_params)
// starting pipeline
pipeline_start_message(version, final_params)

// include processes
include { ASSEMBLY_STATS; COMBINE_ASSEMBLY_STATS_REPORT; ASSIGN_BEST_REFERENCE; EXTRACT_BEST_CONTIG_PER_REFERENCE; NUCMER_FROM_BEST_CONTIGS; DELTA_FROM_BEST_CONTIGS; COPY_FASTAS; FINAL_REPORT } from './modules/processes.nf' addParams(final_params)

workflow  {

	   assemblies_ch = channel
                                .fromPath( final_params.assemblies, checkIfExists: true )
                              //  .map { file -> tuple(file.simpleName, file) }
				.map { file -> tuple(file.baseName, file) }
				.ifEmpty { error "Cannot find any assemblies matching: ${final_params.assemblies}" }
				
	   reference_ch = channel
	   			.fromPath( final_params.reference_file, checkIfExists: true )
				
	   combined_ch = assemblies_ch.combine(reference_ch)

	   ASSEMBLY_STATS(combined_ch)
	  // ASSEMBLY_STATS.out.qcoords_ch.view()
	  
	   collected_assembly_statistics_ch = ASSEMBLY_STATS.out.report_ch.collect( sort: {a, b -> a[0].getBaseName() <=> b[0].getBaseName()} )
	   
	  // collected_assembly_statistics_ch.view()

    	COMBINE_ASSEMBLY_STATS_REPORT(collected_assembly_statistics_ch)

		ASSIGN_BEST_REFERENCE(ASSEMBLY_STATS.out.qcoords_ch)
	  //	ASSIGN_BEST_REFERENCE.out.best_ref_ch.view()

	  //	ASSIGN_BEST_REFERENCE.out.best_ref_ch.join(assemblies_ch).view()
	    EXTRACT_BEST_CONTIG_PER_REFERENCE(ASSIGN_BEST_REFERENCE.out.best_ref_ch.join(assemblies_ch))
		// EXTRACT_BEST_CONTIG_PER_REFERENCE.out.best_contig_ch.view()
	ref_split_ch = reference_ch
		         // .map { file -> tuple(file.baseName, file) }
				  .splitCsv ()
				 .map { ref, path -> tuple(ref.toString(), path) }
				 
		// output is [5925-200127, /path/to/5925-200127_contigs_filtered.fa]

	best_contig_adjusted_ch =	EXTRACT_BEST_CONTIG_PER_REFERENCE.out.best_contig_ch.flatMap { meta, fastas ->
							fastas.collect { fasta ->
							def ref = fasta.getName().tokenize('.')[1] // extracts the reference name
            					tuple(groupKey(meta, fastas.size()), ref, fasta)              // preserve group size with key
        								}
		}
		// output is [ERR13964273, 5925-200127, /path/to/work/3b/7421439015a3923a151d7629c8151c/ERR13964273/assembly.5925-200127.fasta]
	best_contig_adjusted_ch_transformed = best_contig_adjusted_ch.map { meta_id, ref_id, assembly_path -> 
								[ref_id, meta_id, assembly_path]
	}
	// best_contig_adjusted_ch_transformed.view()
		// join the two channels using same reference id
	joined_ch = best_contig_adjusted_ch_transformed.combine(ref_split_ch, by: 0)

	// joined_ch.view()

	NUCMER_FROM_BEST_CONTIGS(joined_ch)
	// NUCMER_FROM_BEST_CONTIGS.out.nucmer_ch.view()
	DELTA_FROM_BEST_CONTIGS(NUCMER_FROM_BEST_CONTIGS.out.nucmer_ch)
	// DELTA_FROM_BEST_CONTIGS.out.delta_ch.view()

	COPY_FASTAS(best_contig_adjusted_ch)

	collected_fasta_ch = COPY_FASTAS.out.fasta_ch
												.transpose()
												.groupTuple()

	collected_report_ch = DELTA_FROM_BEST_CONTIGS.out.report_ch
															.transpose()
															.groupTuple()

	collected_qdiff_ch = DELTA_FROM_BEST_CONTIGS.out.qdiff_ch
															.transpose()
															.groupTuple()
							

	collected_rdiff_ch = DELTA_FROM_BEST_CONTIGS.out.rdiff_ch
															.transpose()
															.groupTuple()

	final_ch = collected_report_ch
								.combine(reference_ch)
								.join(collected_fasta_ch, by: 0)
								.join(collected_qdiff_ch, by: 0)
								.join(collected_rdiff_ch, by: 0)
								
							//	.combine(best_contig_adjusted_ch_transformed, by: 0)
	// final_ch.view()
	
	FINAL_REPORT(final_ch)

	// combine final report

	combined_report = FINAL_REPORT.out.final_ch
												.map { meta, tsv -> tsv }
												.collectFile (
													name: 'combined_final_report.tsv',
													keepHeader: true,
													storeDir: "${params.output_dir}/final_report"
												)
}

workflow.onComplete {
    complete_message(final_params, workflow, version)
}

workflow.onError {
    error_message(workflow)
}
