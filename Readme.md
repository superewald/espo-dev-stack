# EspoCRM containers for development

Containers and configuration for a local espocrm specific development environment. 

## features

- handle the whole EspoCRM installation within one top level directory
- easely add and remove extensions from source or zip
- allows parallel development of multiple extensions

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