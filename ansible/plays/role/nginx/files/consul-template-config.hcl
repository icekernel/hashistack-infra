template {
  source      = "/etc/consul-template/templates/nginx-default.ctmpl"
  destination = "/etc/nginx/sites-available/default"
  command     = "systemctl reload nginx"
}