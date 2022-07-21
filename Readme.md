# EspoCRM containers for development

OCI compatible containers and configurations for EspoCRM development environment.

## setup

```bash
# create root directory that will be opened in IDE
mkdir -p ./espodev/extensions
cd ./espodev

# clone container stack
git clone https://github.com/superewald/espo-dev-stack stack

# clone espocrm
git clone https://github.com/espocrm/espocrm

# clone extensions
## git clone <git-url> extensions/<extension>

# build container
./stack/compose build
```