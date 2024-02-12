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
can use the derivation from this repository. It uses [nix
flakes](https://nixos.wiki/wiki/Flakes), which you must enable in your
nix installation.

The quickest way to run sharry:
``` bash
$ nix run github:eikek/sharry
```

This will build sharry from its default branch, which is `master`. It
is recommended to use a tag instead, as `master` may not always work.
Simply append the tag (starting from 1.14.0). Also a config file should be given:

``` bash
$ nix run github:eikek/sharry/v1.14.0 -- /path/to/sharry.conf
```

To make it permanent, install it into your profile:
``` bash
$ nix profile install github:eikek/sharry/v1.14.0
```

### Latest Release

The flake provides two packages: `sharry` is build from the source
tree as referenced by the flake url. There is also `sharry-bin` which
builds the latest (at time of the commit referenced by the flake url)
release as published to GitHub. In case a tag is referenced by the
flake url as shown above, both versions are the same.

The NixOS module uses the `sharry` package by default. It can be
changed via the config to provide a different one.


## Sharry as a service on NixOS

If you are running [NixOS](https://nixos.org), there is a module
definition for installing Sharry as a service using systemd.

Define this repo in your inputs and refer to its module:

```nix
{
  inputs = {
    sharry = "github:eikek/sharry/v1.14.0";
  };

  outputs = attrs@{ nixpkgs, sharry, ... }:
    {
      nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          # include sharry
          sharry.nixosModules.default
          # your machine config
          ./configuration.nix
        ];
      };
    };
}
```

Please see the `nix/module.nix` file for the set of options. The nixos
options are modelled after the default configuration file.
