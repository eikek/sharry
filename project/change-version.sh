#!/usr/bin/env bash

set -e

cd "$(dirname $0)/.."

edit_version() {
    file="$1"
    old="$2"
    new="$3"

    sed -i "s/$old/$new/g" $file
}

current_version() {
    cat "version.sbt" | head -n1 | cut -d'=' -f2 | xargs
}

curr="$(current_version)"

if [ -z "$1" ]; then
    echo "No new version given!"
    exit 1
fi

edit_version "version.sbt" "$curr" "$1"
edit_version "modules/restapi/src/main/resources/sharry-openapi.yml" "$curr" "$1"
edit_version "nix/meta.nix" "$curr" "$1"
