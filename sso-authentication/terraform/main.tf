resource null_resource create-application-assignment {
  triggers = {
    trigger = value
  }

  provisioner "local-exec" {
    command = "aws sso-admin create-account-assignment "
  }
}
