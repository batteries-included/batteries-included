use ::entity::{paste, paste::Entity as Paste};
use sea_orm::*;
use uuid::Uuid;

pub struct Query;

impl Query {
    pub async fn find_paste_by_id(db: &DbConn, id: Uuid) -> Result<Option<paste::Model>, DbErr> {
        Paste::find_by_id(id).one(db).await
    }
}
