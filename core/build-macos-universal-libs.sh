#!/bin/sh


BASEDIR=$(dirname "$0")

cd $BASEDIR
cargo build -r --target=x86_64-apple-darwin
cargo build -r --target=aarch64-apple-darwin
mkdir -p target/universal-apple-darwin/release
lipo target/{x86_64,aarch64}-apple-darwin/release/libipf.dylib -create -output target/universal-apple-darwin/release/libipf.dylib
lipo target/{x86_64,aarch64}-apple-darwin/release/libipf.a -create -output target/universal-apple-darwin/release/libipf.a
echo 'Build dynamic library and static library done!'
