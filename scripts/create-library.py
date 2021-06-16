#!/usr/bin/env python3

import argparse

from cyvcf2 import VCF
from pysam import FastaFile

def create_library(name, record, chrom, begin, end=None, flank_size=20):
    """ Create a library line 

    record should be a pysam FastaFile

    """
    if not end:
        end = begin + 1

    left_marker = record.fetch(reference=chrom, start=begin-flank_size, end=begin)
    right_marker = record.fetch(reference=chrom, start=end, end=end+flank_size)
    expected_allele = record.fetch(reference=chrom, start=begin, end=end)

    return f'{name}\t{left_marker}\t{right_marker}\t{expected_allele} 1 1'

def main(args):
    # Read the reference fasta (requires biopython >=1.52
    record = FastaFile(args.reference)

    # Open the VCF
    for variant in VCF(args.vcf):
        name = f'{variant.CHROM}:{variant.POS}'
        # Get the size of the event
        size = max (len(x) for x in [variant.REF]+variant.ALT)
        # Skip if the event is too large
        if size > args.max_size:
            continue
        # VCF's are 1-based
        begin = variant.POS - 1
        end = begin + size
        lib = create_library(name, record, variant.CHROM, begin, end, args.flank_size)
        print(lib)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('--reference', required=True,
                        help='Reference fasta file')
    parser.add_argument('--vcf', required=True,
                        help='Create a library for the variants in the VCF')
    parser.add_argument('--flank-size', default=20, type=int,
                        help='Size of the flanking regions')
    parser.add_argument('--max-size', default=20, type=int,
                        help='Maximum size of an indel to verify')

    arguments = parser.parse_args()
    main(arguments)
