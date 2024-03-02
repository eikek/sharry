{
  concatTextFile,
  writeShellScriptBin,
}: let
  key = ./dev-vm-key;
in rec {
  devcontainer-recreate = concatTextFile {
    name = "devcontainer-recreate";
    files = [./scripts/recreate-container];
    executable = true;
    destination = "/bin/devcontainer-recreate";
  };

  devcontainer-start = writeShellScriptBin "devcontainer-start" ''
    cnt=''${SHARRY_CONTAINER:-sharry-dev}
    sudo nixos-container start $cnt
  '';

  devcontainer-stop = writeShellScriptBin "devcontainer-stop" ''
    cnt=''${SHARRY_CONTAINER:-sharry-dev}
    sudo nixos-container stop $cnt
  '';

  devcontainer-login = writeShellScriptBin "devcontainer-login" ''
    cnt=''${SHARRY_CONTAINER:-sharry-dev}
    sudo nixos-container root-login $cnt
  '';

  vm-build = writeShellScriptBin "vm-build" ''
    nix build .#nixosConfigurations.dev-vm.config.system.build.vm
  '';

  vm-run = writeShellScriptBin "vm-run" ''
    nix run .#nixosConfigurations.dev-vm.config.system.build.vm
  '';

  vm-ssh = writeShellScriptBin "vm-ssh" ''
    ssh -i ${key} -p $VM_SSH_PORT root@localhost "$@"
  '';

  run-jekyll = writeShellScriptBin "run-jekyll" ''
    jekyll serve -s modules/microsite/target/site --baseurl /sharry
  '';
}
