# ──────────────────────────────────────────────────────────
# CloudWatch Dashboard (opcional pero útil para monitoreo)
# ──────────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 12
        height = 6
        properties = {
          title  = "DLQ - Mensajes visibles"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [[
            "AWS/SQS",
            "ApproximateNumberOfMessagesVisible",
            "QueueName", var.sqs_dlq_name
          ]]
          period = 60
          stat   = "Maximum"
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width  = 12
        height = 6
        properties = {
          title  = "Cola principal - Mensajes en cola"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [[
            "AWS/SQS",
            "ApproximateNumberOfMessagesVisible",
            "QueueName", var.sqs_queue_name
          ]]
          period = 60
          stat   = "Maximum"
        }
      }
    ]
  })
}
