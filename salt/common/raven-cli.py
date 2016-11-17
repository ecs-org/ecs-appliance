#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
import logging
import os
import time
import argparse
import mailbox
import email

from raven import Client, get_version
from raven.transport.requests import RequestsHTTPTransport
from raven.utils.json import json


class EnvDefault(argparse.Action):
    def __init__(self, envvar, required=True, default=None, **kwargs):
        if not default and envvar:
            if envvar in os.environ:
                default = os.environ[envvar]
        if required and default:
            required = False
        super(EnvDefault, self).__init__(default=default, required=required,
                                         **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, values)

class JsonAction(argparse.Action):
    def __init__(self, option_strings, dest, **kwargs):
        super(JsonAction, self).__init__(option_strings, dest, **kwargs)
    def __call__(self, parser, namespace, values, option_strings):
        try:
            values = json.loads(values)
        except ValueError:
            print('Invalid JSON was used for option {}.  Received: {}'.format(
                option_strings, values), file=sys.stderr)
            raise
        setattr(namespace, self.dest, values)

def exist_file(x):
    """
    'Type' for argparse - checks that file exists but does not open.
    """
    if not os.path.exists(x):
        raise argparse.ArgumentTypeError("{0} does not exist".format(x))
    return x

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
        date=options.get('date'),
        tags=options.get('tags'),
        extra=options.get('extra'),
        # { 'user': get_uid() }.update(
    )
    success = not client.state.did_fail()
    if options.get('verbose', True):
        print('Event ID was {}'.format(eventid))
        if not success:
            print('error!', file=sys.stderr)

    return (success, eventid)


def main():
    logging_choices= ('critical', 'error', 'warning', 'info', 'debug')
    root = logging.getLogger('sentry.errors')
    root.setLevel(logging.DEBUG)

    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version', version=get_version())
    parser.add_argument('--verbose', action='store_true', default=True)
    parser.add_argument('--culprit', default='raven.scripts.runner')
    parser.add_argument('--logger', default='raven.cli')
    parser.add_argument('--release', default='')
    parser.add_argument('--site', default='')
    parser.add_argument('--level', default='info', choices=logging_choices)
    parser.add_argument('--tags', action=JsonAction)

    parser.add_argument('--dsn', action=EnvDefault, envvar='SENTRY_DSN',
        required=True, help='Specify Sentry DSN, will use env SENTRY_DSN if unset')

    group = parser.add_mutually_exclusive_group(required=False)
    group.add_argument('--request', action=JsonAction, default={})
    group.add_argument('--request-stdin', action='store_true', default=False)

    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument('message', nargs='?')
    input_group.add_argument('--mbox', type=exist_file, metavar='FILE')

    args = parser.parse_args()

    client = Client(args.dsn,
        include_paths=['raven'],
        transport=RequestsHTTPTransport,
        release=args.release,
        site=args.site,
        )

    if not client.remote.is_active():
        print('Error: DSN configuration is not valid!', file=sys.stderr)
        sys.exit(1)

    if not client.is_enabled():
        print('Error: Client reports are disabled!', file=sys.stderr)
        sys.exit(1)

    if args.mbox:
        try:
            mbox = mailbox.mbox(args.mbox)
            margs = args.__dict__

            for message in mbox:
                margs['culprit'] = message['From']
                margs['date'] = email.utils.parsedate_to_datetime(message['Date'])
                margs['logger'] = 'mailbox.mbox'

                for k in message.walk():
                    if k.get_content_type() == 'text/plain':
                        margs['extra'] = { 'content': k.get_payload().splitlines() }
                        break

                success, eventid = send_message(client, message['subject'], margs)
                if success:
                    # TODO: delete message from mbox
                    pass
        finally:
            if mbox:
                mbox.close()
    else:
        if args.request_stdin:
            with codecs.open(sys.stdin, 'r', 'utf-8') as f:
                args.request= json.loads(f.read())

        success, eventid = send_message(client, args.message, args.__dict__)

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    main()
