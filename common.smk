containers = {
        "debian": "docker://debian:latest",
        "tssv-library": "docker://quay.io/biocontainers/mulled-v2-ddb8b80b33a09f54efd9219c18e1d38acfa18bc8:ae02896ffb35dfc564385b2276a1fbf7862567c2-0"
}

def gather_libraries(wildcards):
    """
    Gather the library files, based on the split_vcf checkpoint.

    We have to use this helper function since we cannot know the number of
    output files that are produced by split_vcf, since that depends on the
    number of variants per split and the number of variants in the input VCF
    file.
    """
    checkpoint_output = checkpoints.split_vcf.get(**wildcards).output[0]
    return expand("{{sample}}/library/{chunk}.lib",
            chunk=glob_wildcards(os.path.join(checkpoint_output, "{sample}_{chunk}.vcf")).chunk)

def set_default_variants_per_file():
    try:
        pep.config.variants_per_file
    except AttributeError:
        pep.config.variants_per_file = 50

set_default_variants_per_file()
