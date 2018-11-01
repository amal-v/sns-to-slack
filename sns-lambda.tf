provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.project}-${var.environment}_iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name = "${var.project}-${var.environment}-sns-iam-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Action": [
                "logs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${dirname("${path.module}/lambda-src/")}"
  output_path = "/tmp/slacknotifier.zip"
}

resource "aws_lambda_function" "slack_notifier_lambda" {
  filename         = "${data.archive_file.lambda_zip.output_path}"
  function_name    = "${var.project}-${var.environment}_slack_notifier"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs8.10"

  environment {
    variables {
      slack_web_hook = "${var.slack_web_hook}"
      channel_name  = "${var.channel_name}"
    }
  }
}

resource "aws_sns_topic" "sns_topic" {
  name = "${var.project}-${var.environment}_aws-alarm-topic"
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  depends_on = ["aws_sns_topic.sns_topic"]
  topic_arn  = "${aws_sns_topic.sns_topic.arn}"
  protocol   = "lambda"
  endpoint   = "${aws_lambda_function.slack_notifier_lambda.arn}"
}

resource "aws_lambda_permission" "lambda_invoke_permission" {
  statement_id        = "AllowExecutionFromSNS"
  action              = "lambda:InvokeFunction"
  function_name       = "${aws_lambda_function.slack_notifier_lambda.function_name}"
  principal           = "sns.amazonaws.com"
  source_arn          = "${aws_sns_topic.sns_topic.arn}"
}
