
pepfile: config['pepfile']
include: 'common.smk'

rule all:
    input:
        final_report = 'final_report.csv'

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
            {input.library} 2> {log}
    """

rule tssv_to_json:
    input:
        json_script = srcdir('scripts/tssv-to-json.py'),
        report = rules.run_tssv.output.report
    output:
        '{sample}/tssv/{chunk}-{fastq}.json'
    log:
        'log/tssv_to_json_{sample}_{chunk}_{fastq}.txt'
    container:
        containers['tssv']
    shell: """
        {input.json_script} \
            --tssv {input.report} > {output} 2> {log}
    """

rule merge_report_files:
    """
    This is a dummy rule, used to trigger the checkpoint

    The number of report files are determined by the checkpoint, and hence cannot be
    known before the pipeline runs. Therefore, there is no way to include the
    report files in the 'all' rule.

    This rule consumes the checkpoint for each sample, and writes a simple text file that holds
    all report files. The output of this rule is a target for the 'all' rule.
    """
    input:
        json_report = gather_tssv_reports,
        merge_tssv = srcdir('scripts/merge-tssv.py')
    output:
        '{sample}/tssv/merged.json'
    log:
        'log/merge_report_files_{sample}.txt'
    container:
        containers['tssv']
    shell: """
        python {input.merge_tssv} --files {input.json_report} > {output} 2>{log}
    """

rule combine_samples:
    """
    Combine the merged data for each sample into a single tsv file
    """
    input:
        reports = expand('{sample}/tssv/merged.json', sample=pep.sample_table.index),
        combine_samples = srcdir('scripts/combine-samples.py'),
    params:
        names = [sample for sample in pep.sample_table.index]
    output:
        final_report = 'final_report.csv'
    log:
        'log/final_report.txt'
    container:
        containers['tssv']
    shell: """
        python {input.combine_samples} \
                --files {input.reports} \
                --names {params.names} \
                > {output.final_report} \
                2> {log}
    """
