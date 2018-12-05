#!/bin/bash
# metric from smartctl values prometheus text collection
# based on http://devel.dob.sk/collectd-scripts/
# see also http://arstechnica.com/civis/viewtopic.php?p=22062211

toolname="smartctl"
storagesystem="smart"

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


parse_smartctl_attributes_awk="$(cat << 'SMARTCTLAWK'
$1 ~ /^[0-9]+$/ && $2 ~ /^[a-zA-Z0-9_-]+$/ {
  gsub(/-/, "_");
  printf "%s_value{%s,smart_id=\"%s\"} %d\n", $2, labels, $1, $4
  printf "%s_worst{%s,smart_id=\"%s\"} %d\n", $2, labels, $1, $5
  printf "%s_threshold{%s,smart_id=\"%s\"} %d\n", $2, labels, $1, $6
  printf "%s_raw_value{%s,smart_id=\"%s\"} %d\n", $2, labels, $1, $10
}
SMARTCTLAWK
)"

smartmon_attrs="$(cat << 'SMARTMONATTRS'
airflow_temperature_cel
command_timeout
current_pending_sector
end_to_end_error
erase_fail_count
g_sense_error_rate
hardware_ecc_recovered
host_reads_mib
host_reads_32mib
host_writes_mib
host_writes_32mib
load_cycle_count
media_wearout_indicator
nand_writes_1gib
offline_uncorrectable
power_cycle_count
power_on_hours
program_fail_count
raw_read_error_rate
reallocated_sector_ct
reported_uncorrect
sata_downshift_count
spin_retry_count
spin_up_time
start_stop_count
temperature_celsius
total_lbas_read
total_lbas_written
udma_crc_error_count
unsafe_shutdown_count
workld_host_reads_perc
workld_media_wear_indic
workload_minutes
SMARTMONATTRS
)"
smartmon_attrs="$(echo ${smartmon_attrs} | xargs | tr ' ' '|')"

parse_smartctl_attributes() {
  local disk="$1"
  local disk_type="$2"
  local labels="disk=\"${disk}\",type=\"${disk_type}\""
  local vars="$(echo "${smartmon_attrs}" | xargs | tr ' ' '|')"
  sed 's/^ \+//g' \
    | awk -v labels="${labels}" "${parse_smartctl_attributes_awk}" 2>/dev/null \
    | tr A-Z a-z \
    | grep -E "(${smartmon_attrs})"
}

parse_smartctl_info() {
  local -i smart_available=0 smart_enabled=0
  local disk="$1" disk_type="$2"
  while read line ; do
    info_type="$(echo "${line}" | cut -f1 -d: | tr ' ' '_')"
    info_value="$(echo "${line}" | cut -f2- -d: | sed 's/^ \+//g')"
    case "${info_type}" in
      Model_Family) model_family="${info_value}" ;;
      Device_Model) device_model="${info_value}" ;;
      Serial_Number) serial_number="${info_value}" ;;
      Firmware_Version) fw_version="${info_value}" ;;
      Vendor) vendor="${info_value}" ;;
      Product) product="${info_value}" ;;
      Revision) revision="${info_value}" ;;
      Logical_Unit_id) lun_id="${info_value}" ;;
    esac
    if [[ "${info_type}" == 'SMART_support_is' ]] ; then
      case "${info_value:0:7}" in
        Enabled) smart_enabled=1 ;;
        Availab) smart_available=1 ;;
        Unavail) smart_available=0 ;;
      esac
    fi
  done
  if [[ -n "${model_family}" ]] ; then
    echo "device_info{disk=\"${disk}\",type=\"${disk_type}\",model_family=\"${model_family}\",device_model=\"${device_model}\",serial_number=\"${serial_number}\",firmware_version=\"${fw_version}\"} 1"
  elif [[ -n "${vendor}" ]] ; then
    echo "device_info{disk=\"${disk}\",type=\"${disk_type}\",vendor=\"${vendor}\",product=\"${product}\",revision=\"${revision}\",lun_id=\"${lun_id}\"} 1"
  fi
  echo "device_smart_available{disk=\"${disk}\",type=\"${disk_type}\"} ${smart_available}"
  echo "device_smart_enabled{disk=\"${disk}\",type=\"${disk_type}\"} ${smart_enabled}"
}

output_format_awk="$(cat << 'OUTPUTAWK'
BEGIN { v = "" }
v != $1 {
  print "# HELP smartmon_" $1 " SMART metric " $1;
  print "# TYPE smartmon_" $1 " gauge";
  v = $1
}
{print "smartmon_" $0}
OUTPUTAWK
)"

format_output() {
  sort \
  | awk -F'{' "${output_format_awk}"
}


if test "$1" = "--help"; then usage; fi
if ! which $toolname > /dev/null; then
    (>&2 echo "ERROR: program $toolname not found, can not collect metrics")
    exit 1
fi

smartctl_version="$(${toolname} -V | head -n1  | awk '$1 == "smartctl" {print $2}')"

if [[ "$(expr "${smartctl_version}" : '\([0-9]*\)\..*')" -lt 6 ]] ; then
    (>&2 echo "ERROR: unsupported ${toolname} version $smartctl_version")
    exit 1
fi

device_list="$(${toolname} --scan-open | grep -v "^#" | awk '{print $1 "|" $3}')"

if test "$1" = "--help"; then usage; fi
if test "$1" = "--has-devices"; then
    if test "$device_list" != ""; then exit 0; else exit 1; fi
fi
if test "$device_list" = ""; then exit 0; fi

echo "smartctl_version{version=\"${smartctl_version}\"} 1" | format_output

for device in ${device_list}; do
    disk="$(echo ${device} | cut -f1 -d'|')"
    type="$(echo ${device} | cut -f2 -d'|')"
    echo "smartctl_run{disk=\"${disk}\",type=\"${type}\"}" $(TZ=UTC date '+%s')
    ${toolname} -i -d "${type}" "${disk}" | parse_smartctl_info "${disk}" "${type}"
    ${toolname} -A -d "${type}" "${disk}" | parse_smartctl_attributes "${disk}" "${type}"
done | format_output
