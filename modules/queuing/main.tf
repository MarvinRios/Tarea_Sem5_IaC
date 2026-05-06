# ──────────────────────────────────────────────────────────
# Dead Letter Queue
# ──────────────────────────────────────────────────────────
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name_prefix}-image-dlq"
  message_retention_seconds = 1209600 # 14 días

  tags = { Name = "${var.name_prefix}-image-dlq" }
}

# ──────────────────────────────────────────────────────────
# Cola Principal
# ──────────────────────────────────────────────────────────
resource "aws_sqs_queue" "main" {
  name                       = "${var.name_prefix}-image-queue"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = 86400  # 1 día
  receive_wait_time_seconds  = 20     # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Name = "${var.name_prefix}-image-queue" }
}

# ──────────────────────────────────────────────────────────
# SNS Topic para notificaciones de alarma
# ──────────────────────────────────────────────────────────
resource "aws_sns_topic" "dlq_alarm" {
  name = "${var.name_prefix}-dlq-alarm-topic"
  tags = { Name = "${var.name_prefix}-dlq-alarm-topic" }
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.dlq_alarm.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ──────────────────────────────────────────────────────────
# CloudWatch Alarm: mensajes visibles en DLQ
# Threshold: > 0 mensajes → dispara alarma
# ──────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.name_prefix}-dlq-messages-alarm"
  alarm_description   = "Alarma: hay mensajes en la Dead Letter Queue. Revisar procesamiento de imágenes."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.dlq_alarm.arn]
  ok_actions    = [aws_sns_topic.dlq_alarm.arn]

  tags = { Name = "${var.name_prefix}-dlq-alarm" }
}
