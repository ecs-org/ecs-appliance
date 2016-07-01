#!/usr/bin/env python

import sys
import collections

try:
    import yaml
except ImportError as e:
    print("ERROR: fatal, could not import: {0}".format(e))


def usage():
    print('''
usage: {0} {root|.} < data.yml

takes yaml from stdin,
selects optional root to filter yaml or "." for all,
flatten, upper case key names, print to stdout

program will exit with code:
10 = wrong/empty parameter, missing library, other fatal errors

  '''.format(sys.argv[0]))
    sys.exit(10)

def flatten(d, parent_key='', sep='_'):
    items = []
    for k, v in d.items():
        new_key = parent_key + sep + k if parent_key else k
        if isinstance(v, collections.MutableMapping):
            items.extend(flatten(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

def main():
    if len(sys.argv) > 1:
        usage()
    with sys.stdin as f:
        data=yaml.safe_load(f)
    if sys.argv[1] != ".":
        data = data[sys.argv[1]]
    for key,value in flatten(data).iteritems():
        print("{key}={value}".format(key=key.upper(), value=value))

if __name__ == '__main__':
    main()
