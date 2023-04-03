use std::net::SocketAddr;

use eyre::{ContextCompat, Result};
use futures::{StreamExt, TryStreamExt};
use k8s_openapi::api::core::v1::Pod;
use kube_client::api::ListParams;
use kube_client::{Api, Client};
use tokio::io::{AsyncRead, AsyncWrite};
use tokio::net::TcpListener;
use tokio_stream::wrappers::TcpListenerStream;
use tracing::{debug, error, info};

pub async fn port_forward(kube_client: Client, namespace: &str) -> Result<()> {
    info!("Starting port forward");
    let pods: Api<Pod> = Api::namespaced(kube_client, namespace);
    // Get and wait for the master name.
    //
    // This allows us to pause before bringing up the port-forwarder
    let initial_master_name = master_name(pods.clone()).await?;
    info!("Initial master pods name = {:?}", initial_master_name);
    start_server(pods).await
}

async fn master_name(pods: Api<Pod>) -> Result<String> {
    let list_params = ListParams::default()
        .labels("spilo-role=master,cluster-name=pg-control")
        .disable_bookmarks()
        .timeout(290);
    let list = pods.list(&list_params).await?;
    if list.items.is_empty() {
        let rv = list
            .metadata
            .resource_version
            .unwrap_or_else(|| "0".to_string());
        let mut stream = pods.watch(&list_params, &rv).await?.boxed();
        let res = stream.try_next().await?.and_then(|event| match event {
            kube_client::core::WatchEvent::Added(pod) => pod.metadata.name,
            kube_client::core::WatchEvent::Modified(pod) => pod.metadata.name,
            _event => None,
        });

        Ok(res.context("Expected a pod name after timeout of 290 seconds")?)
    } else {
        let pod_name = list.into_iter().next().and_then(|p| p.metadata.name);

        debug!(pod_name = pod_name);
        Ok(pod_name.context("We should have only one name by now")?)
    }
}

async fn forward_connection(
    pods: &Api<Pod>,
    pod_name: &str,
    port: u16,
    mut client_conn: impl AsyncRead + AsyncWrite + Unpin,
) -> Result<()> {
    let mut forwarder = pods.portforward(pod_name, &[port]).await?;
    let mut upstream_conn = forwarder
        .take_stream(port)
        .context("port not found in forwarder")?;
    tokio::io::copy_bidirectional(&mut client_conn, &mut upstream_conn).await?;
    drop(upstream_conn);
    forwarder.join().await?;
    info!("connection closed");
    Ok(())
}

async fn start_server(pods: Api<Pod>) -> Result<()> {
    let addr = SocketAddr::from(([127, 0, 0, 1], 5432));
    let pod_port = 5432;
    info!(local_addr = %addr, pod_port, "forwarding traffic to the pod");
    let server = TcpListenerStream::new(TcpListener::bind(addr).await.unwrap())
        .take_until(tokio::signal::ctrl_c())
        .try_for_each(|client_conn| async {
            if let Ok(peer_addr) = client_conn.peer_addr() {
                info!(%peer_addr, "new connection");
            }
            let pods = pods.clone();
            tokio::spawn(async move {
                if let Ok(master_name) = master_name(pods.clone()).await {
                    if let Err(e) =
                        forward_connection(&pods, &master_name, pod_port, client_conn).await
                    {
                        error!(
                            error = e.as_ref() as &dyn std::error::Error,
                            "failed to forward connection"
                        );
                    }
                } else {
                    error!("Unable to determine the correct master");
                }
            });
            // keep the server running
            Ok(())
        });

    Ok(server.await?)
}
