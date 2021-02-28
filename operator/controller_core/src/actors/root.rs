use common::actors::messages::ActorMessage;
use tokio::sync::mpsc;

struct RootActor {
    receiver: mpsc::Receiver<ActorMessage>,
}

impl RootActor {
    fn new(receiver: mpsc::Receiver<ActorMessage>) -> Self {
        Self { receiver }
    }
    async fn run(&mut self) {
        while let Some(msg) = self.receiver.recv().await {
            self.handle_message(msg);
        }
    }
    fn handle_message(&mut self, msg: ActorMessage) {
        match msg {
            ActorMessage::Shutdown => (),
        }
    }
}

#[derive(Clone)]
pub struct RootActorHandle {
    sender: mpsc::Sender<ActorMessage>,
}
impl RootActorHandle {
    pub fn new() -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let mut actor = RootActor::new(receiver);
        tokio::spawn(async move { actor.run().await });
        Self { sender }
    }
}
impl Default for RootActorHandle {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod test_root_actor {
    use super::*;

    #[tokio::test]
    async fn test_start() {
        let _handle = RootActorHandle::new();
        assert!(true);
    }
}
