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

## setup

It is recommended to use the [install script]() which creates the local stack for you. Run the script and follow the instructions.

```
bash <(wget -qO- https://raw.githubusercontent.com/superewald/espo-dev-stack/main/install.sh)
```

After executing the install script the EspoCRM stack is ready to be run. 

## containers

There is a little helper script for container management located at `./compose`. It is a simple wrapper to podman-compose so you can pass the same arguments.

- **start containers**: `./compose up -d`
- **stop containers**: `./compose down`
- **build containers**: `./compose build`

## development

The environment is configured to serve the recent changes of your source directories (`espocrm/` and `extensions/**`).

It is recommended to open the top level directory inside VSCode/VSCodium for a nice IDE setup!

### espocrm

EspoCRM is located inside the `espocrm/` folder. Just follow the official [development guide]() for EspoCRM.

### extensions

Extensions for EspoCRM are located in `extensions/` and can be either an 

- extension zip package 
- source folder with structure of [official extension template](https://github.com/espocrm/espo-ext-template)
- source folder with structure of [superewald's extension template](https://github.com/superewald/espo-ext-template)

Just stick to the according documentation.

The containers are configured to install the extensions and handle updates.

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