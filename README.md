# ECS-Appliance - DEV Branch

the ecs-appliance is a selfservice production setup virtual machine builder and executor for ecs.
it can be stacked on top of the developer vm, but is independent of it. 

See [the Administrator Manual](https://ecs-org.github.io/ecs-docs/admin-manual/index.html) for installing and configuring an ECS-Appliance.

## Quickstart

```
# bootstrap appliance
export DEBIAN_FRONTEND=noninteractive
apt-get -y update && apt-get -y install curl
curl https://raw.githubusercontent.com/ecs-org/ecs-appliance/master/bootstrap-appliance.sh > /tmp/bootstrap.sh
cd /tmp; chmod +x /tmp/bootstrap.sh; /tmp/bootstrap.sh --yes 2>&1 | tee /tmp/setup.log

# create a new environment
env-create.sh domain.name /app/env.yml
XXX: edit your created env.yml and change settings

# activate environment
chmod 0600 /app/env.yml
cp /app/env.yml /run/active-env.yml

# create a empty ecs database
sudo -u postgres createdb ecs -T template0  -l de_DE.utf8

# apply new environment settings and start service
systemctl restart appliance

# create first internal office user (f=female, m=male)
create-internal-user.sh useremail@domain.name "First Name" "Second Name" "f" 

# create and send matching client certificate
create-client-certificate.sh useremail@domain.name cert_name [daysvalid(default=7)]

# disable test user
cat << EOF | docker exec -i ecs_ecs.web_1 /start run ./manage.py shell
from django.contrib.auth.models import User
User.objects.filter(profile__is_testuser=True).update(is_active=False)
EOF

# Installation is finished. 
# Import Client Certificate into browser.
# Browse to https://domain.name and login.
```
