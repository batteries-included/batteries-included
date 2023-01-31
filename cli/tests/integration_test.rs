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
