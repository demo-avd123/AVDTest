# ===================================================================
# TERRAFORM CLOUD BACKEND
# ===================================================================
# This repo is configured for Terraform Cloud workspace-driven runs.
#
# Inputs:
#   - Set Terraform variables in the Terraform Cloud workspace UI.
#   - Do not store real values in terraform.tfvars when using TFC.
#
# Backend setup:
#   1. Replace <YOUR_TFC_ORG> with your Terraform Cloud organization.
#   2. Replace <YOUR_TFC_WORKSPACE_NAME> with your existing workspace.
#   3. Run: terraform login
#   4. Run: terraform init
#
# VCS-driven workspace setup:
#   1. Push this Terraform code to your GitHub repository.
#   2. In Terraform Cloud, create or update a workspace using
#      Version Control Workflow.
#   3. Connect the workspace to the GitHub repository.
#   4. If the repo root contains parent folders, set the workspace
#      Working Directory to the folder that contains this file.
#   5. Keep using Terraform Cloud workspace variables for all inputs.
#
# This folder is the Terraform root for the deployment.
# Sensitive values must be marked Sensitive in Terraform Cloud.
# ===================================================================

terraform {
  cloud {
    organization = "<YOUR_TFC_ORG>"

    workspaces {
      name = "<YOUR_TFC_WORKSPACE_NAME>"
    }
  }
}
