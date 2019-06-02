#![feature(core_intrinsics)]

use std::io::Write;

fn main() {
    //let mutex = std::sync::Mutex::new(0u32);
    //mutex.lock().unwrap();
    let _ = ::std::iter::repeat('a' as u8).take(10).collect::<Vec<_>>();
    let stderr = ::std::io::stderr();
    let mut stderr = stderr.lock();

    writeln!(stderr, "some {} text", "<unknown>").unwrap();

    let _ = std::process::Command::new("true").env("c", "d").spawn();

    println!("cargo:rustc-link-lib=z");

    static ONCE: std::sync::Once = std::sync::ONCE_INIT;
    ONCE.call_once(|| {});

    LoopState::Continue(()) == LoopState::Break(());

    unsafe {
        let ptr = &[0u64] as &[u64] as *const [u64] as *const u64;
        println!("{:p}", ptr);
        //std::slice::from_raw_parts(ptr, 1);
    }
}

#[derive(PartialEq)]
enum LoopState {
    Continue(()),
    Break(())
}
