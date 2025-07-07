resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/elixir-app" # Match this with your logConfiguration options
  retention_in_days = 7                 # Optional
}

