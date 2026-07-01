#!/bin/bash
# Resolve ROCm installation root for build scripts.
#
# ROCm 7.2 and earlier: typically /opt/rocm
# ROCm 7.12+: installed in the Python environment; use `rocm-sdk path --root`
#
# Usage (source from another script):
#   source "$(dirname "${BASH_SOURCE[0]}")/resolve_rocm_root.sh"
#   ROCM_ROOT="$(resolve_rocm_root)" || exit 1
#
# Or run directly:
#   ./resolve_rocm_root.sh

resolve_rocm_root() {
    local root=""

    if [[ -n "${ROCM_PATH:-}" && -d "${ROCM_PATH}" ]]; then
        echo "${ROCM_PATH}"
        return 0
    fi
    if [[ -n "${ROCM_HOME:-}" && -d "${ROCM_HOME}" ]]; then
        echo "${ROCM_HOME}"
        return 0
    fi

    if command -v rocm-sdk &>/dev/null; then
        root="$(rocm-sdk path --root 2>/dev/null || true)"
        if [[ -n "$root" && -d "$root" ]]; then
            echo "$root"
            return 0
        fi
    fi

    if [[ -d /opt/rocm ]]; then
        echo "/opt/rocm"
        return 0
    fi

    echo "Error: Could not determine ROCm root. Set ROCM_PATH, install rocm-sdk via pip, or install ROCm to /opt/rocm." >&2
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    resolve_rocm_root
fi
