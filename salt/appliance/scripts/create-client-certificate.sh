#!/bin/bash

usage(){
    cat << EOF
Usage:  $0 [--sendto user@address] user-email@address.domain cert_name [daysvalid]

Creates a client certificate, and send certificate via Email.

+ The the user must already exist
    and must be internal (ec-office or ec-executive or ec-signing)
+ The default certificate lifetime is 7 days.
    Change this with supplying daysvalid
+ optional parameter --sendto: send cert to a different email adress
+ Requirements: Appliance must be running.

EOF
    exit 1
}

if test "$1" = "--sendto"; then sendto="$2"; shift 2; else sendto=""; fi
if test "$2" = ""; then usage; fi
if test "$3" != ""; then daysvalid=$3; else daysvalid=7; fi
email="$1"
certname="$2"
if test "$sendto" = ""; then sendto=$email; fi

cat << EOF | docker exec -i ecs_ecs.web_1 /start run ./manage.py shell

sendto="$sendto"; email="$email"; certname="$certname"; daysvalid=$daysvalid;

import os
from django.conf import settings
from django.contrib.auth.models import Group, User
from ecs.pki.models import Certificate
from ecs.communication.mailutils import deliver

if not User.objects.filter(email=email).exists():
    print("Error: could not find user {}".format(email))
    exit(1)

u = User.objects.get(email=email)
cert, passphrase = Certificate.create_for_user(
    '/tmp/user.p12', u, cn=certname, days=daysvalid)
pkcs12 = open('/tmp/user.p12', 'rb').read()
os.remove('/tmp/user.p12')

deliver([sendto],
    subject='Certificate {}'.format(certname),
    message='See attachment',
    from_email=settings.DEFAULT_FROM_EMAIL,
    attachments=(('{}.p12'.format(certname), pkcs12, 'application/x-pkcs12'),),
    nofilter=True)

print("Create and send certificate for {} using passphrase {}".format(email, passphrase))
exit()

EOF
