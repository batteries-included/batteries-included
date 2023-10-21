use std::{
    path::PathBuf,
    process::{Command, Output},
    time::Duration,
};

use eyre::Result;
use tracing::{debug, info};

const INFO_ARGS: [&str; 2] = ["--debug", "info"];
const INIT_ARGS: [&str; 9] = [
    "machine",
    "init",
    "--cpus",
    "2",
    "--disk-size",
    "128",
    "--memory",
    "4096",
    "--rootful",
];
const START_ARGS: [&str; 5] = ["podman", "machine", "start", "--no-info", "--quiet"];

pub async fn ensure_podman_started<P>(base_temp_dir: P) -> Result<()>
where
    P: Into<PathBuf>,
{
    // This is kind of a hack, but also elegant
    //
    // podman fails when started from inside of nix direnv.
    // Nix/direnv tacks on a TEMP_DIR/TMP that's special for the derivation.
    // However that's not shared with any other processes that don't get spawned with the env
    //
    // So you get this shit:
    //  ```Starting machine "podman-machine-default"
    //     Waiting for VM ...
    //     Error: dial unix /var/folders/d6/fxgml2l933j5pmkp5_cq5qqh0000gn/T/nix-shell.EOsX7O/podman/podman-machine-default_ready.sock: connect: invalid argument
    //  ```

    //
    // Now we should be able to just drop those directories and be done, except
    // it seems like defaults somewhere get royally fucked if I do that.
    //
    // Instead we side step the whole fucking thing and do it ourselves, by using the provided cache dir
    // that rust's dir's crate provides us. That's right we set the env variable ourself to a sane default
    // that's also shared with what will be found if the env is dropped, and everyone is happy.
    //
    let temp_dir = clean_temp_path(base_temp_dir.into())?;

    // Try and get the info about podman.
    // If there's no machine running to host podman
    // then this fails
    debug!("Checking podman info to check liveness");
    let info_out = podman_info(temp_dir.clone()).await?;
    if !info_out.status.success() {
        // At this point we hope there are no machines
        let _ = init_podman_machine(temp_dir.clone()).await?;

        // Start the thing for real.
        start_podman_machine(temp_dir.clone())
            .await?
            .status
            .exit_ok()?;

        // Sometimes podman is up, but it's up so fast that kind can't actually start
        debug!("Sleeping until podman is up and ready...");
        tokio::time::sleep(Duration::from_secs(5)).await;
    }

    Ok(())
}

fn clean_temp_path(temp_dir: PathBuf) -> Result<PathBuf> {
    let conan_dir = temp_dir.canonicalize()?;

    // See if the path contains nix-shell which seems to mess up podman
    if conan_dir
        .to_str()
        .map(|p| p.contains("nix-shell"))
        .unwrap_or(false)
    {
        Ok(conan_dir.join("..").canonicalize()?)
    } else {
        Ok(conan_dir)
    }
}
async fn init_podman_machine(temp_dir: PathBuf) -> Result<Output> {
    debug!("Initializing podman machine");
    run_command("podman", INIT_ARGS, temp_dir).await
}

async fn start_podman_machine(temp_dir: PathBuf) -> Result<Output> {
    // Okay what the hell
    //
    // `podman start` is supposed to start the process running in the background
    // However the daeamon gets reaped as a child when we die :-/
    //
    // Tried wrapping in a bash or nohup
    info!("Starting podman machine running");
    run_command("nohup", START_ARGS, temp_dir).await
}
async fn podman_info(temp_dir: PathBuf) -> Result<Output> {
    run_command("podman", INFO_ARGS, temp_dir).await
}

async fn run_command<I, S>(program: &str, args: I, temp_dir: PathBuf) -> Result<Output>
where
    I: IntoIterator<Item = S>,
    S: ToString,
{
    let cloned_args: Vec<String> = args.into_iter().map(|a| a.to_string()).collect();
    let cloned_prog = program.to_string();

    let f = move || -> Result<Output> {
        let res = Command::new(cloned_prog)
            .env("TMPDIR", temp_dir.clone())
            .env("TEMPDIR", temp_dir.clone())
            .env("TMP", temp_dir.clone())
            .env("TEMP", temp_dir.clone())
            .args(cloned_args)
            .output()?;

        Ok(res)
    };
    tokio::task::spawn_blocking(f).await?
}
