//! LootIconsExtensionFix
//!
//! ```swift
#![doc = include_str!("../reds/LootIconsExtensionFix.reds")]
//! ```

include!(concat!(env!("OUT_DIR"), "/version.rs"));

use hook::{attach_hook, detach_hook};
use red4ext_rs::{
    ExportNil, Exportable, Plugin, SdkEnv, SemVer, U16CStr, export_plugin_symbols, wcstr,
};

mod hook;

pub struct LootIconsExtensionFix;

impl Plugin for LootIconsExtensionFix {
    const NAME: &'static U16CStr = wcstr!("LootIconsExtensionFix");
    const AUTHOR: &'static U16CStr = wcstr!("Demon9ne + Roms1383");
    const VERSION: SemVer = PLUGIN_VERSION;

    fn on_load(env: &SdkEnv) {
        attach_hook(env);
    }

    fn on_unload(env: &SdkEnv) {
        detach_hook(env);
    }

    fn exports() -> impl Exportable {
        ExportNil
    }
}

export_plugin_symbols!(LootIconsExtensionFix);
