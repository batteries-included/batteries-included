pub mod cs_client;
pub mod state;
pub mod reconciler;
pub mod manager;
pub mod metrics;
pub mod prometheus;

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
