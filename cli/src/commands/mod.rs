use crate::args::{CliAction, ProgramArgs};
use eyre::Result;

use self::{dev::dev_command, stop::stop_command, uninstall::uninstall_command};

pub mod dev;
pub mod stop;
pub mod uninstall;

pub async fn program_main(program_args: ProgramArgs) -> Result<()> {
    match program_args.cli_args.action {
        CliAction::Dev {
            installation_url,
            overwrite_resources,
            forward_postgres,
            platform_dir,
            static_dir,
            forward_pods,
            ..
        } => {
            dev_command(
                program_args.base_args,
                installation_url,
                overwrite_resources,
                forward_postgres,
                forward_pods,
                platform_dir,
                static_dir,
            )
            .await
        }
        CliAction::Uninstall => uninstall_command(program_args.base_args).await,
        CliAction::Stop { .. } => stop_command(program_args.base_args).await,
        CliAction::Start { .. } => unimplemented!(),
    }
}
