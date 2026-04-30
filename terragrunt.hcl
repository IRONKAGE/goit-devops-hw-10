remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "ironkage-tf-state-hw89-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-hw89"
  }
}
inputs = {
  project_name = "ironkage-k8s-hw89"
  region       = "eu-central-1"
}
