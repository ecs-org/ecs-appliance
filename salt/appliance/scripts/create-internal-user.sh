#!/bin/bash

usage(){
    cat << EOF
Usage:  $0 email@domain "first name" "Last Name" "m/f"

Creates a internal office user.
gender can be "f" or "m"

EOF
    exit 1
}


cat << EOF | docker exec -it ecs_ecs.web_1 /start run ./manage.py shell

email='$1'; first_name='$2'; last_name='$3'; gender='$4'

import math, string
from random import SystemRandom
from ecs.users.utils import create_user
from django.contrib.auth.models import Group, User

PASSPHRASE_ENTROPY = 80
PASSPHRASE_CHARS = string.ascii_lowercase + string.digits
PASSPHRASE_LEN = math.ceil(PASSPHRASE_ENTROPY / math.log2(len(PASSPHRASE_CHARS)))

u = User.objects.get(email=email) if User.objects.filter(email=email).exists() else create_user(email)
p = u.profile
p.gender = gender
p.is_internal = True
p.save()
passphrase = ''.join(SystemRandom().choice(PASSPHRASE_CHARS) for i in range(PASSPHRASE_LEN))
u.first_name=first_name
u.last_name=last_name
u.set_password(passphrase)
print("created/updated user {} with passphrase {}".format (email, passphrase))
u.save()
u.groups.add(Group.objects.get(name='EC-Office'))
exit()

EOF
