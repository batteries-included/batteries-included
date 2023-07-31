use std::path::{Path, PathBuf};

use eyre::{Context, Result};
use std::os::unix::fs::PermissionsExt;
use tempfile::NamedTempFile;

use crate::operating_system;

const KIND_URL_BASE: &str = "https://github.com/kubernetes-sigs/kind/releases/download";
const KIND_VER: &str = "v0.18.0";

const XDG_BASE: &str = ".config/batteriesincluded";
const BIN_PATH: &str = "bin";

pub async fn install_kind(dir_parent: &Path, arch: &str) -> Result<PathBuf> {
    let bin_path = ensure_battery_bin(dir_parent)?;
    ensure_kind_binary(&bin_path, arch).await
}

fn ensure_battery_bin(dir_parent: &Path) -> Result<PathBuf> {
    let bin_path = std::path::Path::new(dir_parent)
        .join(XDG_BASE)
        .join(BIN_PATH);
    std::fs::create_dir_all(bin_path.clone())?;
    Ok(bin_path)
}

async fn ensure_kind_binary(bin_path: &Path, arch: &str) -> Result<PathBuf> {
    let kind_path = bin_path.join(format!("kind-{}", KIND_VER));
    if !kind_path.exists() {
        let os = operating_system::detect();
        let kind_arch = to_kind_arch(arch);
        download_kind(&kind_path, &os.to_string(), &kind_arch).await?;
    }
    Ok(kind_path)
}

async fn download_kind(kind_path: &Path, os: &str, arch: &str) -> Result<()> {
    let url = format!("{}/{}/kind-{}-{}", KIND_URL_BASE, KIND_VER, os, arch);
    download_to(&url, kind_path).await
}

fn to_kind_arch(arch: &str) -> String {
    let lower = arch.to_ascii_lowercase();
    match lower.as_str() {
        "x86_64" => "amd64".to_owned(),
        _ => lower,
    }
}

async fn download_to(url: &str, to: &Path) -> Result<()> {
    // Start the download.
    let response = reqwest::get(url)
        .await
        .context("Downloading binary to install it.")?;
    // Create a temporary file that we'll use to get the body and then atomically rename it after we're done
    let mut file = NamedTempFile::new()?;
    let contents = response
        .error_for_status()
        .context("Downloading contents of the remote binary")?
        .bytes()
        .await?;
    // Copy all the bytes.
    std::io::copy(&mut contents.as_ref(), &mut file.as_file_mut())?;

    // Now atomically rename the file.
    if file.persist(to).is_err() {
        // If this failed then copy over.
        std::fs::write(to, contents)?;
    }

    // Set the permissions.
    //
    // There's a problem here. It's possible that the download and write will work
    // then the chmod won't. This will leave us in a broken state.
    std::fs::set_permissions(to, std::fs::Permissions::from_mode(0o755))?;
    Ok(())
}
