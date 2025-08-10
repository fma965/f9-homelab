NAS deployment
```yaml
version: '3.4'
services:
  ser2net:
    container_name: ser2net
    image: ghcr.io/jippi/docker-ser2net
    restart: unless-stopped
    network_mode: host
    volumes:
      - /mnt/user/appdata/ser2net.yaml:/etc/ser2net/ser2net.yaml
    devices:
      - /dev/ttyUSB0
```