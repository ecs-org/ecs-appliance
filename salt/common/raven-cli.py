#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
import logging
import os
import time
import argparse

from raven import Client, get_version
from raven.transport.requests import RequestsHTTPTransport
from raven.utils.json import json

logging_choices= ('critical', 'error', 'warning', 'info', 'debug')

class JsonAction(argparse.Action):
    def __init__(self, option_strings, dest, **kwargs):
        super(JsonAction, self).__init__(option_strings, dest, **kwargs)
    def __call__(self, parser, namespace, values, opts_str):
        try:
            values = json.loads(values)
        except ValueError:
            print('Invalid JSON was used for option {}.  Received: {}'.format(
                opt_str, values), file=sys.stderr)
            sys.exit(1)
        setattr(namespace, self.dest, values)

def get_uid():
    try:
        import pwd
    except ImportError:
        return None
    return pwd.getpwuid(os.geteuid())[0]


def send_message(client, message, options):
    eventid = client.captureMessage(
        message=message,
        data={
            'culprit': options.get('culprit'),
            'logger': options.get('logger'),
            'request': options.get('request'),
        },
        level=getattr(logging, options.get('level').upper()),
        stack=False,
        tags=options.get('tags'),
        extra={
            'user': get_uid(),
        },
    )
    return (not client.state.did_fail(), eventid)


def main():
    root = logging.getLogger('sentry.errors')
    root.setLevel(logging.DEBUG)

    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version', version=get_version())

    parser.add_argument('message', nargs='+')
    parser.add_argument('--dsn', nargs=1, help="SENTRY_DSN")

    parser.add_argument('--culprit', default='raven.scripts.runner')
    parser.add_argument('--logger', default='raven.test')
    parser.add_argument('--release', default='')
    parser.add_argument('--site', default='')
    parser.add_argument('--level', default='info', choices=logging_choices)
    parser.add_argument('--tags', action=JsonAction, nargs='?')
    parser.add_argument('--request', action=JsonAction, nargs='?', default=
        {
            'method': 'GET',
            'url': 'http://example.com',
        })

    args = parser.parse_args()
    client = Client(args.dsn, include_paths=['raven'],
        transport=RequestsHTTPTransport,
        release=args.release,
        site=args.site,
        )

    if not client.remote.is_active():
        print('Error: DSN configuration is not valid!', file=sys.stderr)
        sys.exit(1)

    if not client.is_enabled():
        print('Error: Client reports as being disabled!', file=sys.stderr)
        sys.exit(1)

    success, eventid = send_message(client, " ".join (args.message), args.__dict__)
    print('Event ID was {}'.format(eventid))

    if not success:
        print('error!', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(main())
