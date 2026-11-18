# These repositories are created empty. Build and push images to them before deploying the Frontend
# and Actions ECS services — see the root README.md for the build/push commands.

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.name}-frontend"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.name}-frontend" }
}

resource "aws_ecr_repository" "actions" {
  name                 = "${var.name}-actions"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.name}-actions" }
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "actions" {
  repository = aws_ecr_repository.actions.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
