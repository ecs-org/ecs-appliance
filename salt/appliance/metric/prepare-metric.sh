prepare_metric () {
    # set/clear flags and start/stop services connected to flags
    services="cadvisor.service node-exporter.service postgres_exporter.service process-exporter.service"
    if is_truestr "$APPLIANCE_METRIC_EXPORTER"; then
        flag_and_service_enable "metric.exporter" "$services"
    else
        flag_and_service_disable "metric.exporter" "$services"
    fi
    services="prometheus.service alertmanager.service"
    if is_truestr "$APPLIANCE_METRIC_SERVER"; then
        flag_and_service_enable "metric.server" "$services"
        sed -ri.bak  's/([ \t]+site:).*/\1 "'${APPLIANCE_DOMAIN}'"/g' /app/etc/prometheus.yml
        if ! diff -q /app/etc/prometheus.yml /app/etc/prometheus.yml.bak; then
            echo "info: changed prometheus external:site tag to ${APPLIANCE_DOMAIN}"
            systemctl restart prometheus.service
        fi
    else
        flag_and_service_disable "metric.server" "$services"
    fi
    if is_truestr "$APPLIANCE_METRIC_GUI"; then
        flag_and_service_enable "metric.gui" "grafana.service"
    else
        flag_and_service_disable "metric.gui" "grafana.service"
    fi
    if is_truestr "$APPLIANCE_METRIC_PGHERO"; then
        flag_and_service_enable "metric.pghero" "pghero-container.service"
    else
        flag_and_service_disable "metric.pghero" "pghero-container.service"
    fi
}

mute_alerts() {
    # JobInstanceDown
    # POST http://localhost:9093/api/v1/silences
    # application/json
    # {"matchers":[{"name":"alertname","value":"JobInstanceDown","isRegex":false}],"createdBy":"appliance-update@localhost","startsAt":"2017-02-19T14:01:00.000Z","endsAt":"2017-02-19T18:01:00.000Z","comment":"system update"}
    # response: json
    # {"status":"success","data":{"silenceId":"1e452199-cabc-47d7-a84e-a5acc0b8855f"}}
    # check status, and write silenceId to /app/etc/tags/silenceId
    #
    # get alert manager compatible datetime: $(date -u "+%Y-%m-%dT%H:%M:%SZ")
    # get seconds since epoch: $(date +%s)
    # add 30 minutes to epoch: $(( $(date +%s) + 60*30 ))
    # convert epoch to alert manager compatible datetime:
    # $(date --date="@$epochstring" -u "+%Y-%m-%dT%H:%M:%SZ")
    true
}

unmute_alerts() {
    # get silenceId from /app/etc/tags/silenceId or noop
    # DELETE
    # http://localhost:9093/api/v1/silence/1e452199-cabc-47d7-a84e-a5acc0b8855f
    true
}


manual_metric() {
    local outputname
    outputname=$(mktemp -p /app/prometheus/metric_import -u manual_job_XXXX.prom)
    printf "%s" "$1" > ${outputname}.$$
    mv ${outputname}.$$ ${outputname}
}

simple_metric() {
    # call with $1=id , $2=type , $3=help , $4=value [,$5=timestamp-epoch]
    # make $5 (timestamp-epoch) the current time by using $(date +%s)
    # type can be one of "counter, gauge, untyped"
    # value if float but can take "Nan", ""+Inf", and ""-Inf" as valid values
    local data
    data="
# HELP $1 $3
# TYPE $1 $2
$1 $4 $5
"
    manual_metric $data
}
