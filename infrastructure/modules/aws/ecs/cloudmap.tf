resource "aws_service_discovery_private_dns_namespace" "ecs" {
  name        = "internal"
  description = "ECS internal service discovery namespace"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "elixir" {
  name = "elixir-app"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs.id
    dns_records {
      type = "SRV"
      ttl  = 60
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

