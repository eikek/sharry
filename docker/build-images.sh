#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Please specify a version"
    exit 1
fi

version="$1"
if [[ $version == v* ]]; then
    version="${version:1}"
fi

push=""
if [ -z "$2" ] || [ "$2" == "--push" ]; then
    push="$2"
    if [ ! -z "$push" ]; then
        echo "Running with $push !"
    fi
else
    echo "Don't understand second argument: $2"
    exit 1
fi

if ! docker buildx version > /dev/null; then
    echo "The docker buildx command is required."
    echo "See: https://github.com/docker/buildx#binary-release"
    exit 1
fi

set -e
cd "$(dirname "$0")"

trap "{ docker buildx rm sharry-builder; }" EXIT

platforms="linux/amd64,linux/aarch64,linux/arm/v7"
docker buildx create --name sharry-builder --use

if [[ $version == *SNAPSHOT* ]]; then
    echo ">>>> Building nightly images for $version <<<<<"
    url_base="https://github.com/eikek/sharry/releases/download/nightly"

    echo "============ Building Sharry ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg sharry_url="$url_base/sharry-restserver-$version.zip" \
           --tag eikek0/sharry:nightly \
           -f sharry.dockerfile .
else
    echo ">>>> Building release images for $version <<<<<"

    echo "============ Building Sharry ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg version=$version \
           --tag eikek0/sharry:v$version \
           --tag eikek0/sharry:latest \
           -f sharry.dockerfile .
fi
