
resource "aws_s3_bucket" "s3_net_day" {
  bucket = "networking-day"
}

/*
resource "aws_s3_bucket_policy" "net_imm_day_test" {
    bucket = aws_s3_bucket.s3_net_day.id
    policy = jsonencode({
    Version = "2012-10-17"
    Id      = "MYBUCKETPOLICY"
    Statement = [
      {
        Sid       = "IPAllow"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:DeleteObject", "s3:PutObject"]
        Resource  = "${aws_s3_bucket.b.arn}/*"
      },
    ]
  })
}
*/

