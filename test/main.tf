
resource "local_file" "foo" {
    content  = local.secret_file_builder
    filename = "secrets.env"
}


locals {

  secret_file_builder = ""

}