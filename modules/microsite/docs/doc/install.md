---
layout: docs
title: Installation
permalink: doc/install
---

# {{ page.title }}

This page contains detailed installation instructions. For a quick
start, refer to [this page](quickstart).

Sharry is a *REST Server* that also provides the web application. The
web application runs in the browser and talks to the server using the
[REST Api](rest).

The [download page](https://github.com/eikek/sharry/releases)
provides pre-compiled packages and the [development page](dev.html)
contains build instructions.


## Prerequisites

### Java

Very often, Java is already installed. You can check this by opening a
terminal and typing `java -version`. Otherwise install Java using your
package manager or see [this site](https://adoptopenjdk.net/) for
other options.

It is enough to install the JRE. The JDK is required, if you want to
build sharry from source.

Sharry has been tested with Java version 1.8 (or sometimes referred
to as JRE 8 and JDK 8, respectively). The pre-build packages are also
build using JDK 8. But a later version of Java should work as well.


## Database

Sharry stores all its information (files, accounts etc) in a database.
The following products are supported:

- PostreSQL
- MariaDB
- H2

The H2 database is an interesting option for personal and mid-size
setups, as it requires no additional work (i.e. no separate db
server). It is integrated into sharry and works really well. It is
also configured as the default database.

For large installations, PostgreSQL or MariaDB is recommended. Create
a database and a user with enough privileges (read, write, create
table) to that database.

When using H2, make sure to add the options
`;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE` at the end of the url. See
the [default config](configure.html) for an example.


## Installing from ZIP files

After extracting the zip files, you'll find a start script in the
`bin/` folder.


## Installing from DEB packages

The DEB packages can be installed on Debian, or Debian based Distros:

``` bash
$ sudo dpkg -i sharry*.deb
```

Then the start scripts are in your `$PATH`. Run `sharry-restserver`
from a terminal window.

The packages come with a systemd unit file that will be installed to
autostart the services.


## Running

Run the start script (in the corresponding `bin/` directory when using
the zip files):

```
$ ./sharry-restserver*/bin/sharry-restserver
```

This will startup using the default configuration. The configuration
should be adopted to your needs. For example, the database connection
is configured to use a H2 database that is created in the `/tmp`
directory. Please refer to the [configuration page](configure)
for how to create a custom config file. Once you have your config
file, simply pass it as argument to the command:

```
$ ./sharry-restserver*/bin/sharry-restserver /path/to/server-config.conf
```

After starting the rest server, you can reach the web application at
path `/app`, so using default values it would be
`http://localhost:9090/app`.

You should be able to create a new account and sign in.


### Options

The start scripts support some options to configure the JVM. One often
used setting is the maximum heap size of the JVM. By default, java
determines it based on properties of the current machine. You can
specify it by given java startup options to the command:

```
$ ./sharry-restserver*/bin/sharry-restserver -J-Xmx1G -- /path/to/server-config.conf
```

This would limit the maximum heap to 1GB. The double slash separates
internal options and the arguments to the program. Another frequently
used option is to change the default temp directory. Usually it is
`/tmp`, but it may be desired to have a dedicated temp directory,
which can be configured:

```
$ ./sharry-restserver*/bin/sharry-restserver -J-Xmx1G -Djava.io.tmpdir=/path/to/othertemp -- /path/to/server-config.conf
```

The command:

```
$ ./sharry-restserver*/bin/sharry-restserver -h
```

gives an overview of supported options.


### System properties

All options that are given with `-D` are called system properties.
These can be used to overwrite certain configuration values. System
properties always take precedence over values defined in config files.

This can be handy to temporarily change some configuration, for
example, enable the fixed admin account like this:

```
$  ./sharry-restserver*/bin/sharry-restserver -Dsharry.restserver.backend.auth.fixed.enabled=true -- /path/to/server-config.conf
```
