#![deny(clippy::all)]
#![deny(clippy::nursery)]
#![warn(
    missing_debug_implementations,
    rust_2018_idioms,
    unreachable_pub,
    bad_style,
    const_err,
    dead_code,
    improper_ctypes,
    non_shorthand_field_patterns,
    no_mangle_generic_items,
    overflowing_literals,
    path_statements,
    patterns_in_fns_without_body,
    private_in_public,
    unconditional_recursion,
    unused,
    unused_allocation,
    unused_comparisons,
    unused_parens,
    while_true
)]
#![allow(clippy::use_self)]

pub mod cluster_spec;
pub mod error;
pub mod labels;
pub mod logging;
pub mod namespace;
pub mod permissions;

pub use k8s_openapi;