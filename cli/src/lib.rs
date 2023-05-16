#![feature(exit_status_error)]
#![feature(async_closure)]

pub mod args;
pub mod commands;
mod docker;
mod install_bin;
mod kind;
pub mod logging;
mod operating_system;
mod postgres_kube;
mod spec;
pub mod tasks;
