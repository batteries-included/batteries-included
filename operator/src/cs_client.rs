use reqwest::Client;

#[derive(Debug, Clone)]
pub struct ControlServerClient {
    http_client: Client,
    base_url: String,
}

impl ControlServerClient {
    pub fn new(base_url: String) -> Self {
        Self {
            http_client: Client::new(),
            base_url,
        }
    }
}
