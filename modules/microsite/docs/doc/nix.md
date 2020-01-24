---
layout: docs
title: Nix/NixOS
permalink: doc/nix
---

# {{ page.title }}

## Install via Nix

Sharry can be installed via the [nix](https://nixos.org/nix) package
manager, which is available for Linux and OSX. Sharry is currently not
part of the [nixpkgs collection](https://nixos.org/nixpkgs/), but you
can use the derivation from this repository. This is sometimes
referred to as [import from
derivation](https://nixos.wiki/wiki/Import_From_Derivation).

For example, the `builtins.fetchTarball` function can be used to
retrieve the files; then import the `release.nix` file:

``` nix
let
  sharrysrc = builtins.fetchTarball "https://github.com/eikek/sharry/archive/master.tar.gz";
in
import "${sharrysrc}/nix/release.nix";
```

This creates a set containing a function for creating a derivation for
sharry. This then needs to be called like other custom packages. For
example, in your `~/.nixpkgs/config.nix` you could write this:

``` nix
let
  sharrysrc = builtins.fetchTarball "https://github.com/eikek/sharry/archive/master.tar.gz";
  sharry = import "${sharrysrc}/nix/release.nix";
in
{ packageOverrides = pkgs:
   let
     callPackage = pkgs.lib.callPackageWith(custom // pkgs);
     custom = {
       sharry = callPackage sharry.currentPkg {};
     };
   in custom;
}
```

Then you can install sharry via `nix-shell` or `nix-env`, for example:

``` bash
$ nix-env -iA nixpkgs.sharry
```

You may need to replace `nixpkgs` with `nixos` when you're on NixOS.

The expression `sharry.currentPkg` refers to the most current release
of Sharry. So even if you use the tarball of the current master
branch, the `release.nix` file only contains derivations for releases.
The expression `sharry.currentPkg` is a shortcut for selecting the
most current release. For example it translates to `sharry.pkg
sharry.cfg.v@PVERSION@` – if the current version is `@VERSION@`.


## Sharry as a service on NixOS

If you are running [NixOS](https://nixos.org), there is a module
definition for installing Sharry as a service using systemd.

You need to import the `release.nix` file as described above in your
`configuration.nix` and then append the sharry module to your list of
modules. Here is an example:

```nix
{ config, pkgs, ... }:
let
  sharrysrc = builtins.fetchTarball "https://github.com/eikek/sharry/archive/master.tar.gz";
  sharry = import "${sharrysrc}/nix/release.nix";
in
{
  imports = [ mymodule1 mymodule2 ] ++ sharry.modules;

  nixpkgs = {
    config = {
      packageOverrides = pkgs:
        let
          callPackage = pkgs.lib.callPackageWith(custom // pkgs);
          custom = {
            sharry = callPackage sharry.currentPkg {};
          };
        in custom;
    };
  };

  services.sharry = {
    enable = true;
    base-url = "http://sharrytest:7878";
    backend = {
      auth = {
        oauth = [];
      };
    };
  };

  ...
}

```

Please see the `nix/module.nix` file for the set of options. The nixos
options are modelled after the default configuration file.
