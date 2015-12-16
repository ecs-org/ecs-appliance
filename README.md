nginx does not support location based client certificates,
but client_cert_verify = optional, and export a variable.
We should use that variable within a middleware

mocca:static:all:https://joinup.ec.europa.eu/system/files/project/bkuonline-1.3.18.war:custom:bkuonline.war
pdfasconfig:static:all:https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.7/cfg/defaultConfig.zip:custom:pdf-as-web
pdfas:static:all:https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.7/pdf-as-web-4.0.7.war:custom:pdf-as-web.war
wily has wkhtmltopdf in version 12.2.4-1, so no manual download is required
http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb

```
cat application.py | grep -E "[^:]+:[^:]+:[^:]+.*" | grep -v ^# | sed -re "s/[^:]+:([^:]+).*/\1/g" | sort | uniq
cat application.py | grep -E "[^:]+:[^:]+:[^:]+.*" | grep -v ^# > test.txt

cat test.txt | grep -E "([^:]+:)(instbin|static|static64|static32|req:apt).*" | sort
cat test.txt | grep -E "([^:]+:)(instbin|static|static64|static32).*" | grep -v ":win:" | sort

```

use ubuntu wily

vagrant box add http://cloud-images.ubuntu.com/vagrant/wily/current/wily-server-cloudimg-amd64-vagrant-disk1.box --name wily --checksum c87753b8e40e90369c1d0591b567ec7b2a08ba4576714224bb24463a4b209d1a --checksum-type sha256
vagrant mutate wily libvirt --input-provider virtualbox

https://piratenpad.de/p/SarTB5QEQ

https://hitchtest.readthedocs.org/en/latest/faq/how_does_hitch_compare_to_other_technologies.html

https://cookiecutter-django.readthedocs.org/en/latest/developing-locally.html

https://github.com/joke2k/django-environ

hamlpy has not a lot of support,
best options so far:
https://bitbucket.org/dlamotte/haml-scss/src/d784e16cc04484b2c4e788e55ba1ded463221fe4/example/?at=default


look for best asset compressor
https://www.djangopackages.com/packages/p/django-pipeline/

https://pypi.python.org/pypi/django-taggit
https://www.djangopackages.com/packages/p/django-filter/
https://github.com/jessemiller/HamlPy
