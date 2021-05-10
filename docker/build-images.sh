#!/usr/bin/env bash

set -e

docker build -t eikek0/sharry:1.7.1 -f sharry.dockerfile .
docker tag eikek0/sharry:1.7.1 eikek0/sharry:latest
