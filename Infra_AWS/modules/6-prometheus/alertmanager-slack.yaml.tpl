apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-slack
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    route:
      receiver: slack-main
      group_by: ['alertname']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 1h
    receivers:
      - name: slack-main
        slack_configs:
          - channel: "#devops"
            send_resolved: true
            username: "AlertManager"
            icon_emoji: ":warning:"
            api_url: "${slack_webhook_url}"
