use std::num::ParseIntError;

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("couldn't generate key from SIGNING_KEY")]
    SigningKey,
    #[error("couldn't parse BYTE_LIMIT")]
    ByteLimit(ParseIntError),
    #[error("couldn't parse LISTEN_ADDR")]
    ListenAddr,
    #[error("couldn't parse DATABASE_URL")]
    DatabaseUrl,
    #[error("database connection error")]
    DatabaseConnection,
    #[error("couldn't load terra templates")]
    TerraTemplates,
}
