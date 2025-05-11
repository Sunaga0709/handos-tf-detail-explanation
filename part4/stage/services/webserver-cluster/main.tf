provider "aws" {
  region = "ap-northeast-1"
}

# terraform {
#   backend "s3" {
#     bucket = "sunaga-terraform-up-and-running-state"
#     key    = "global/s3/terraform.tfstate"
#     region = "ap-northeast-1"
#
#     dynamodb_table = "sunaga-terraform-up-and-running-locks"
#     encrypt        = true
#   }
# }

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}
