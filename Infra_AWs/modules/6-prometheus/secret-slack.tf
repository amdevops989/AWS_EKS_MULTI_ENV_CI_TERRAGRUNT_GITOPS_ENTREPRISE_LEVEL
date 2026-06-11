

resource "null_resource" "alertmanager_slack" {
  triggers = {
    always_run = timestamp()
    slack_url  = var.slack_webhook_url
  }
  provisioner "local-exec" {
    command = <<EOT
      tmpfile=$(mktemp)
      echo '${templatefile("${path.module}/alertmanager-slack.yaml.tpl", { slack_webhook_url = var.slack_webhook_url })}' > $tmpfile
      kubectl apply -f $tmpfile
      rm -f $tmpfile
    EOT
    interpreter = ["/bin/bash", "-c"]
  }


  depends_on = [ kubernetes_namespace.monitoring]
}