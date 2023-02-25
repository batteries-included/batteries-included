use assert_cmd::Command;
use predicates::prelude::*;
static HELP_STR: &str = "Usage: bcli <COMMAND>";

#[test]
fn test_help() {
    let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
    cmd.arg("help")
        .assert()
        .success()
        .stdout(predicate::str::starts_with(HELP_STR));
}
