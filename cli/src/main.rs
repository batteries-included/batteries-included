use bcli::args::BaseArgs;
use bcli::args::CliArgs;
use bcli::args::ProgramArgs;
use bcli::commands::program_main;
use clap::Parser;

use eyre::ContextCompat;
use eyre::Result;
use tracing::log;

fn convert_filter(filter: log::LevelFilter) -> tracing_subscriber::filter::LevelFilter {
    match filter {
        log::LevelFilter::Off => tracing_subscriber::filter::LevelFilter::OFF,
        log::LevelFilter::Error => tracing_subscriber::filter::LevelFilter::ERROR,
        log::LevelFilter::Warn => tracing_subscriber::filter::LevelFilter::WARN,
        log::LevelFilter::Info => tracing_subscriber::filter::LevelFilter::INFO,
        log::LevelFilter::Debug => tracing_subscriber::filter::LevelFilter::DEBUG,
        log::LevelFilter::Trace => tracing_subscriber::filter::LevelFilter::TRACE,
    }
}

#[tokio::main(worker_threads = 2)]
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
            arch: String::from(std::env::consts::ARCH),
        },
    };

    tracing_subscriber::fmt()
        .with_max_level(convert_filter(
            program_args.cli_args.verbose.log_level_filter(),
        ))
        .init();

    program_main(program_args).await
}
