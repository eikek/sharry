---
layout: docs
title: Development
permalink: doc/dev
---

# {{ page.title }}

## Building

[Sbt](https://scala-sbt.org) is used to build the application. Clone
the sources, start `sbt` in the source root and run inside the sbt
shell:

- `make` to compile all sources (Elm + Scala)
- `make-zip` to create zip packages
- `make-deb` to create debian packages
- `make-pkg` to run a clean compile and create both packages

The zip file can be found afterwards in:

```
modules/restserver/target/universal/
```

The `deb` file is in
```
modules/restserver/target/
```

## Starting Servers with `reStart`

When developing, it's very convenient to use the [revolver sbt
plugin](https://github.com/spray/sbt-revolver). Start the sbt console
and then run:

```
sbt:sharry-root> restserver/reStart
```

This starts a REST server. Prefixing the commads with `~`, results in
recompile+restart once a source file is modified.

Note that with current sbt the revolver plugin will not restart the
server if elm files are changed. But this is not really necessary:
just run a second sbt shell with `~ compile` and sbt will *compile*
all elm files on change and the final js file is immediately
available. Only a browser refresh is necessary to load the new web
app.

## Custom config file

The sbt build is setup such that a file `local/dev.conf` (from the
root of the source tree) is picked up as config file, if it exists. So
you can create a custom config file for development. For example, a
custom database for development may be setup this way:

```
#jdbcurl = "jdbc:h2:///home/dev/workspace/projects/sharry/local/sharry-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"
#jdbcurl = "jdbc:mariadb://localhost:3306/sharrydev"
jdbcurl = "jdbc:postgresql://localhost:5432/sharrydev"

sharry.restserver {
  backend {
    jdbc {
      url = ${jdbcurl}
      user = "dev"
      password = "dev"
    }
  }
}
```
