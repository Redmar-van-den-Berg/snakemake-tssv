
include: "common.smk"
pepfile: config["pepfile"]


rule all:
    input:
        outfile = expand('{sample}/vcf', sample=pep.sample_table.index)
        #samples = expand('{sample}.txt', sample=pep.sample_table["sample_name"])

checkpoint split_vcf:
    """ Split the variants over multiple files """
    input:
        vcf = lambda wc: pep.sample_table.loc[wc.sample, 'vcf']
    params:
        variants_per_file = 3
    output:
        directory('{sample}/vcf/')
    log:
        "log/{sample}_split_vcf.txt"
    container:
        containers["debian"]
    shell: """
        set -e

        mkdir -p {output}

        zcat {input.vcf} > {output}/{wildcards.sample}.vcf

        cd {output}

        # Split the header from the variants
        grep "^#" {wildcards.sample}.vcf > header.txt
        grep -v "^#" {wildcards.sample}.vcf > variants.txt

        # Split the variants into separate files
        split \
                --numeric-suffixes \
                --suffix-length 3 \
                --lines {params.variants_per_file} \
                variants.txt

        # Combine the split variants with the full header
        for i in x*; do
            cat header.txt ${{i}} > {wildcards.sample}_${{i#x}}.vcf
        done

        # Remove intermediate files
        rm header.txt
        rm variants.txt
        rm x*
        rm {wildcards.sample}.vcf
    """
