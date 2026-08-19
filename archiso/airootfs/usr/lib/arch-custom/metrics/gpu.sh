#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Arch Custom — GPU Metrics Collector
# Detects GPU type and reads usage via sysfs (AMD/NVIDIA/Intel).
# ═══════════════════════════════════════════════════════════════════

declare -g _GPU_TYPE="none"
declare -g _GPU_PATH=""

# Detect GPU type on first call
gpu_detect() {
    [[ "$_GPU_TYPE" != "none" ]] && return

    # AMD GPU (amdgpu)
    if [[ -d /sys/class/drm/card0/device/pp_dpm_sclk ]] || ls /sys/class/drm/card*/device/vendor 2>/dev/null | head -1 | grep -q "0x1002"; then
        _GPU_TYPE="amd"
        _GPU_PATH="/sys/class/drm/card0/device"
        return
    fi

    # NVIDIA (via nvidia-smi or sysfs)
    if command -v nvidia-smi &>/dev/null; then
        _GPU_TYPE="nvidia"
        return
    fi

    # Intel GPU
    if ls /sys/class/drm/card*/device/vendor 2>/dev/null | head -1 | grep -q "0x8086"; then
        _GPU_TYPE="intel"
        _GPU_PATH="/sys/class/drm/card0/device"
        return
    fi

    _GPU_TYPE="none"
}

# Get GPU usage percentage
gpu_get_usage() {
    gpu_detect

    case "$_GPU_TYPE" in
        amd)
            local busy_file="$_GPU_PATH/gpu_busy_percent"
            if [[ -f "$busy_file" ]]; then
                cat "$busy_file" 2>/dev/null || echo "N/A"
            else
                echo "N/A"
            fi
            ;;
        nvidia)
            nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "N/A"
            ;;
        intel)
            # Intel doesn't provide easy GPU usage via sysfs
            echo "N/A"
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

# Get GPU name
gpu_get_name() {
    gpu_detect

    case "$_GPU_TYPE" in
        amd)
            local card
            card=$(ls /sys/class/drm/ 2>/dev/null | grep "^card[0-9]" | head -1)
            if [[ -n "$card" ]]; then
                local uevent="/sys/class/drm/$card/device/uevent"
                if [[ -f "$uevent" ]]; then
                    grep "PCI_ID" "$uevent" 2>/dev/null | cut -d= -f2 || echo "AMD GPU"
                else
                    echo "AMD GPU"
                fi
            else
                echo "AMD GPU"
            fi
            ;;
        nvidia)
            nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "NVIDIA GPU"
            ;;
        intel)
            echo "Intel GPU"
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

# Get GPU memory usage
gpu_get_memory() {
    gpu_detect

    case "$_GPU_TYPE" in
        amd)
            local vram_used vram_total
            vram_used=$(cat "$_GPU_PATH/mem_info_vram_used" 2>/dev/null || echo "0")
            vram_total=$(cat "$_GPU_PATH/mem_info_vram_total" 2>/dev/null || echo "0")
            if [[ "$vram_total" -gt 0 ]]; then
                echo "$((vram_used / 1048576))M / $((vram_total / 1048576))M"
            else
                echo "N/A"
            fi
            ;;
        nvidia)
            nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null | head -1 || echo "N/A"
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

# Get GPU temperature
gpu_get_temp() {
    gpu_detect

    case "$_GPU_TYPE" in
        amd)
            local temp_file="$_GPU_PATH/hwmon/hwmon*/temp1_input"
            local temp
            temp=$(cat $temp_file 2>/dev/null | head -1 || echo "0")
            if [[ "$temp" -gt 0 ]]; then
                echo "$((temp / 1000))°C"
            else
                echo "N/A"
            fi
            ;;
        nvidia)
            nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1 | xargs -I{} echo "{}°C" || echo "N/A"
            ;;
        *)
            echo "N/A"
            ;;
    esac
}
