---
layout: docs
title: Development
permalink: doc/dev
---

# {{ page.title }}

## Contribution Guide Lines

Contribution guide lines may be found [here](https://github.com/eikek/sharry/blob/master/Contributing.md).

## Building

Clone the repository using [git](https://git-scm.org).

```
git clone https://github.com/eikek/sharry
```

Install [Elm](https://elm-lang.org) and [Sbt](https://scala-sbt.org),
which is used to build the application. Start `sbt` in the source root
and run inside the sbt shell:

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

## Nix Expressions

The directory `/nix` contains nix expressions to install sharry via
the nix package manager and to integrate it into NixOS as a system
service.

### Testing NixOS Modules

The modules can be build by building the `configuration-test.nix` file
together with some nixpkgs version. For example:

``` shell
nixos-rebuild build-vm -I nixos-config=./configuration-test.nix \
  -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz
```

This will build all modules imported in `configuration-test.nix` and
create a virtual machine containing the system, including sharry.
After that completes, the system configuration can be found behind the
`./result/system` symlink. So it is possible to look at the generated
systemd config for example:

``` shell
cat result/system/etc/systemd/system/sharry.service
```

And with some more commands (there probably is an easier way…) the
config file can be checked:

``` shell
cat result/system/etc/systemd/system/sharry.service | \
  grep ExecStart | \
  cut -d'=' -f2 | \
  xargs cat | \
  tail -n1 | \
  awk '{print $NF}'| \
  sed 's/.$//' | \
  xargs cat | jq
```

To see the module in action, the vm can be started (the first line
sets more memory for the vm):

``` bash
export QEMU_OPTS="-m 2048"
./result/bin/run-sharrytest-vm
```
