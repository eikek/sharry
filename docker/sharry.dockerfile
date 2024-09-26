FROM alpine:latest

LABEL maintainer="eikek0 <news@eknet.org>"

ARG version=
ARG sharry_url=
ARG TARGETPLATFORM

RUN apk -U add --no-cache openjdk17 tzdata unzip curl bash

WORKDIR /opt

RUN curl -L -o sharry.zip ${sharry_url:-https://github.com/eikek/sharry/releases/download/v$version/sharry-restserver-$version.zip} \
  && unzip sharry.zip \
  && rm sharry.zip \
  && ln -snf sharry-restserver-* sharry

RUN addgroup -S user -g 10001 && \
    adduser -SDH user -u 10001 -G user
USER 10001

EXPOSE 9090
ENTRYPOINT ["/opt/sharry/bin/sharry-restserver"]

HEALTHCHECK --interval=1m --timeout=10m --retries=2 --start-period=30s \
  CMD wget --spider http://localhost:9090/api/v2/open/info/version
