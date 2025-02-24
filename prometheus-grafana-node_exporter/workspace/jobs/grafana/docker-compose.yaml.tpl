version: "3.3"

services:
  grafana:
    image: grafana/grafana

    ports:
      - 3000:3000
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER={{(get "vars/job/grafana" "grafana_admin_user")}}
      - GF_SECURITY_ADMIN_PASSWORD={{(get "vars/job/grafana" "grafana_admin_password")}}
    volumes:
      - ./datasources:/etc/grafana/provisioning/datasources