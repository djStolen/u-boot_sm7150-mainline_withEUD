# SM7150 Fastboot-Only U-Boot (EUD Lifeline) 🚀

This repository contains build scripts, configs, and patches for producing a
**fastboot-only U-Boot** image for Qualcomm SM7150 devices (e.g. Xiaomi Surya),
with **EUD (Emergency USB Download)** kept alive at all times.

The primary goal is **USB survivability**:
> Even if fastboot exits, errors out, or is interrupted, USB must stay up.

This is *not* a general-purpose U-Boot build.  
It is a **lifeline bootloader** designed to be hard to brick.

---

## Design Goals 🎯

- Boot directly into fastboot
- Never fall through to a shell or boot command
- Never power down the USB PHY
- Keep EUD enabled so the device always enumerates over USB
- Minimize subsystems that could tear down USB or reboot the device

Non-goals:
- Booting Linux or Android
- EFI boot
- Capsule updates (in EUD-only builds)
- Clean shutdown or resource teardown

If something looks “leaky” or “wrong” by normal U-Boot standards, it is probably
**intentional**.

---

## Main Inspiration 💡

The core idea behind this repository is heavily inspired by Linaro’s work on
**Qualcomm EUD (Emergency USB Download)** as a hidden-but-powerful hardware
debug and recovery mechanism.

In particular, this article was foundational:

https://www.linaro.org/blog/hidden-jtag-qualcomm-snapdragon-usb/

That write-up demonstrates how Qualcomm Snapdragon platforms can expose deep
debug and recovery functionality purely over USB, without physical JTAG access.
This project applies the same philosophy to U-Boot:

> Keep USB alive at all costs, and the device stays recoverable.

---

## Repository Contents 📂

- **Build scripts** 🛠️
  - Fetch and build `mkbootimg`
  - Fetch and build Qualcomm SM7150 U-Boot
  - Assemble an Android-compatible `boot.img`

- **Config overlays** ⚙️
  - `tauchgang-eud-only.config` — Minimal, fastboot-only, USB-never-dies
  - `tauchgang-efi.config` — Full-featured EFI-capable (optional/future)

- **Patches** 📝
  - Fastboot behavior changes to prevent USB gadget teardown
  - Qualcomm EUD enablement fixes

---

## Fastboot Exit Patch (Why It Exists) ⚡

One critical patch modifies `cmd/fastboot.c` so that fastboot **never runs its
cleanup path**:

```diff
 ret = CMD_RET_SUCCESS;

+return 0;
+
 exit:
     udc_device_put(udc);
     g_dnl_unregister();
     g_dnl_clear_detach();
