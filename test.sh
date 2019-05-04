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

echo "[AOT] arbitrary_self_types_pointers_and_wrappers"
$RUSTC example/arbitrary_self_types_pointers_and_wrappers.rs --crate-type bin -Cpanic=abort
./target/out/arbitrary_self_types_pointers_and_wrappers

echo "[BUILD] sysroot"
time ./build_sysroot/build_sysroot.sh

$RUSTC example/std_example.rs --crate-type bin
./target/out/std_example

git clone https://github.com/rust-lang/rust.git --depth=1 || true
cd rust
git checkout -- .
#git pull
export RUSTFLAGS=

git apply ../rust_lang.patch


rm config.toml || true

cat > config.toml <<EOF
[rust]
codegen-backends = []
[build]
local-rebuild = true
cargo = "$(echo ~/.rustup/toolchains/nightly-x86_64-*/bin/cargo)"
rustc = "$(echo ~/.rustup/toolchains/nightly-x86_64-*/bin/rustc)"
EOF

rm -r src/test/run-pass/{asm-*,abi-*,extern/,panic-runtime/,panics/,unsized-locals/,proc-macro/,threads-sendsync/,thinlto/,simd/} || true
for test in src/test/run-pass/*.rs src/test/run-pass/**/*.rs; do
    if grep "ignore-emscripten" $test 2>&1 >/dev/null; then
        rm $test
    fi
done

echo "[TEST] run-pass"

#rm -r build/x86_64-unknown-linux-gnu/test || true
./x.py test --stage 0 src/test/run-pass/ \
    --rustc-args "-Zcodegen-backend=$(pwd)/../target/"$channel"/librustc_codegen_cranelift."$dylib_ext" --sysroot $(pwd)/../build_sysroot/sysroot -Cpanic=abort" \
    2>&1 | tee log.txt
