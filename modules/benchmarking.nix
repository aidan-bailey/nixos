{
  config,
  lib,
  pkgs,
  ...
}:

let
  cpuPackages = with pkgs; [
    stress-ng
    sysbench
    s-tui
  ];

  memoryPackages = with pkgs; [
    memtester
  ];

  diskPackages = with pkgs; [
    fio
    iozone
  ];

  networkPackages = with pkgs; [
    iperf3
  ];

  systemPackages = with pkgs; [
    phoronix-test-suite
    geekbench
  ];

  gpuPackages = with pkgs; [
    unigine-heaven
    unigine-valley
  ];

  cliPackages = with pkgs; [
    hyperfine
  ];

in
{
  environment.systemPackages =
    cpuPackages
    ++ memoryPackages
    ++ diskPackages
    ++ networkPackages
    ++ systemPackages
    ++ gpuPackages
    ++ cliPackages;
}
