log1 = Channel.create().subscribe { println "Log 1: $it" }

Channel
    .fromPath("${params.table}")
    .splitCsv(header:true)
    .map{ row-> tuple(row.run_accession, row.library_layout, row.fastq_ftp1, row.fastq_ftp2) }
    .tap(log1)
    .set { runs_ch }

process kallisto {
	publishDir "$params.processed_folder/", mode: 'copy', saveAs: { filename -> "${id}_$filename" }

    input:
    file transcriptome_index from file("$params.index")
    set id, type, ftp1, ftp2 from runs_ch

    output:
    file "abundance.tsv"
    file "run_info.json" 

    when:
    params.kallisto != "NOT_PROVIDED"

    script:
    	if( type ==  "PAIRED") {
        """
        curl $ftp1 > r_1.fasta.gz
        curl $ftp2 > r_2.fasta.gz

        kallisto quant -i $transcriptome_index -o . -t ${params.NUM_THREADS} r_1.fasta.gz r_2.fasta.gz
        """
    	}  
    	else if( type ==  "SINGLE"){
        """
        curl $ftp1 > r.fasta.gz
        kallisto quant -i $transcriptome_index -o . --single -l 200 -s 20 -bias -t ${params.NUM_THREADS} r.fasta.gz
        
	#sed s/// > abundance.tsv
	"""
    	}
}

