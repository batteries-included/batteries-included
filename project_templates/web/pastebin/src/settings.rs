use crate::errors::Error;
use axum_extra::extract::cookie::Key;
use std::net::SocketAddr;
use std::time::Duration;

const PORT: &str = "PORT";
const GREETING: &str = "GREETING";
const DATABASE_URL: &str = "DATABASE_URL";
const LISTEN_ADDR: &str = "PASTE_LISTEN_ADDR";
const BYTE_LIMIT: &str = "PASTE_BYTE_LIMIT";
const SIGNING_KEY: &str = "PASTE_SIGNING_KEY";

pub const HTTP_TIMEOUT: Duration = Duration::from_secs(10);

pub fn database_url() -> Result<String, Error> {
    match std::env::var(DATABASE_URL) {
        Ok(url) => Ok(url),
        Err(_) => Err(Error::DatabaseUrl),
    }
}

pub fn greeting() -> String {
    std::env::var(GREETING).unwrap_or_else(|_| "Welcome".to_owned())
}

pub fn byte_limit() -> Result<usize, Error> {
    std::env::var(BYTE_LIMIT)
        .map_or_else(|_| Ok(1000000), |s| s.parse::<usize>())
        .map_err(Error::ByteLimit)
}

pub fn signing_key() -> Result<Key, Error> {
    std::env::var(SIGNING_KEY).map_or_else(
        |_| Ok(Key::generate()),
        |s| Key::try_from(s.as_bytes()).map_err(|_err| Error::SigningKey),
    )
}

pub fn listen_addr() -> Result<SocketAddr, Error> {
    let default_port = std::env::var(PORT).unwrap_or("8080".to_owned());
    let default_addr = format!("0.0.0.0:{}", default_port);

    std::env::var(LISTEN_ADDR)
        .as_ref()
        .map(String::as_str)
        .unwrap_or(&default_addr)
        .parse()
        .map_err(|_| Error::ListenAddr)
}
