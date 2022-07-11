use async_trait::async_trait;

use color_eyre::{Help, SectionExt};
use eyre::{eyre, Result};
use tracing::{instrument, Instrument};

use std::process::{ExitStatus, Stdio};
use tokio::process::Command;

#[async_trait]
pub trait RunHelper {
    async fn run(&mut self) -> Result<ExitStatus>;
}

#[async_trait]
impl RunHelper for Command {
    #[instrument(skip(self))]
    async fn run(&mut self) -> Result<ExitStatus> {
        let child = self.spawn()?;

        let output = child
            .wait_with_output()
            .in_current_span()
            .await
            .map_err(|e| eyre!("Failed to run {:?}: {}", self.as_std().get_program(), e))?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        output
            .status
            .success()
            .then(|| output.status)
            .ok_or_else(|| {
                let stderr = String::from_utf8_lossy(&output.stderr);
                eyre!("{:?} exited non-zero", self.as_std().get_program())
                    .with_section(move || stderr.trim().to_string().header("Stderr:"))
                    .with_section(move || stdout.trim().to_string().header("Stdout:"))
            })
    }
}

pub trait ToCommand {
    fn to_command(&self) -> Command {
        let mut cmd = Command::new(self.cmd_name());
        cmd.args(self.to_args())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped());
        cmd
    }
    fn cmd_name(&self) -> &str;
    fn to_args(&self) -> Vec<String>;
}
