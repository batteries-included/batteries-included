use axum::{Router, Server};
use migration::{Migrator, MigratorTrait};
use std::process::ExitCode;
use tower::ServiceBuilder;

use axum::extract::DefaultBodyLimit;
use tower_http::compression::CompressionLayer;
use tower_http::timeout::TimeoutLayer;
use tower_http::trace::TraceLayer;

pub mod app_state;
pub mod errors;
pub mod handlers;
pub mod mutation;
pub mod query;
pub mod router;
pub mod settings;
pub mod view;

pub async fn start() -> Result<(), Box<dyn std::error::Error>> {
    let addr = settings::listen_addr()?;

    let byte_limit = settings::byte_limit()?;
    let app_state = app_state::new().await?;

    // Now that we have a db connection migrate
    Migrator::up(&app_state.conn, None).await?;

    let router = router::new();

    let service_builder = ServiceBuilder::new()
        .layer(TraceLayer::new_for_http())
        .layer(DefaultBodyLimit::max(byte_limit))
        .layer(CompressionLayer::new())
        .layer(TimeoutLayer::new(settings::HTTP_TIMEOUT));

    let service: Router<()> = router.layer(service_builder).with_state(app_state);

    Server::bind(&addr)
        .serve(service.into_make_service())
        .with_graceful_shutdown(async {
            tokio::signal::ctrl_c()
                .await
                .expect("failed to listen to ctrl-c");
        })
        .await?;

    Ok(())
}

#[tokio::main]
async fn main() -> ExitCode {
    tracing_subscriber::fmt::init();

    match start().await {
        Ok(_) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("Error: {err}");
            ExitCode::FAILURE
        }
    }
}
