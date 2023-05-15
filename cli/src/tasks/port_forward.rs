use std::net::SocketAddr;

use eyre::{Context, ContextCompat, Result};
use futures::{StreamExt, TryStreamExt};
use k8s_openapi::api::core::v1::Pod;
use kube_client::{Api, Client};
use tokio::io::{AsyncRead, AsyncWrite};
use tokio::net::TcpListener;
use tokio_stream::wrappers::TcpListenerStream;

use tracing::{debug, info, warn};

use crate::postgres_kube::master_name;

pub async fn port_forward(kube_client: Client, namespace: &str) -> Result<()> {
    info!("Starting port forward");
    let pods: Api<Pod> = Api::namespaced(kube_client, namespace);
    // Get and wait for the master name.
    //
    // This allows us to pause before bringing up the port-forwarder
    let initial_master_name = master_name(pods.clone()).await?;
    info!("Initial master pods name = {:?}", initial_master_name);
    run_server(pods).await
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
    debug!("connection closed");
    Ok(())
}

async fn run_server(pods: Api<Pod>) -> Result<()> {
    let addr = SocketAddr::from(([127, 0, 0, 1], 5432));
    let pod_port = 5432;
    info!(local_addr = %addr, pod_port, "forwarding traffic to the pod");
    let server = TcpListenerStream::new(TcpListener::bind(addr).await?)
        .take_until(tokio::signal::ctrl_c())
        .try_for_each(|client_conn| async {
            if let Ok(peer_addr) = client_conn.peer_addr() {
                debug!(%peer_addr, "new connection");
            }
            let pods = pods.clone();
            tokio::spawn(async move {
                if let Ok(master_name) = master_name(pods.clone()).await {
                    if let Err(e) =
                        forward_connection(&pods, &master_name, pod_port, client_conn).await
                    {
                        warn!(
                            error = e.as_ref() as &dyn std::error::Error,
                            "failed to forward connection"
                        );
                    }
                } else {
                    warn!("Unable to determine the correct master");
                }
            });
            // keep the server running
            Ok(())
        });
    server
        .await
        .context("TCP Echo server expected to run until ctrl-c")
}
