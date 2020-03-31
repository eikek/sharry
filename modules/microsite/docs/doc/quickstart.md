---
layout: docs
title: Quickstart
permalink: doc/quickstart
---

# Quickstart

To quickly try out sharry, follow these steps:

1. Download a zip (version @VERSION@) from the [release
   page](https://github.com/eikek/sharry/releases).
   - e.g. [sharry-restserver-@VERSION@.zip](https://github.com/eikek/sharry/releases/download/release%2F@VERSION@/sharry-restserver-@VERSION@.zip)
2. Unpack it to some place.
   ```bash
   $ unzip sharry-restserver-@VERSION@.zip
   ```
3. Run the executable:
   ```bash
   $ /path/to/extracted-zip/bin/sharry-restserver
   ```
4. Goto <http://localhost:9090/>, signup and login

If you want to know more, for example what can be
[configured](configure), checkout these pages.


# Quickstart with Docker

There is a [docker-compose](https://docs.docker.com/compose/) setup
available in the `/docker` folder.

1. Clone the github repository
   ```bash
   $ git clone https://github.com/eikek/sharry
   ```
2. Change into the `docker` directory:
   ```bash
   $ cd sharry/docker
   ```
3. Run `docker-compose up`:
   ```bash
   $ docker-compose up
   ```
4. Goto <http://localhost:9090/>, signup and login

The directory contains a file `sharry.conf` that you can
[modify](configure) as needed.
