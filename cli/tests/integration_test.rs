use assert_cmd::Command;

static HELP_STR: &str = "Usage: bcli [OPTIONS] <COMMAND>";

#[test]
fn test_help_command() {
    let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
    let stdout = String::from_utf8(cmd.arg("help").output().unwrap().stdout).unwrap();
    assert!(
        stdout.contains(HELP_STR),
        "The help command should include usgage and options."
    );
}
