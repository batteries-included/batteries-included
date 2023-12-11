use npm_rs::*;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("cargo:rerun-if-changed=static/styles.css");
    println!("cargo:rerun-if-changed=styles/styles.css");
    if std::env::var_os("CARGO_FEATURE_GENERATE_STYLES").is_some() {
        let exit_status = NpmEnv::default()
            .with_node_env(&NodeEnv::from_cargo_profile().unwrap_or_default())
            .init_env()
            .install(None)
            .run("build:tailwind")
            .exec()?;

        if !exit_status.success() {
            panic!("npm failed");
        }
    }

    Ok(())
}
