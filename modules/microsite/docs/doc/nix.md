---
layout: docs
title: Nix/NixOS
permalink: doc/nix
---

# {{ page.title }}

## Install nix

Sharry is a flake. You need to enable flakes in order to make use of
it. You can also use the provided expressions without Flakes, which is
described below.

## Try it out

You can try out sharry by running the following:

```
nix run github:eikek/sharry
```

To pass a configuration file, provide it to the command after a
double-dash:
```
nix run github:eikek/sharry -- /path/to/sharry.conf
```

This will run the latest release using a file-based database in the
`/tmp` directory.

A more elaborate setup can be started using the `test-vm`:

```
nix run github:eikek/sharry#nixosConfigurations.test-vm.config.system.build.vm
```

This starts a VM with sharry installed connected to a PostgreSQL database.


## Install via Nix

Sharry can be installed via the [nix](https://nixos.org/nix) package
manager. Sharry is currently not part of the [nixpkgs
collection](https://nixos.org/nixpkgs/), but you can use this flake.


``` bash
$ nix profile install github:eikek/sharry
```

### Latest Release

The flake provides two packages: `sharry-dev` is build from the source
tree as referenced by the flake url. The package `sharry` builds the
latest (at time of the commit referenced by the flake url) release as
published to GitHub.

The NixOS module uses the `sharry` package by default. It can be
changed via the config to provide a different one.


## Sharry as a service on NixOS

If you are running [NixOS](https://nixos.org), there is a module
definition for installing Sharry as a service using systemd.

Define this repo in your inputs and refer to its module:

```nix
{
  inputs = {
    sharry = "github:eikek/sharry";
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

## Without Flakes

You can use the provided nix expressions without flakes. The default
package is in `nix/package-bin.nix`. Just call them with your nixpkgs
instance as usual:

```nix
let
  repo = fetchFromGitHub {
    owner = "eikek";
    repo = "sharry";
    rev = "master";
    sha256 = "sha256-/tBvn1l8XUCsNyed4haK9r6jwc1uTCxag4qYv0ns0qs=";
  };
  sharry = callPackage (import "${repo}/nix/package-bin.nix") {};
in
 …
```
