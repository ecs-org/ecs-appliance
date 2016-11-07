#!/usr/bin/env python3
import sys
import string
import collections

from shlex import quote

try:
    import yaml
except ImportError as e:
    print("ERROR: fatal, could not import: {0}".format(e))
    sys.exit(1)


def usage():
    print("usage: {0} ".format(sys.argv[0])+ '''(root[,root]*)|.} [prefix] [postfix] < data.yml

reads yaml from stdin,
select optional roots (seperated by ",") to filter yaml or "." for all,
flatten (concatinate with "_") & upper case key names,
convert lists to arrays using key_name[0] syntax,
strip and shlex.quote values if string,
convert bool to repr(value).lower(),
output {prefix}{KEY_NAME}{'['+ index+ ']'}='{shlex quoted value}'{postfix} to stdout

program will exit with code 1 on error (empty parameter, missing library)

  ''')
    sys.exit(1)


def flatten(d, parent_key='', sep='_', index=None):
    def _repr(v):
        if v is None:
            v = ""
        elif isinstance(v, str):
            v = quote(v.strip())
        elif isinstance(v, bool):
            v = repr(v).lower()
        return v

    items = []

    if isinstance(d, collections.MutableMapping):
        for k, v in d.items():
            new_key = parent_key + sep + k if parent_key else k
            items.extend(flatten(v, new_key, sep=sep, index=index).items())
        return dict(items)

    elif isinstance(d, (list, tuple)):
        for i, r in enumerate(d):
            items.extend(flatten(r, parent_key=parent_key, sep=sep, index=i).items())
        return dict(items)

    else:
        new_key = parent_key+ '_{}'.format(index) if index is not None else parent_key
        return {new_key: _repr(d)}


def main():
    prefix = postfix = keyroot = ""

    if len(sys.argv) < 2:
        usage()
    if len(sys.argv) >= 3:
        prefix = sys.argv[2]
    if len(sys.argv) >= 4:
        postfix = sys.argv[3]

    with sys.stdin as f:
        data = yaml.safe_load(f)

    if sys.argv[1] != ".":
        for i in sys.argv[1].split(','):
            keyroot = i.upper()+ "_"
            if i in data:
                rootdata = data[i]
                for key, value in flatten(rootdata).items():
                    print("{prefix}{key}={value}{postfix}".format(
                        prefix=prefix, key=keyroot+key.upper(),
                        value=value, postfix=postfix))
    else:
        for key, value in flatten(data).items():
            print("{prefix}{key}={value}{postfix}".format(
                prefix=prefix, key=key.upper(),
                value=value, postfix=postfix))


if __name__ == '__main__':
    main()
