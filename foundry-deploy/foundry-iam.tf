resource "aws_iam_user" "foundry" {
  name = "foundry"
}
resource "aws_iam_access_key" "foundry" {
  user = aws_iam_user.foundry.name
}
data "aws_iam_policy_document" "foundry" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${var.foundry_bucket_name}",
      "arn:aws:s3:::${var.foundry_bucket_name}/*",
    ]
  }
  statement {
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }

}
resource "aws_iam_user_policy" "foundry" {
  name   = "foundry-s3-policy"
  user   = aws_iam_user.foundry.name
  policy = data.aws_iam_policy_document.foundry.json
}