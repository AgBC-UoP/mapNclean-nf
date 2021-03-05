# mapNclean-nf

### This script can map(bowtie2) paied-end dataset(s) to a referenece sequence and automatically removes soft clipped reads from the sam file using [samclip](https://github.com/tseemann/samclip)

``` nextflow run AgBC-UoP/mapNclean-nf --reads {readDir/READ_PATTERN} --reference {referenceDir/ref.fa}```

ex : ``` nextflow run AgBC-UoP/mapNclean-nf --reads "*R{1,2}*.fastq" --reference refseq.fa```
