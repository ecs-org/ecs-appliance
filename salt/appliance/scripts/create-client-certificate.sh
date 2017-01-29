#!/bin/bash

usage(){
    cat << EOF
Usage:  $0 user-email@address.domain cert_name [daysvalid]

Creates a client certificate, and send certificate via Email.

+ The the user must already exist
    and must be internal (ec-office or ec-executive or ec-signing)
+ The default certificate lifetime is 7 days.
    Change this with supplying daysvalid
+ Requirements: Appliance must be running.

EOF
    exit 1
}

daysvalid=7
email="$1"
certname="$2"
if test "$2" = ""; then usage; fi
if test "$3" != ""; then daysvalid=$3; fi

cat << EOF | docker exec -it ecs_ecs.web_1 /start run ./manage.py shell

email="$email"; certname="$certname"; daysvalid=$daysvalid;

from django.contrib.auth.models import Group, User
from ecs.communication.mailutils import deliver

if not User.objects.filter(email=email).exists():
    print("Error: could not find user {}".format(email))
    exit(1)

u = User.objects.get(email=email)
cert, passphrase = Certificate.create_for_user(
    '/tmp/user.p12', u, cn=certname, days=daysvalid)
pkcs12 = open('/tmp/user.p12', 'rb').read()
deliver(u.email,
    subject='Certificate {}'.format(certname),
    message='See attachment',
    from_email=settings.DEFAULT_FROM_EMAIL,
    attachments=(('user.p12', pkcs12, 'application/x-pkcs12'),),
    nofilter=True)

print("Create and send certificate for {} using passphrase {}".format(email, passphrase))
exit()

EOF
