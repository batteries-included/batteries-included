use axum_extra::extract::cookie::Key;
use sea_orm::{Database, DatabaseConnection};

use crate::errors::Error;
use crate::settings;

#[derive(Clone)]
pub struct AppState {
    pub greeting: String,
    pub key: Key,
    pub conn: DatabaseConnection,
}

pub async fn new() -> Result<AppState, Error> {
    let greeting = settings::greeting();
    let database_url = settings::database_url()?;

    let conn = Database::connect(database_url)
        .await
        .map_err(|_| Error::DatabaseConnection)?;
    let key = settings::signing_key()?;

    Ok(AppState {
        greeting,
        conn,
        key,
    })
}
