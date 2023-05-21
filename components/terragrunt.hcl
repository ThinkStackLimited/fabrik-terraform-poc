locals {
  environment        = get_env("TG_ENVIRONMENT", "")
  environments       = get_env("TG_ENVIRONMENTS", "{}")
  github_org         = "ThinkStackLimited"
  terraform_version  = file("../.terraform-version")
  terragrunt_version = file("../.terragrunt-version")
  tfstate_key        = "${path_relative_to_include()}/terraform.tfstate"

  tags = {
    environment        = local.environment
    terragrunt_version = trimspace("v${local.terragrunt_version}")
    terraform_version  = trimspace("v${local.terraform_version}")
  }
}

remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "bootstrap"
    storage_account_name = "fabrikbootstrap"
    container_name       = "terraform-state"
    key                  = local.tfstate_key
  }
  generate = {
    path      = "remote_state.tf"
    if_exists = "overwrite"
  }
}

generate provider {
  path      = "temp_providers.tf"
  if_exists = "overwrite"
  contents  = file("../.providers.tf")
}

inputs = {
  environment        = local.environment
  environments       = local.environments
  github_org         = local.github_org
  terraform_version  = local.terraform_version
  terragrunt_version = local.terragrunt_version
  tags               = local.tags
}

# Customise terraform
terraform {
  extra_arguments disable_input {
    commands  = get_terraform_commands_that_need_input()
    arguments = ["-input=false"]
  }
}
