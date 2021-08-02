#!/usr/bin/env python

import argparse
import json
from collections import defaultdict



def main(args):
    # Read the log files
    data = dict()
    for samplename, filename in zip(args.names, args.files):
        with open(filename) as fin:
            data[samplename] = json.load(fin)

    # For each report, determine alle alleles for each marker
    alleles = defaultdict(set)
    for report in data.values():
        for marker in report:
            for allele in report[marker]:
                alleles[marker].add(allele)
                
    # Print the header
    header = ['Marker', 'Allele'] + args.names
    print(*header, sep='\t')

    # Print the data
    for marker in alleles:
        for allele in alleles[marker]:
            sample_data = list()
            for sample in args.names:
                try:
                    total = data[sample][marker][allele]['total']
                except KeyError:
                    total = 0
                sample_data.append(total)
            print(marker, allele, *sample_data, sep='\t')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Combine (merged) json reports from different samples')
    parser.add_argument('--files', nargs='+', required=True,
                        help='merged report files, one for each sample')
    parser.add_argument('--names', nargs='+', required=True,
                        help='Names of the samples, one for each --file')
    args = parser.parse_args()
    assert len(args.files) == len(args.names), 'Specify a name for each file'
    main(args)
