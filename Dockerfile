FROM alpine:latest

RUN apk update update && \
apk add hugo supervisor nginx && \
mkdir /home/devopsclub && \
mkdir /run/nginx/ && \
/usr/bin/hugo new site  /home/devopsclub && \
rm /etc/nginx/conf.d/default.conf && \
rm -rf /var/cache/apk/* 

COPY files/nginx/gohugo.conf /etc/nginx/conf.d/gohugo.conf 
COPY files/gohugo/minimal /home/devopsclub/themes/minimal
COPY files/gohugo/minimal/devopsclub/ /home/devopsclub/
COPY files/supervisor/ /etc/supervisor/conf.d/

EXPOSE 80
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
