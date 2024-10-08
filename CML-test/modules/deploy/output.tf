
output "public_ip" {
  value = (
    (var.cfg.target == "aws") ?
    module.aws[0].public_ip :
      "127.0.0.1"
    )
}