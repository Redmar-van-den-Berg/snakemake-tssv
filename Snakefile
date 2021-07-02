
pepfile: config['pepfile']
include: 'common.smk'

rule all:
    input:
        reports = expand('{sample}/tssv/reports.txt', sample=pep.sample_table.index),

checkpoint split_vcf:
    """ Split the variants over multiple files """
    input:
        vcf = pep.config['vcf']
    params:
        variants_per_file = pep.config['variants_per_file']
    output:
        directory('split-vcf')
    log:
        'log/split_vcf.txt'
    container:
        containers['debian']
    shell: """
        set -e

        mkdir -p {output}


        # Split the header from the variants
        grep '^#' {input.vcf} > {output}/header.txt
        grep -v '^#' {input.vcf} > {output}/variants.txt

        cd {output}

        # Split the variants into separate files
        split \
                --numeric-suffixes \
                --suffix-length 3 \
                --lines {params.variants_per_file} \
                variants.txt

        # Combine the split variants with the full header
        for i in x*; do
            cat header.txt ${{i}} > ${{i#x}}.vcf
        done

        # Remove intermediate files
        rm header.txt
        rm variants.txt
        rm x*
    """

rule create_tssv_config:
    """ Create configuration files for tssv """
    input:
        vcf = 'split-vcf/{chunk}.vcf',
        ref = pep.config['reference'],
        create_library = srcdir('scripts/create-library.py')
    params:
        flank_size = pep.config['flank_size'],
        max_indel_size = pep.config['max_indel_size']
    output:
        'library/{chunk}.lib'
    log:
        'log/library_{chunk}.txt'
    container:
        containers['tssv-library']
    shell: """
        {input.create_library} \
            --reference {input.ref} \
            --vcf {input.vcf} \
            --flank-size {params.flank_size} \
            --max-size {params.max_indel_size} > {output}
    """

rule run_tssv:
    input:
        library = 'library/{chunk}.lib',
        fastq = lambda wc: pep.sample_table.loc[wc.sample, wc.fastq],
    params:
        folder = '-d {sample}/tssv/{chunk}-{fastq}/' if pep.config['output_folder'] else ''
    output:
        report = '{sample}/tssv/{chunk}-{fastq}.txt'
    log:
        'log/tssv_{sample}_{chunk}_{fastq}.txt'
    container:
        containers['tssv']
    shell: """
        tssv \
            -r {output.report} \
            {params} \
            {input.fastq} \
            {input.library}
    """

rule list_report_files:
    """
    This is a dummy rule, used to trigger the checkpoint

    The number of report files are determined by the checkpoint, and hence cannot be
    known before the pipeline runs. Therefore, there is no way to include the
    report files in the 'all' rule.

    This rule consumes the checkpoint for each sample, and writes a simple text file that holds
    all report files. The output of this rule is a target for the 'all' rule.
    """
    input:
        gather_tssv_reports
    output:
        '{sample}/tssv/reports.txt'
    log:
        'log/list_report_files_{sample}.txt'
    container:
        containers['debian']
    shell: """
        ls {input} > {output} 2>{log}
    """
