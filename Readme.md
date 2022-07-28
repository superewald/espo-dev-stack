# EspoCRM containers for development

Containers and configuration for a local espocrm specific development environment. 

## features

- handle the whole EspoCRM installation within one top level directory
- easely add and remove extensions from source or zip
- allows parallel development of multiple extensions

## prerequisites

The following sofware is needed to use this stack:

1. [Docker] or [Podman] (>= 4.0) with [netavark] and [aardvark-dns]
1. [docker-compose] or [podman-compose] (latest development)
1. php (>= 7.3)
1. nodejs (>= 14) & npm

> NOTE: If you are using podman you have to create symlinks for docker "alias":
> ```bash
> sudo ln -s /usr/bin/docker /usr/bin/podman
> ln -s $HOME/.local/bin/docker-compose $HOME/.local/bin/podman-compose
> ```

## setup

It is recommended to use the [install script]() which creates the local stack for you. Run the script and follow the instructions.

```
wget -qO- https://raw.githubusercontent.com/superewald/espo-dev-stack/main/install.sh | bash
```

After executing the install script the EspoCRM stack is ready to be run. 

You might want to configure/install your espocrm app now, simply start the containers (`./stack/compose up -d`) and head to [localhost:8080/install](http://localhost:8080/install).

## containers

There is a little helper script for container management located at `./stack/compose`. It is a simple wrapper to podman-compose so you can pass the same arguments.

- **start containers**: `./stack/compose up -d`
- **stop containers**: `./stack/compose down`
- **build containers**: `./stack/compose build`

## application data

EspoCRM and Mysql data is stored at `./data` with the following structure:

- `espo/` data of espocrm
    - `client/custom/`: custom client data
    - `custom/`: custom app data
    - `data/`: espocrm data (config, logs, cache)
- `mysql/` data of mysql

If you want to reinstall/reconfigure your application you should remove the data folder (`rm -r ./data`)!

[Docker]: https://www.docker.com/
[docker-compose]: https://docs.docker.com/compose/
[Podman]: https://podman.io/
[podman-compose]: https://github.com/containers/podman-compose
[netavark]: https://github.com/containers/netavark
[aardvark-dns]: https://github.com/containers/aardvark-dns