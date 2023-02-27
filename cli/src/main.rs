use bcli::prod::URL_STUB_KIND;
use bcli::prod::URL_STUB_KUBECTL;
use bcli::program_main;
use bcli::CliArgs;
use bcli::ProgramArgs;
use clap::Parser;
use std::io;
use std::io::BufReader;
use std::io::BufWriter;
use tokio::runtime::Handle;

#[tokio::main]
async fn main() {
    let stdin = BufReader::new(io::stdin().lock());
    let mut stderr = BufWriter::new(io::stderr());
    let mut stdout = BufWriter::new(io::stdout());
    let dir_parent = dirs::home_dir();
    let mut program_args = ProgramArgs {
        cli_args: CliArgs::parse(),
        kube_client_factory: Box::new(|| {
            let handle = Handle::current();
            let _ = handle.enter();
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
