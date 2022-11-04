{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.dart
    pkgs.zig
    pkgs.zls
  ];
}
