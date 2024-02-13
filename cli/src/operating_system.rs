pub enum OS {
    Linux,
    #[allow(clippy::enum_variant_names)]
    MacOS,
    Windows,
    Unknown,
}

impl std::fmt::Display for OS {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OS::Linux => write!(f, "Linux"),
            OS::MacOS => write!(f, "MacOS"),
            OS::Windows => write!(f, "Windows"),
            OS::Unknown => write!(f, "Unknown"),
        }
    }
}

pub fn detect() -> OS {
    if cfg!(target_os = "linux") {
        OS::Linux
    } else if cfg!(target_os = "macos") {
        OS::MacOS
    } else if cfg!(target_os = "windows") {
        OS::Windows
    } else {
        OS::Unknown
    }
}
