FROM alpine:latest

LABEL maintainer="eikek0 <news@eknet.org>"

RUN apk add --no-cache openjdk11-jre unzip curl bash

RUN mkdir -p /opt \
  && cd /opt \
  && curl -L -o sharry.zip https://github.com/eikek/sharry/releases/download/v1.8.0/sharry-restserver-1.8.0.zip \
  && unzip sharry.zip \
  && rm sharry.zip \
  && apk del unzip curl

EXPOSE 9090

ENTRYPOINT ["/opt/sharry-restserver-1.8.0/bin/sharry-restserver"]
