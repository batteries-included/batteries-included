use axum::{
    http::StatusCode,
    routing::{get, get_service, post, MethodRouter},
    Router,
};
use tower_http::services::ServeDir;

use crate::{
    app_state::AppState,
    handlers::{form_insert_paste, get_paste, show_index},
};

pub fn new() -> Router<AppState> {
    Router::new()
        .route("/", post(form_insert_paste).get(show_index))
        .route("/:id", get(get_paste))
        .nest_service("/static", static_file_service())
}

fn static_file_service() -> MethodRouter {
    let files = ServeDir::new("static").precompressed_gzip();

    get_service(files).handle_error(|e| async move {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Unhandled internal error: {}", e),
        )
    })
}
