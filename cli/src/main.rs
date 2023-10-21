use bcli::args::BaseArgs;
use bcli::args::CliArgs;
use bcli::args::ProgramArgs;
use bcli::commands::program_main;
use bcli::logging::TracingFilterExt;
use clap::Parser;

use eyre::Context;
use eyre::ContextCompat;
use eyre::Result;

#[tokio::main(worker_threads = 4)]
async fn main() -> Result<()> {
    color_eyre::install()?;

    let program_args = ProgramArgs {
        cli_args: CliArgs::parse(),
        base_args: BaseArgs {
            kube_client_factory: Box::new(|| {
                futures::executor::block_on(kube_client::Client::try_default()).unwrap()
            }),
            dir_parent: dirs::home_dir()
                .context("Expected a home directory for us to install into")?,
            current_dir: std::env::current_dir().context("Expected to get a current dir")?,
            arch: String::from(std::env::consts::ARCH),
            os: String::from(std::env::consts::OS),
            temp_dir: std::env::temp_dir(),
        },
    };

    tracing_subscriber::fmt()
        .with_max_level(
            program_args
                .cli_args
                .verbose
                .log_level_filter()
                .to_tracing_subscriber_filter(),
        )
        .init();

    program_main(program_args).await
}
