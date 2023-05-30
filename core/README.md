# libipf

This is the Rust implementation of core functionality for port forwarding,
which can be accessed as a shared C static or dynamic library.

## Build

Simply run:

```shell
cargo run -r
```

To create a universal library that works on both x86_64 and ARM64 architectures for macOS, you can use a script.
However, before running the script, ensure that `aarch64-apple-darwin` and `x86_64-apple-darwin` are already installed as rustup targets.

```shell
sh build-macos-universal-libs.sh
```

## Function Signatures

You can check header file [here](./headers/ipf.h).

## Lua script

There is a Lua script named `demo.lua` that performs port forwarding by loading the dynamic library via luajit. This script exists primarily for testing purposes, allowing you to verify whether libipf is functioning correctly.

Please make sure you have build the libraries in release mode before you run the Lua script.

```shell
cargo build -r
luajit demo.lua
```
