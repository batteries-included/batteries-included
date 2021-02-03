use prometheus::{register_int_counter, IntCounter};

#[derive(Clone)]
pub struct ControllerMetrics {
    pub reconcile_called: IntCounter,
}
impl ControllerMetrics {
    #[must_use]
    pub fn new() -> Self {
        Self {
            reconcile_called: register_int_counter!("reconcile_called", "Reconcile Called")
                .unwrap(),
        }
    }
}

impl Default for ControllerMetrics {
    fn default() -> Self {
        Self::new()
    }
}
