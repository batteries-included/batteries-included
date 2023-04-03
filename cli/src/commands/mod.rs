use crate::args::{CliAction, ProgramArgs};
use eyre::Result;

use self::dev::dev_command;

pub mod dev;

pub async fn program_main(program_args: ProgramArgs) -> Result<()> {
    match program_args.cli_args.action {
        CliAction::Dev {
            installation_url,
            overwrite_resources,
            ..
        } => {
            dev_command(
                program_args.base_args,
                installation_url,
                overwrite_resources,
            )
            .await
        }
        CliAction::Start { .. } => unimplemented!(),
    }
}
