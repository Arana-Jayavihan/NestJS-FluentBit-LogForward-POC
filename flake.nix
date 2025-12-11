{
  description = "Nix flake for NestJS FluentBit Log Integration";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  
  outputs = { self, nixpkgs-unstable, ...}:

  let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable { inherit system; };
  in

  {
    devShells.${system}.default = pkgs-unstable.mkShell {
      buildInputs = with pkgs-unstable; [
        nodejs_24
        fluent-bit
        minikube
        kubernetes-helm
        kubectl
      ];
    };
  };
}
