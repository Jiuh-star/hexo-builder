# hexo-builder

A simple container build script of [Hexo](https://hexo.io/zh-cn/) with theme [Butterfly](https://butterfly.js.org/).

## Requirements

- [Podman](https://podman.io/)
- [Buildah](https://buildah.io/)
- [Git](https://git-scm.com/)

## How to use

```bash
chmod +x build.sh

# Modified build.sh to meet your requirement
./build.sh

# Waiting for building an image...
# Some volume point generated at $PWD
# Modified _config.yml and _config.butterfly.yml to finish your configuration

# Create a new container if not exists & make some management commands
source activate

# Generate, deploy & run Hexo at http://localhost:4000, Qexo at 4001,
# Twikoo at 4002 by default. Logging are saved at var/
start-blog-server

# Restart blog server if config file changed
restart-blog-server

# You can run a single server in foreground for debugging
run-hexo-server
```
