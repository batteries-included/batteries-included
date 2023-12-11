use axum::{
    extract::{Form, Path, State},
    http::StatusCode,
    response::{IntoResponse, Redirect, Response},
};
use serde::Deserialize;

use crate::{
    app_state::AppState,
    mutation::Mutation,
    query::Query,
    view::{index, show},
};

pub async fn show_index(state: State<AppState>) -> Result<Response, Response> {
    Ok(index(&state.greeting).into_response())
}

pub async fn get_paste(
    Path(id): Path<String>,
    State(state): State<AppState>,
) -> Result<Response, Response> {
    let uuid_id =
        uuid::Uuid::parse_str(&id).map_err(|_| StatusCode::BAD_REQUEST.into_response())?;

    let paste_result = Query::find_paste_by_id(&state.conn, uuid_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response())?;

    match paste_result {
        Some(paste) => Ok(show(paste.text).into_response()),
        _ => Err(StatusCode::NOT_FOUND.into_response()),
    }
}

#[derive(Debug, Deserialize)]
pub struct InputPaste {
    content: String,
}

pub async fn form_insert_paste(
    state: State<AppState>,
    Form(form): Form<InputPaste>,
) -> Result<Response, Response> {
    let id: uuid::Uuid = Mutation::create_paste(&state.conn, form.content)
        .await
        .map_err(|_err| StatusCode::INTERNAL_SERVER_ERROR.into_response())?;

    let to = format!("/{}", &id);

    Ok(Redirect::to(&to).into_response())
}
