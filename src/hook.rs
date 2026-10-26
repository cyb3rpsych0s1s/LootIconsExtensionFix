//! Hook for [HasLootableItems](https://nativedb.red4ext.com/gamePuppet#HasLootableItems).

use red4ext_rs::{
    RttiSystem, SdkEnv, VoidPtr, addr_hashes, hooks,
    log::{error, info},
    types::{CName, IScriptable, StackFrame, WeakRef},
};
use red4ext_rs_bindings::ScriptedPuppet;

/// Corresponding hash on:
/// - `2.12a`: `0x141117628`
/// - `2.13`:  `0x1411C26D8`
const OFFSET: u32 = 0x362B23C7;
const NAME: &str = "gamePuppet.HasLootableItems";

hooks! {
   static HOOK: fn(i: *mut IScriptable, f: *mut StackFrame, a3: VoidPtr, a4: VoidPtr) -> ();
}

fn target() -> Option<unsafe extern "C" fn(*mut IScriptable, *mut StackFrame, VoidPtr, VoidPtr)> {
    let addr = addr_hashes::resolve(OFFSET);
    (addr != 0).then(|| unsafe { std::mem::transmute::<usize, _>(addr) })
}

pub(super) fn attach_hook(env: &SdkEnv) {
    let Some(target) = target() else {
        return red4ext_rs::log::warn!("unable to resolve {NAME} ({:#X}), not hooked", OFFSET);
    };
    unsafe { env.attach_hook(HOOK, target, detour) };
    red4ext_rs::log::info!("attached native internal hook for {NAME}",);
}

pub(super) fn detach_hook(env: &SdkEnv) {
    let Some(target) = target() else {
        return;
    };
    unsafe { env.detach_hook(target) };
    info!("detached native internal hook for {NAME}");
}

unsafe extern "C" fn detour(
    i: *mut IScriptable,
    f: *mut StackFrame,
    a3: VoidPtr,
    a4: VoidPtr,
    cb: unsafe extern "C" fn(i: *mut IScriptable, f: *mut StackFrame, a3: VoidPtr, a4: VoidPtr),
) {
    // save stack frame args state
    let frame = unsafe { &mut *f };
    let state = frame.args_state();

    #[cfg(debug_assertions)]
    info!("intercepted HasLootableItems!");

    // read stack frame arg
    let puppet: WeakRef<ScriptedPuppet> = unsafe { StackFrame::get_arg(frame) };

    // retrieve Redscript method
    let func_name = "LootIconsExtensionFix.HasLootableItems";
    let rtti = RttiSystem::get();
    let funcs = rtti.get_global_functions();
    let func = funcs
        .iter()
        .find(|x| x.short_name() == CName::new(func_name))
        .unwrap();

    // call Redscript method
    match func.execute::<_, bool>(None, (puppet,)) {
        Ok(has) => {
            let out = a3 as *mut bool;
            unsafe { *out = has };

            #[cfg(debug_assertions)]
            info!("wrote LootIconsExtensionFix.HasLootableItems()'s output successfully: {has}");
        }
        // if detouring fails, fallback to vanilla method
        Err(e) => {
            unsafe {
                // restore stack frame args
                frame.restore_args(state);

                cb(i, f, a3, a4);
            }

            error!("unable to call {func_name}: {e}");
        }
    };
}
