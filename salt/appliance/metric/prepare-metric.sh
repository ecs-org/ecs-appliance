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
