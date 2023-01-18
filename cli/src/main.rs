use clap::Parser;

#[derive(clap::Parser)]
struct Args {
    #[command(subcommand)]
    cli_action: CliAction,
}

#[derive(clap::Subcommand)]
enum CliAction {
    Create {
        #[clap(long)]
        forward_postgres: Option<String>,
        #[clap(long)]
        sync: Option<bool>
    },
    Start {
        #[clap(long)]
        forward_postgres: Option<String>,
        /// optional, positional customer id
        id: Option<String>,

        #[clap(long)]
        overwrite_resources: Option<bool>,
    },

}

#[cfg(test)]
mod tests {
    use assert_cmd::prelude::*;
    use predicates::prelude::*;
    use std::process::Command;
    static HELP_STR: &str = r#"Usage: cli <COMMAND>

Commands:
  create  
  start   
  help    Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
"#;

    #[test]
    fn test_blank() {
        use assert_cmd::Command;

        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.assert()
            .failure()
            .stderr(predicate::eq(HELP_STR));
    }

    #[test]
    fn test_help() {
        use assert_cmd::Command;

        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("help")
            .assert()
            .success()
            .stdout(predicate::eq(HELP_STR));
    }
}

fn main() {
    let args = Args::parse();
}


