sharry
======

Sharry allows to share files with others in a simple way. It is a
self-hosted web application. The basic concept is: upload files and get
a url back that can then be shared.

<a href="https://travis-ci.org/eikek/sharry"><img src="https://travis-ci.org/eikek/sharry.svg"></a>
<a href="https://xkcd.com/949/"><img height="400" align="right" style="float:right" src="https://imgs.xkcd.com/comics/file_transfer.png"></a>

How it works
------------

### Authenticated users -&gt; others

Authenticated users can upload their files on a web site together with
an optional password and a time period. The time period defines how long
the file is available for download. Then a public URL is generated that
can be shared, e.g. via email.

The download page is hard to guess, but open to everyone.

### Others -&gt; Authenticated users

Anonymous can send files to registered ones. Each registered user can
maintain alias pages. An alias page is behind a “hard-to-guess” URL
(just like the download page) and allows everyone to upload files to the
corresponding user. The form does not allow to specify a password or
validation period, but a description can be given. The user belonging to
the alias can be notified via email.

### Others -&gt; Others

If authentication is enabled, it is not possible to share files between
non-registered users. One party must be registered. But authentication
can be completely disabled. Then any user can upload files. This may be
useful within a closed network.

Upload and Download
-------------------

Sharry aims to provide a good support for large files. That means
downloads and uploads are resumable. Large files can be downloaded via
[byte serving](https://en.wikipedia.org/wiki/Byte_serving), which allows
for example to watch video files directly in the browser. Uploads are
resumable, too, by using
[resumable.js](https://github.com/23/resumable.js) on the client.
Uploads can be retried where only chunks not already at the server are
transferred.

Each published upload has a validity period, after which the public
download page doesn't work anymore. A cleanup job running periodically
can delete those files to save space.

Features
--------

-   resumable and recoverable upload of multiple files; thanks to
    [resumable.js](https://github.com/23/resumable.js)
-   validation period for uploads
-   resumable downloads using [byte
    serving](https://en.wikipedia.org/wiki/Byte_serving)
-   download single files or all in a zip
-   protect downloads with a password
-   automatic removal of invalid uploads
-   external authentication (via system command or http requests)
-   managing accounts, uploads and alias pages

Try it
------

There is a demo installation at <https://sharrydemo.eknet.org>. It
doesn't require authentication, everyone acts as the same user. The mail
feature is not enabled and uploads are restricted to 500K.

Or, clone this project and use sbt (see below for prerequisites) to
compile and run:

``` {.shell .rundoc-block rundoc-language="shell" rundoc-exports="both"}
sbt run-sharry
```

This will build the project and start the server. Point your browser to
<http://localhost:9090> and login with user `admin` and password
`admin`.

Documentation
-------------

There is a user manual in the [./docs](./docs) folder (sources). These
pages are shown in each sharry instance, for example
[here](https://sharrydemo.eknet.org/#manual/index.md).

Building
--------

You need Java8, [sbt](http://scala-sbt.org) and
[Elm](http://elm-lang.org/) installed first. Then clone the project and
run:

``` {.shell .rundoc-block rundoc-language="shell" rundoc-exports="both"}
sbt make
```

This creates a file in `modules/server/target/scala-2.12` named
`sharry-*.jar.sh`. This is an executable jar file and can be used to run
sharry:

The `--console` argument allows to terminate the server from the
terminal (otherwise it's `Ctrl-C`). By default a
[H2](http://h2database.com) database is configured in the current
working directory.

``` {.shell .rundoc-block rundoc-language="shell" rundoc-exports="both"}
$ ./modules/server/target/scala-2.12/sharry-server-0.0.1-SNAPSHOT.jar.sh --console
2017-05-08T14:53:07.345+0200 INFO [main] sharry.server.main$ [main.scala:36]
––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
 Sharry 0.0.1-SNAPSHOT (build 2017-05-08 12:49:58UTC) is starting up …
––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
2017-05-08T14:53:08.563+0200 INFO [main] sharry.server.main$ [main.scala:42]
––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
 • Running initialize tasks …
––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
2017-05-08T14:53:08.622+0200 INFO [main] com.zaxxer.hikari.HikariDataSource [HikariDataSource.java:93] HikariPool-1 - Started.
2017-05-08T14:53:09.272+0200 INFO [main] sharry.server.main$ [main.scala:62]
––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
 • Starting http server at 0.0.0.0:9090
––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
Hit RETURN to stop the server
```

Dependencies
------------

The server part is written in [Scala](http://scala-lang.or) and uses the
following great libraries:

-   [fs2](https://github.com/functional-streams-for-scala/fs2) all the
    way
-   [fs2-http](https://github.com/Spinoco/fs2-http) for the http stack
-   [doobie](https://github.com/tpolecat/doobie) for db access (which
    uses fs2, too)
-   [circe](https://github.com/circe/circe) great library for json
-   [pureconfig](https://github.com/pureconfig/pureconfig) is reading
    the configuration file using
    [config](https://github.com/typesafehub/config) library
-   …

See all of them in the [libs](./project/libs.scala) file.

The frontend is written in [Elm](http://elm-lang.org/). Two libraries
aside from `elm-lang/*` are used:

-   [evancz/elm-markdown](https://github.com/evancz/elm-markdown)
    rendering markdown
-   [NoRedInk/elm-decode-pipeline](https://github.com/NoRedInk/elm-decode-pipeline)
    decoding json

Non-elm components:

-   [semantic-ui](https://semantic-ui.com) for a well looking web
    interface
-   [resumable.js](https://github.com/23/resumable.js) for handling
    uploads at the client

Configuring
-----------

Sharry reads a configuration file that can be given as an argument to
the executable. Please see the
[default](./modules/server/src/main/resources/reference.conf)
configuration for all available options and their default values. It
also contains hopefully helpful comments.

For more detailed information on its syntax, please refer to the
[specification](https://github.com/typesafehub/config/blob/master/HOCON.md)
and documentation of [config
library](https://github.com/typesafehub/config).

The important settings are

-   `sharry.web.bindHost` and `sharry.web.bindPort` the host and port
    for binding the http server
-   `sharry.web.baseurl` this must be set to the external base url. So
    if the app is at <http://example.com/>, then it should be set to
    this value. It is used to restrict the authentication cookie and to
    create links in the web application. Please note, that currently a
    trailing slash must be used in order to make it parse (this will
    change in the future).
-   `sharry.db.driver|user|url|password` the JDBC settings; currently it
    should work with postgres and h2
-   `sharry.upload.max-file-size` maximum file size to upload
-   `sharry.authc.enable=true|false` whether to enable authentication
    (default is `true`)
-   `sharry.authc.extern.admin.enable=true|false` enables an admin
    account for initial login (password is `admin`), default is `false`

Every setting can also be given as a Java system property by adding it
to the environment variable `SHARRY_JAVA_OPTS` (`-D` prefix is required
here):

``` {.shell .rundoc-block rundoc-language="shell" rundoc-exports="both"}
SHARRY_JAVA_OPTS="-Dsharry.authc.enable=false" ./sharry-server-0.0.1-SNAPSHOT.jar.sh
```

This overrides same settings in the configuration file.

### Reverse Proxy

When running behind a reverse proxy, it is importand to use HTTP 1.1.
For example, a minimal nginx config would look like this:

``` {.conf .rundoc-block rundoc-language="conf" rundoc-exports="both"}
server {
  listen 0.0.0.0:80;

  proxy_request_buffering off;
  proxy_buffering off;

  location / {
     proxy_pass http://127.0.0.1:9090;
     # this is important, because fs2-http can only do 1.1
     # and it effectively disables request_buffering
     proxy_http_version 1.1;
  }
}
```
