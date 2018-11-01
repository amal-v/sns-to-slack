# Common Variables
variable "region" {
  description = "AWS region to deploy"
}

variable "environment" {
  description = "Specify the environment - dev/stg/prod"
}

#Lambda variables 
variable "slack_web_hook" {
  description = "Slack Web Hook to send alert notifications "
}

variable "channel_name" {
  description = "Slack Channel Name to push alert notifications "
}

variable "project" {

    description = "Name of the project"
  
}