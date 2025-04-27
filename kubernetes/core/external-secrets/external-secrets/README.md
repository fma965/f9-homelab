# external-secrets

## NAS Deployments

### onepassword-connect

```yaml
services:
  onepassword-connect-api:
    container_name: onepassword-connect-api
    image: 1password/connect-api:1.7.3
    environment:
      XDG_DATA_HOME: /config
    env_file: ./.env
    ports:
      - "8080:8080"
    volumes:
      - data:/config
  onepassword-connect-sync:
    container_name: onepassword-connect-sync
    image: 1password/connect-sync:1.7.3
    environment:
      XDG_DATA_HOME: /config
    env_file: ./.env
    ports:
      - "8081:8080"
    volumes:
      - data:/config

volumes:
  data:
    driver: local
    driver_opts:
      device: tmpfs
      o: uid=999,gid=999
      type: tmpfs
```
