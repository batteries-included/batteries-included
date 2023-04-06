pub trait TracingFilterExt {
    fn to_tracing_subscriber_filter(&self) -> tracing_subscriber::filter::LevelFilter;
}

impl TracingFilterExt for tracing::log::LevelFilter {
    fn to_tracing_subscriber_filter(&self) -> tracing_subscriber::filter::LevelFilter {
        match self {
            tracing::log::LevelFilter::Off => tracing_subscriber::filter::LevelFilter::OFF,
            tracing::log::LevelFilter::Error => tracing_subscriber::filter::LevelFilter::ERROR,
            tracing::log::LevelFilter::Warn => tracing_subscriber::filter::LevelFilter::WARN,
            tracing::log::LevelFilter::Info => tracing_subscriber::filter::LevelFilter::INFO,
            tracing::log::LevelFilter::Debug => tracing_subscriber::filter::LevelFilter::DEBUG,
            tracing::log::LevelFilter::Trace => tracing_subscriber::filter::LevelFilter::TRACE,
        }
    }
}
