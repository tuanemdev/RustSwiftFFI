uniffi::setup_scaffolding!();

#[uniffi::export]
pub fn add_core_logic(left: u64, right: u64) -> u64 {
    left + right
}

#[uniffi::export]
pub fn say_hi_from_rust() -> String {
    "Hello from Rust!".to_string()
}
