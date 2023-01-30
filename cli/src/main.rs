use clap::Parser;
use cli::program_main;
use cli::Args;
use std::io;
use std::io::BufReader;
use std::io::BufWriter;

#[cfg(test)]
mod tests {
    use assert_cmd::Command;
    use predicates::prelude::*;
    static HELP_STR: &str = r#"Usage: cli <COMMAND>

Commands:
  create  
  start   
  help    Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
"#;

    #[test]
    fn test_help() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("help")
            .assert()
            .success()
            .stdout(predicate::eq(HELP_STR));
    }
}

#[tokio::main]
async fn main() {
    let stdin = BufReader::new(io::stdin().lock());
    let mut stderr = BufWriter::new(io::stderr());
    let mut stdout = BufWriter::new(io::stdout());
    let dir_parent = dirs::home_dir();

    let code = program_main(
        Args::parse(),
        Box::new(|| futures::executor::block_on(kube_client::Client::try_default()).unwrap()),
        &mut stderr,
        &stdin,
        &mut stdout,
        dir_parent,
        String::from(std::env::consts::ARCH),
    )
    .await;

    std::process::exit(code);
}
