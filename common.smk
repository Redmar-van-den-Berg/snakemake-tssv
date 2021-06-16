containers = {
        "debian": "docker://debian:latest"
}

def get_outfile():
    return 'outputfile.txt'

def set_default_variants_per_file():
    try:
        pep.config.variants_per_file
    except AttributeError:
        pep.config.variants_per_file = 50

set_default_variants_per_file()
