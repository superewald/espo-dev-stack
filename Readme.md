# EspoCRM containers for development

OCI compatible containers and configurations for EspoCRM development environment.

## setup

```bash
# create root directory that will be opened in IDE
mkdir -p ./espodev/extensions
cd ./espodev

# clone container stack
git clone https://github.com/superewald/espo-dev-stack stack

# build container
./stack/compose build

# clone espocrm
git clone https://github.com/espocrm/espocrm

# install espocrm dependencies & run internal build
cd ./stack
composer install
npm install
grunt internal
cd ../

# clone extensions
## git clone <git-url> extensions/<extension>

```