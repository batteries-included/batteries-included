use clap::Parser;
use cli::prod::URL_STUB_KIND;
use cli::prod::URL_STUB_KUBECTL;
use cli::program_main;
use cli::CliArgs;
use cli::ProgramArgs;
use std::io;
use std::io::BufReader;
use std::io::BufWriter;

#[tokio::main]
async fn main() {
    let stdin = BufReader::new(io::stdin().lock());
    let mut stderr = BufWriter::new(io::stderr());
    let mut stdout = BufWriter::new(io::stdout());
    let dir_parent = dirs::home_dir();
    let mut program_args = ProgramArgs {
        cli_args: CliArgs::parse(),
        kube_client_factory: Box::new(|| {
            futures::executor::block_on(kube_client::Client::try_default()).unwrap()
        }),
        stderr: &mut stderr,
        _stdin: &stdin,
        _stdout: &mut stdout,
        dir_parent,
        raw_arch: String::from(std::env::consts::ARCH),
        raw_os: String::from(std::env::consts::OS),
        kind_stub: String::from(URL_STUB_KIND),
        kubectl_stub: String::from(URL_STUB_KUBECTL),
    };
    let code = program_main(&mut program_args).await;

    std::process::exit(code);
}
