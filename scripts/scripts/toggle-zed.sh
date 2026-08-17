#!/usr/bin/env bash
# Win+C. Zed is native (Rust/GPUI) rather than Electron, which is the whole
# reason it has this bind instead of VS Code.
exec toggle-app app_id dev.zed.Zed zeditor
