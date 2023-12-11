use ::entity::paste;
use sea_orm::*;
use uuid::Uuid;

pub struct Mutation;

impl Mutation {
    pub async fn create_paste(db: &DbConn, text: String) -> Result<Uuid, DbErr> {
        let active_paste = paste::ActiveModel {
            id: Set(Uuid::new_v4()),
            text: Set(text),
        };

        paste::Entity::insert(active_paste)
            .exec(db)
            .await
            .map(|ir| ir.last_insert_id)
    }
}
