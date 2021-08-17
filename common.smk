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
    chunks = globs.chunk

    # Determine the list of readgroups (which are subsamples in PEP terminology)
    # Depending on how the sample were specified in the PEP configuration, the
    # fastq files for 'forward' and 'reverse' can either be:
    # 1. A single path to the fastq file, i.e. a string
    # 2. A list containing a single path
    # 3. A list containing more than one path
    fastq = pep.sample_table.loc[wildcards.sample, 'forward']
    if isinstance(fastq, str):
        nr_fastq = 1
    elif isinstance(fastq, list):
        nr_fastq = len(fastq)
    else:
        raise RuntimeError('This should not happen')

    # Once we know how many files there are, we can generate the readgroup
    # names that are used in the file paths
    readgroups = [f'readgroup_{rg}' for rg in range(1, nr_fastq+1)]

    # We will get a report file for each chunk, for both the
    # forward and reverse reads, for each readgroup for sample
    reports = list()
    for chunk in chunks:
        for fastq in ['forward', 'reverse']:
            for readgroup in readgroups:
                reports.append(f'{wildcards.sample}/{readgroup}/{chunk}-{fastq}.json')

    return reports

def get_fastq_file(wildcards):
    """ Get the fastq file for the given wildcards

    This is a special case to support both normal samples (where there is one
    fastq for 'forward', 'reverse'), and subsamples, where each 'forward',
    'reverse' sample is actually a list.
    """
    fastq = pep.sample_table.loc[wildcards.sample, wildcards.fastq]


    # If the fastq file is already a path (string), we are done
    if isinstance(fastq, str):
        return fastq

    # Otherwise, it is a list of 1 or more paths, and we have to use the
    # 'readgroup' wildcard to select the proper fastq file to return.
    # This requires some messing about with the pep sample data, to generate
    # a mapping from readgroup name (readgroup_1, _2 etc) to the
    # corresponding fastq file
    readgroups = {f'readgroup_{rg}':filename for rg, filename in zip(range(1,len(fastq)+1), fastq)}

    return readgroups[wildcards.readgroup]

def set_default(key, value):
    """ Set configuration for key to value, if not yet set """
    if key not in config:
        config[key] = value

set_default('variants_per_file', 50)
set_default('flank_size', 20)
set_default('max_indel_size', 20)
set_default('output_folder', False)
