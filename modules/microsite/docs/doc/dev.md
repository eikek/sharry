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

Install [Elm](https://elm-lang.org), [Sbt](https://scala-sbt.org),
[npm](https://npmjs.org) and the
[tailwind-cli](https://github.com/tailwindlabs/tailwindcss/releases),
which is used to build the application.

A convenient alternative is to install [nix](https://nixos.org/nix)
(with flakes enabled) and run `nix develop` in the project root. Even
better with [direnv](https://direnv.net) which takes care of that step
transitively.

Start `sbt` in the source root and run inside the sbt shell:

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

The file `flake.nix` contains nix expressions to install sharry via
the nix package manager and to integrate it into NixOS as a system
service.

### Update the nix build

The nix build is setup in `flake.nix`, which refers to the
`nix/package.nix` to build the sharry application. It is build by
first obtaining all dependencies, so that the actual build can be done
in a sandbox without network.

Since `npm` and `elm` mess with the users home directory and require
an internet connection, building the webapp into a webjar is done as
part of the "dependency phase".

If something changes, run `nix build` *twice* and check whether the
hash is the same (this to check whether there was something not
reproducible accidentally included). Then update the `depsSha256`
attribute in `package.nix`. Run `nix build` again and start the app
for a quick check.

NOTE: if nix has the dependencies with the given hash cached, *it will
not* build it again. To be sure, just remove the hash and leave an
empty string. The build will then fail and give the proper hash.

### Testing NixOS Modules

The modules can be build by building the `configuration-test.nix` file
which is referenced in the flake.

``` shell
nixos-rebuild build-vm --flake .#test-vm
```

To build and run with one command:
``` shell
nix run .#nixosConfigurations.test-vm.config.system.build.vm
```

This will build, resp. run, a vm with sharry included. After the
build-vm command completes, the system configuration can be found
behind the `./result/system` symlink. So it is possible to look at the
generated systemd config for example:

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
  sed 's/sharry.restserver = //' | \
  jq
```

To see the module in action, the vm can be started (the first line
sets more memory for the vm):

``` bash
export QEMU_OPTS="-m 2048"
./result/bin/run-sharrytest-vm
```
