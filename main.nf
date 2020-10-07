log1 = Channel.create().subscribe { println "Log 1: $it" }

Channel
    .fromPath("${params.single_end}")
    .map{ file-> tuple(file.simpleName, "SINGLE", file, file) }
    .set { single_ch }

Channel
    .fromFilePairs("${params.paired_end}")
    .map{ tup-> tuple(tup[0], "PAIRED", tup[1][0], tup[1][1]) }
    .set { paired_ch }

process kallisto {
    publishDir "$params.processed_folder/", mode: 'copy', saveAs: { filename -> "${id}_$filename" }

    input:
    file transcriptome_index from file("$params.index")
    set id, type, fasta1, fasta2 from paired_ch.mix(single_ch).tap(log1)

    output:
    file "abundance.tsv"
    file "run_info.json" 

    when:
    params.kallisto != "NOT_PROVIDED"

    script:
        if( type ==  "PAIRED") {
        """
        kallisto quant -i $transcriptome_index -o . -t ${params.NUM_THREADS} fasta1 fasta2
        """
        }  
        else if( type ==  "SINGLE"){
        """
        kallisto quant -i $transcriptome_index -o . --single -l 200 -s 20 -bias -t ${params.NUM_THREADS} fasta1
    """
        }

}


