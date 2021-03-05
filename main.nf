#!/usr/bin/env nextflow

params.reads = "$launchDir/*_R{1,2}.{fastq}"
params.outdir = "$launchDir/nf-out"
params.reference = "$launchDir/genes/verum_myst.fasta"


Channel.fromPath(params.reference)
    .into {fasta_ch;fasta_ch1}
Channel
  .fromFilePairs( params.reads )
  .ifEmpty { error "Oops! Cannot find any file matching: ${params.reads}"  }
  .into { read_pairs_ch; read_pairs2_ch }


process index {

  input:
  file reference from fasta_ch

  output:
  file "${reference.baseName}*" into index_ch

  script:
  """
  bowtie2-build $reference ${reference.simpleName}
  """
      }


process mapping {
    tag "$pair_id ${index.simpleName.first()}"
    publishDir "${params.outdir}/bam/${index.simpleName.first()}", mode:'copy', pattern: '*.sam'
    publishDir "${params.outdir}/bam/${index.simpleName.first()}/logs", mode:'copy', pattern: '*.log'

    cpus 12
    maxForks 3

    input:
    file index from index_ch.collect()
    set pair_id, file(reads) from read_pairs_ch

    output:
    file '*.sam' into sam
    file "${index.simpleName.first()}_${pair_id}.log" into logs
     
    script:
    """
        bowtie2 \\
            --threads $task.cpus \\
            -x ${index.simpleName.first()} \\
            -q -1 ${reads[0]} -2 ${reads[1]} \\
            --very-sensitive-local \\
            -S ${index.simpleName.first()}_${pair_id}.sam \\
            --no-unal \\
            2>&1 | tee ${index.simpleName.first()}_${pair_id}.log
    """
}

process index_samtools {

  input:
  file reference from fasta_ch1

  output:
  file "${reference}*" into index_ch1

  script:
  """
  samtools faidx $reference
  """
      }

process remove_clipping {
    conda "bioconda::samclip"
    tag "${index.simpleName}"
    publishDir "${params.outdir}/bam/${index.simpleName}", mode:'copy', pattern: '*.sam'

    input:
    file(samf) from sam
    file index from index_ch1.collect()

    output:
    file '*.sam' into sam_out

    script:
    """
    samclip --ref ${index} < ${samf} > clean.${samf}
    """
}

workflow.onComplete { 
	log.info( workflow.success ? "\nDone! Your files can be found in $launchDir/nf-out\n" : "Oops .. something went wrong" )
}