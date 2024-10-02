# S3 bucket where CML images will be stored

resource "aws_s3_bucket" "s3_cml" {
  bucket = "phcmlimages"
  #force_destroy = true
}




