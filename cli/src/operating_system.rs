pub enum OS {
    Linux,
    #[allow(clippy::enum_variant_names)]
    MacOS,
    Windows,
    Unknown,
}

impl ToString for OS {
    fn to_string(&self) -> String {
        match self {
            OS::Linux => "linux".to_owned(),
            OS::MacOS => "darwin".to_owned(),
            _ => "unknown".to_owned(),
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
