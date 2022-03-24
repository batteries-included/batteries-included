use std::collections::BTreeMap;

pub fn default_labels(app_name: &str) -> BTreeMap<String, String> {
    [
        ("battery/app".to_owned(), app_name.to_owned()),
        ("battery/managed".to_owned(), "true".to_owned()),
    ]
    .iter()
    .cloned()
    .collect()
}
