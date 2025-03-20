resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = var.s3_tfstate.bucket
    #lifecycle { Removed so can be deleted with not manual intervention
    #prevent_destroy = true
 #}
}

resource "aws_s3_bucket_versioning" "tfstate_bucket" {
    bucket = aws_s3_bucket.tfstate_bucket.id

    versioning_configuration {
      status = "Enabled"
    }
}

output "TFSTATE_BUCKET_NAME" {
  value = aws_s3_bucket.tfstate_bucket.bucket
}