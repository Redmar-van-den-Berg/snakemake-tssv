containers = {
        'debian': 'docker://debian:latest',
        'tssv': 'docker://quay.io/biocontainers/tssv:1.1.0--py39h7cff6ad_0',
        'tssv-library': 'docker://quay.io/biocontainers/mulled-v2-ddb8b80b33a09f54efd9219c18e1d38acfa18bc8:ae02896ffb35dfc564385b2276a1fbf7862567c2-0'
}

def gather_tssv_reports(wildcards):
    """
    Gather the tssv report files, based on the split_vcf checkpoint.

    We have to use this helper function since we cannot know the number of
    output files that are produced by split_vcf, since that depends on the
    number of variants per split and the number of variants in the input VCF
    file.
    """
    checkpoint_output = checkpoints.split_vcf.get(**wildcards).output[0]

    # Glob the sample and chunks from the split vcf file
    globs = glob_wildcards(os.path.join(checkpoint_output, '{chunk}.vcf'))
    samples = pep.sample_table.index
    chunks = globs.chunk

    # We will get a report file for each sample, for each chunk, for both the
    # forward and reverse reads
    reports = list()
    for sample in samples:
        for chunk in chunks:
            for fastq in ['forward', 'reverse']:
                reports.append(f'{sample}/tssv/{chunk}-{fastq}.json')

    return reports

def set_default(key, value):
    """ Set configuration for key to value, if not yet set """
    if key not in pep.config:
        pep.config[key] = value

set_default('variants_per_file', 50)
set_default('flank_size', 20)
set_default('max_indel_size', 20)
set_default('output_folder', False)
