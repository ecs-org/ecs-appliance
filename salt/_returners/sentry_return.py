# -*- coding: utf-8 -*-
'''
Salt returner that reports execution results back to sentry. The returner will
inspect the payload to identify errors and changes and flag them as such.

Pillar needs something like:

.. code-block:: yaml

    raven:
      dsn: https://aaaa:bbbb@app.getsentry.com/12345
      hide_pillar: true
      hide_grains: true
      report_errors_only: true
      change_level: info
      error_level: error
      tags:
        - os
        - master
        - saltversion
        - cpuarch

https://pypi.python.org/pypi/raven and
https://pypi.python.org/pypi/requests must be installed.

The tags list (optional) specifies grains items that will be used as sentry
tags, allowing tagging of events in the sentry ui.

To report only errors (but no changes) to sentry, set report_errors_only: true.

'''
from __future__ import absolute_import

# Import Python libs
import logging

# Import Salt libs
import salt.loader
import salt.utils.jid
import salt.ext.six as six

try:
    from raven import Client
    from raven.transport.requests import RequestsHTTPTransport
    has_raven = True
except ImportError:
    has_raven = False

logger = logging.getLogger(__name__)

# Define the module's virtual name
__virtualname__ = 'sentry'


def __virtual__():
    if not has_raven:
        return False, 'Could not import sentry returner; ' \
                      'raven python client is not installed.'
    if 'raven' not in __opts__:
        return False, 'No \'raven\' key was found in the configuration'
    if 'dsn' not in __opts__['raven']:
        return False, 'Sentry returner needs key raven:dsn in the configuration'
    __grains__ = salt.loader.grains(__opts__)
    __salt__ = salt.loader.minion_mods(__opts__)
    return __virtualname__


def prep_jid(nocache=False, passed_jid=None):  # pylint: disable=unused-argument
    '''
    Do any work necessary to prepare a JID, including sending a custom id
    '''
    return passed_jid if passed_jid is not None else salt.utils.jid.gen_jid()


def returner(ret):
    '''
    Log outcome to sentry. The returner tries to identify errors and report
    them as such. Changes will be reported at info level.
    '''

    def ret_is_success(result):
        failed_states = {}
        changed_states = {}
        success = False

        if result.get('success') and result.get('retcode', 0) == 0:
            success = True

        if result.get('return'):
            if isinstance(result['return'], dict):
                for state_id, state_result in six.iteritems(result['return']):
                    if not state_result['result']:
                        failed_states[state_id] = state_result
                    if (state_result['result'] and
                        len(state_result['changes']) > 0):
                        changed_states[state_id] = state_result
            else:
                if not result.get('success') or result.get('retcode', 0) != 0:
                    failed_states[result['fun']] = result['return']

        result['changed_states'] = changed_states
        result['failed_states'] = failed_states
        return success

    def get_message():
        return 'func: {fun}, jid: {jid}'.format(fun=ret['fun'], jid=ret['jid'])

    def connect_sentry(message, result):
        '''
        Connect to the Sentry server
        '''
        pillar_data = __salt__['pillar.raw']()
        grains = __salt__['grains.items']()
        raven_config = __opts__['raven']
        hide_pillar = raven_config.get('hide_pillar', True)
        hide_grains = raven_config.get('hide_grains', True)
        sentry_data = {
            'result': result,
            'pillar': 'HIDDEN' if hide_pillar else pillar_data,
            'grains': 'HIDDEN' if hide_grains else grains,
        }
        data = {
            'platform': 'python',
            'culprit': 'salt-call',
            'level': 'error'
        }
        tags = {}
        if 'tags' in raven_config:
            for tag in raven_config['tags']:
                tags[tag] = grains[tag]

        client = Client(raven_config.get('dsn'), transport=RequestsHTTPTransport)
        has_error= not ret_is_success(result)

        if has_error:
            data['level'] = raven_config.get('error_level', 'error')
            message = "Salt error on " + result['id']
            sentry_data['result'] = result['failed_states']

            try:
                msgid = client.capture('raven.events.Message',
                    message=message, data=data, extra=sentry_data, tags=tags)
                logger.info('Message id %s written to sentry', msgid)
            except Exception as exc:
                logger.error('Can\'t send message to sentry: {0}'.format(exc), exc_info=True)

        if raven_config.get('report_errors_only'):
            return

        if result['changed_states']:
            data['level'] = raven_config.get('change_level', 'info')
            message = "Salt change(s) on " + result['id']
            sentry_data['result'] = result['changed_states']

            try:
                msgid = client.capture('raven.events.Message',
                    message=message, data=data, extra=sentry_data, tags=tags)
                logger.info('Message id %s written to sentry', msgid)
            except Exception as exc:
                logger.error('Can\'t send message to sentry: {0}'.format(exc), exc_info=True)

    try:
        connect_sentry(get_message(), ret)
    except Exception as err:
        logger.error('Can\'t run connect_sentry: {0}'.format(err), exc_info=True)
