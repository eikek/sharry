#!/usr/bin/env bash

set -e

docker build -t eikek0/sharry:1.5.0 -f sharry.dockerfile .
docker tag eikek0/sharry:1.5.0 eikek0/sharry:latest
