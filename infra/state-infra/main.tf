#Default backend as is rquired.
terraform {
  backend "s3" {}
}

module "s3bucket" {
  source     = "./s3bucket"
  s3_tfstate = var.s3_tfstate
}