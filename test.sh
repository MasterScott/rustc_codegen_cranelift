#!/bin/bash
source config.sh

rm -r target/out || true
mkdir -p target/out/clif

echo "[BUILD] mini_core"
$RUSTC example/mini_core.rs --crate-name mini_core --crate-type lib

echo "[BUILD] example"
$RUSTC example/example.rs --crate-type lib

echo "[JIT] mini_core_hello_world"
SHOULD_RUN=1 JIT_ARGS="abc bcd" $RUSTC --crate-type bin example/mini_core_hello_world.rs --cfg jit

echo "[AOT] mini_core_hello_world"
$RUSTC example/mini_core_hello_world.rs --crate-name mini_core_hello_world --crate-type bin
./target/out/mini_core_hello_world abc bcd

echo "[BUILD] sysroot"
time ./build_sysroot/build_sysroot.sh

echo "[BUILD+RUN] alloc_example"
$RUSTC --sysroot ./build_sysroot/sysroot example/alloc_example.rs --crate-type bin
./target/out/alloc_example

echo "[BUILD+RUN] std_example"
$RUSTC --sysroot ./build_sysroot/sysroot example/std_example.rs --crate-type bin
./target/out/std_example

echo "[BUILD] mod_bench"
$RUSTC --sysroot ./build_sysroot/sysroot example/mod_bench.rs --crate-type bin

# FIXME linker gives multiple definitions error on Linux
#echo "[BUILD] sysroot in release mode"
#./build_sysroot/build_sysroot.sh --release

git clone https://github.com/rust-lang/rust.git --depth=1
rm Cargo.toml
cd rust/src/tools/compiletest/
cargo run -- --rustc-path=$(whereis rustc) --lldb-python=python --docck-python=python --src-base=$(pwd)/../../test --build-base=/tmp --stage-id=stage1 --mode=run-pass --cc=gcc --cxx=g++ --cflags=""

cat target/out/log.txt | sort | uniq -c
