
pepfile: config["pepfile"]
include: "common.smk"

rule all:
    input:
        outfile = expand('{sample}/vcf', sample=pep.sample_table.index),
        libraries = expand("merge_{sample}.txt", sample=pep.sample_table.index)

checkpoint split_vcf:
    """ Split the variants over multiple files """
    input:
        vcf = lambda wc: pep.sample_table.loc[wc.sample, 'vcf']
    params:
        variants_per_file = pep.config.variants_per_file
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

rule create_tssv_config:
    """ Create configuration files for tssv """
    input:
        vcf = "{sample}/vcf/{sample}_{chunk}.vcf",
        ref = "tests/data/reference/ref.fa",
        scr = "scripts/create-library.py"
    params:
        flank_size = 20,
        max_indel_size = 20
    output:
        "{sample}/library/{chunk}.lib"
    log:
        "log/{sample}_library_{chunk}.txt"
    container:
        containers["tssv-library"]
    shell: """
        {input.scr} \
            --reference {input.ref} \
            --vcf {input.vcf} \
            --flank-size {params.flank_size} \
            --max-size {params.max_indel_size} > {output}
    """

rule temp_merge_tssv:
    input: gather_libraries
    output: "merge_{sample}.txt"
    log: "log/merge_{sample}.txt"
    container:
        containers["debian"]
    shell: """
        cat {input} > {output}
    """
