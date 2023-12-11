use askama::Template;

#[derive(Template)]
#[template(path = "index.html")]
pub struct IndexTemplate<'a> {
    greeting: &'a str,
}

pub fn index(greeting: &str) -> IndexTemplate {
    IndexTemplate { greeting }
}

#[derive(Template)]
#[template(path = "show.html")]
pub struct ShowTemplate {
    text: String,
}

pub fn show(text: String) -> ShowTemplate {
    ShowTemplate { text }
}
