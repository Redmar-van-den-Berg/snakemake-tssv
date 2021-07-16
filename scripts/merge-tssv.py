"""
Module that contains the command line app, so we can still import __main__
without executing side effects
"""

import argparse
import copy
import json

def merge(d1, d2):
    """ Merge two dictionaries together by adding their values

    # Test empty dictionary
    >>> d1=dict()
    >>> d2={'one': 1}
    >>> merge(d1, d2)
    {'one': 1}
    
    # Test two non-empty dictionary
    >>> merge(d2, d2)
    {'one': 2}

    # Test nested dictionary
    >>> d3 = {'dict': {'one': 1}}
    >>> merge(d3, d3)
    {'dict': {'one': 2}}

    # Make sure we modify neither dictionary
    >>> d1
    {}
    >>> d2
    {'one': 1}
    >>> d3
    {'dict': {'one': 1}}
    """
    newdict = copy.deepcopy(d1)
    for key in d2:
        if key not in newdict:
            newdict[key] = d2[key]
        elif isinstance(d2[key], dict):
            newdict[key] = merge(newdict[key], d2[key])
        else:
            newdict[key] += d2[key]
    return newdict


def flatten(report):
    """ Flatten a tssv json report to make it easier to work with

    1. Only include the 'marker' section
    2. Merge the 'known' and 'new' sections together, since they hold the same
        information
    3. Instead of a list of alleles, make it a dict with the allele as key
    """
    # 1. Only include the marker section
    flat = report['marker']

    for marker in flat:
        # 2. Combine 'known' and 'new' into a single list
        alleles = flat[marker].pop('known') + flat[marker].pop('new')
        # 3. Store in a new dictionary using the allele as key
        flat[marker] = {allele.pop('allele'): allele for allele in alleles}

    return flat


def main():
    parser = argparse.ArgumentParser(description='Merge tssv json report files')
    parser.add_argument('--files', nargs='+', required=True,
                        help='tssv report files to merge')
    args = parser.parse_args()

    # The final, merged json report
    final_report = dict()
    for filename in args.files:
        with open(filename) as fin:
            report = flatten(json.load(fin))
            final_report = merge(final_report, report)

    print(json.dumps(final_report, indent=True))


if __name__ == '__main__':
    main()
