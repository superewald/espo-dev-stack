FROM webdevops/php-apache:8.0

ARG NODE_VERSION=16.16.0

# install nodejs, npm, grunt
RUN export NODE_VER=$(curl -s https://nodejs.org/en/ | grep -Po '\d*\.\d*\.\d* LTS' | head -n1 | cut -f1 -d' ') && \
    curl https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-linux-x64.tar.xz    | tar --file=- --extract --xz --directory /usr/local/ --strip-components=1 && \
    npm install -g grunt-cli

# install wkhtmltopdf
RUN apt update && apt install -y wkhtmltopdf sed jq inotify-tools

RUN mkdir -p /home/espo/scripts
COPY ./scripts /home/espo/scripts

# configure crontab
COPY ./scripts/espo-cron /etc/cron.d/espo-cron
COPY ./conf /opt/docker

# set httpd to listen on 8080 instead of 80 and 4443 instead of 443 (rootless support)
#RUN sed -i 's/*:80/*:8080/' /opt/docker/etc/httpd/vhost.conf && \
#    sed -i 's/*:443/*:4443/' /opt/docker/etc/httpd/vhost.conf

RUN chmod 0644 /etc/cron.d/espo-cron && \
    crontab /etc/cron.d/espo-cron