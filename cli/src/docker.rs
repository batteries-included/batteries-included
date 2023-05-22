use std::{collections::HashMap, str::FromStr};

use bollard::{network::ListNetworksOptions, service::Network, Docker};
use eyre::Result;
use ipnet::Ipv4Net;

use crate::spec::IPAddressPoolSpec;

pub async fn get_kind_ip_address_pools() -> Result<Vec<IPAddressPoolSpec>> {
    let docker = Docker::connect_with_local_defaults()?;
    let filters = HashMap::from([("name", vec!["kind"])]);
    let options = ListNetworksOptions { filters };
    let networks = docker.list_networks(Some(options)).await?;
    Ok(networks.into_iter().flat_map(to_ip_pool).collect())
}

fn to_ip_pool(net: Network) -> Option<IPAddressPoolSpec> {
    net.ipam
        .into_iter()
        .flat_map(|ipam| ipam.config)
        .flatten()
        .flat_map(|c| c.subnet) // For each config we only need the subnet
        .flat_map(|subnet| Ipv4Net::from_str(&subnet).ok()) // Try and parse the IPv4 only subnet.
        .flat_map(|ip_sub| ip_sub.subnets(ip_sub.prefix_len() + 1).ok())
        .flat_map(|subnets| subnets.last())
        .map(|usable_subnet| IPAddressPoolSpec {
            name: "kind".to_string(),
            subnet: usable_subnet.to_string(),
            id: None,
            inserted_at: None,
            updated_at: None,
        })
        .next()
}
