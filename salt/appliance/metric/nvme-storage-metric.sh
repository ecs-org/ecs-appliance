#!/bin/bash
# metric from nvme-cli values, outputs a prometheus text collection

toolname="nvme"
storagesystem="nvme"

usage() {
    cat <<EOF
usage: $0 [--has-devices]

without parameter $(basename $0) will output all metric from all $storagesystem drives,
or exit 0 if no drives are available

$(basename $0) --has-devices
    will check for devices and exit 0 if at least one device is found,
    and exit 1 if no device is found

$(basename $0) will exit 1 if collection tool $toolname is not present, or at unsupported version

EOF
    exit 1
}


output_format_awk="$(cat << 'OUTPUTAWK'
BEGIN { v = "" }
v != $1 {
  print "# HELP nvme_" $1 " NVME metric " $1;
  print "# TYPE nvme_" $1 " gauge";
  v = $1
}
{print "nvme_" $0}
OUTPUTAWK
)"

format_output() {
  sort \
  | awk -F'{' "${output_format_awk}"
}

versionlte() {
    # args v1,v2 true if v1 <= v2
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

versionlt() {
    # args v1,v2 true if v1 < v2
    [ "$1" = "$2" ] && return 1 || versionlte $1 $2
}


if test "$1" = "--help"; then usage; fi
if ! which $toolname > /dev/null; then
    (>&2 echo "ERROR: program $toolname not found, can not collect metrics")
    exit 1
fi

nvme_version="$(${toolname} --version | sed -r "s/.*version ([0-9.+])/\1/g")"
if versionlte "1.0" "$nvme_version"; then
    (>&2 echo "ERROR: unsupported ${toolname} version $nvme_version")
    exit 1
fi

device_list="$(${toolname} list | grep /dev/  | sed -r 's/(\/dev\/[^ ]+) +.+/\1/g')"
if test "$1" = "--has-devices"; then
    if test "$device_list" != ""; then exit 0; else exit 1; fi
fi
if test "$device_list" = ""; then exit 0; fi

echo "nvmecli_version{version=\"${nvme_version}\"} 1" | format_output

for device in ${device_list}; do
    echo "nvmecli_run{disk=\"${device}\"}" $(TZ=UTC date '+%s')
    nvme_data=$(${toolname} list | grep "$device")
    device_serial=$(echo "$nvme_data" | tr -s " " | cut -d " " -f 2)
    model_vendor=$(echo "$nvme_data" | cut -c 39-79 |  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    device_model=$(echo "$model_vendor" | cut -d " " -f 1)
    device_vendor=$(echo "$model_vendor" | cut -d " " -f 2)
    device_firmware=$(echo "$nvme_data" | sed -r "s/.+ ([^ ]+)$/\1/g")
    echo "device_info{disk=\"${device}\",device_model=\"${device_model}\",serial_number=\"${device_serial}\",firmware_version=\"${device_firmware}\",vendor=\"${device_vendor}\"} 1"
    ${toolname} smart-log ${device} | sed '1d' | tr "A-Z" "a-z" | sed -r "s/([a-z0-9_ ]+) : ([0-9,]+).*/\2#\1/g"| tr -d "," | sed -e 's/[[:space:]]*$//' | tr " " "_" | sed -r 's/([^#]+)#(.*)/\2{disk="PLACEHOLDER"} \1/g' | sed -r "s#PLACEHOLDER#${device}#g"
done | format_output
