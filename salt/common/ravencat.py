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
import pwd

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

    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='grouping by sentry uses the first line of the message')
    parser.add_argument('--verbose', action='store_true', default=True)
    parser.add_argument('--culprit', default='ravencat.send_message')
    parser.add_argument('--logger', default='ravencat.main')
    parser.add_argument('--release', default='')
    parser.add_argument('--site', default='')
    parser.add_argument('--level', default='info', choices=logging_choices)
    parser.add_argument('--extra', default={}, action=JsonAction,
        help='a json dictionary of extra data')
    parser.add_argument('--tags', default={}, action=JsonAction,
        help='a json dictionary listening tag name and value')
    parser.add_argument('--request', default={}, action=JsonAction,
        help='a json dictionary of the request')
    parser.add_argument('--dsn', action=EnvDefault,
        envvar='SENTRY_DSN', required=True,
        help='specify a sentry dsn, will use env SENTRY_DSN if unset')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--mbox-message', type=exist_file, metavar='FILE',
        help='mbox filename to parse,split and send all')
    group.add_argument('--message', type=argparse.FileType(mode='r', encoding='utf-8'),
        dest='message_file',
        metavar='FILE',
        help='filename to read message from, use "-" for stdin')
    group.add_argument('message', nargs='?',
        help='the message string to be sent')

    args = parser.parse_args()

    client = Client(args.dsn,
        include_paths=['raven'],
        transport=RequestsHTTPTransport,
        release=args.release,
        site=args.site,
        )

    if not client.remote.is_active():
        print('Error: DSN configuration, client.remote.is_active <= false', file=sys.stderr)
        sys.exit(1)

    if not client.is_enabled():
        print('Error: Client reporting is disabled', file=sys.stderr)
        sys.exit(1)

    if args.mbox_message:
        try:
            mbox = mailbox.mbox(args.mbox_message)
            margs = args.__dict__

            for message in mbox:
                margs['culprit'] = message['From']
                margs['date'] = email.utils.parsedate_to_datetime(message['Date'])
                margs['logger'] = 'mailbox.mbox'

                for k in message.walk():
                    if k.get_content_type() == 'text/plain':
                        margs['extra'] = {'content': k.get_payload().splitlines()}
                        break

                success, eventid = send_message(client, message['subject'], margs)
                if success:
                    # TODO: delete message from mbox
                    pass
        finally:
            if mbox:
                mbox.close()
    else:
        if args.message_file:
            args.message= args.message_file.read()

        success, eventid = send_message(client, args.message, args.__dict__)
        sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
