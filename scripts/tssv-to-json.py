#!/usr/bin/env python3

import argparse
import json
import re

re.search

def parse_section(fin):
    """ Parse a section from the tssv report

    NOTE: this moves the file pointer forwards
    """
    section = list()

    # Get the header
    header = next(fin).strip().split()

    # Parse the other files
    for line in fin:
        # End of section
        if not line.strip():
            break

        # Extract the data for an allele
        allele = {k:v for k, v in zip(header, line.strip().split())}

        # Convert all counts to int
        for key in allele:
            try:
                allele[key] = int(allele[key])
            except ValueError: # not an int
                pass

        section.append(allele)

    return section

def read_tssv(filename):
    """ Read the tssv report and convert it into a dictionary """
    known_allele = "known alleles for marker "
    new_allele = "new alleles for marker "

    # Lines to skip
    skip = [
        'total reads\t\d',
        'matched pairs\t\d',
        'new alleles\t\d',
        'new unique alleles\t\d',
        'no start\t\d',
        'no end\t\d',
        'unrecognised reads\t\d',
        '\n'
    ]

    data = dict()

    with open(filename) as fin:
        # This top level always points to a new section, or we skip
        for line in fin:
            # There are a bunch of lines in the report that we skip
            if any(re.match(regex, line) for regex in skip):
                continue

            # This is a section that we should skip, instead of a single line
            # So once we find it, we skip every line untill we come to an empty
            # line
            if re.match('name\tfPaired', line):
                line = next(fin)
                while line != '\n':
                    line = next(fin)
                continue

            # Make sure marker is in the data
            marker = line.strip().split()[4]

            # A line like known alleles for marker chrM:152:
            # instead of new alleles for marker chrM:152 (mean length 1.0):
            # So we cut off the last colon
            if marker.endswith(':'):
                marker = marker[:-1]

            if marker not in data:
                data[marker] = dict()

            # Parse known alleles
            if re.search(known_allele, line):
                known = parse_section(fin)
                data[marker]['known'] = known

            # Parse new alelles:
            elif re.search(new_allele, line):
                new = parse_section(fin)
                data[marker]['new'] = new
            # We should never reach this
            else:
                raise RuntimeError
    return {'marker': data}

def main(args):
    data = read_tssv(args.tssv)
    print(json.dumps(data, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('--tssv', required=True,
                        help='tssv output file, in text format')

    arguments = parser.parse_args()
    main(arguments)
