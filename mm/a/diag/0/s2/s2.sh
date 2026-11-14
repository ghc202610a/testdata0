#!/usr/bin/env bash

set -u
umask 077

OUT="$HOME/audio-diagnostics/stage2_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$OUT"

echo "Output: $OUT"

run() {
    local name="$1"
    shift

    echo "Collecting $name"

    "$@" > "$OUT/$name" 2>&1 || true
}

echo "=== FILTER CHAIN PROCESS ==="

ps -ww -eo pid,ppid,user,lstart,stat,args \
    | grep -E '[p]ipewire|[w]ireplumber' \
    > "$OUT/audio_processes.txt"

run filter_chain_pid.txt \
    pgrep -af 'pipewire.*filter-chain'

echo "=== SYSTEMD USER SERVICES ==="

run user_units.txt \
    systemctl --user list-units --all

run user_unit_files.txt \
    systemctl --user list-unit-files

echo "=== FILTER CHAIN SERVICE DETAILS ==="

for pid in $(pgrep -f '/usr/bin/pipewire -c filter-chain.conf' || true); do

    [[ -d "/proc/$pid" ]] || continue

    mkdir -p "$OUT/process_$pid"

    cat "/proc/$pid/cmdline" \
        > "$OUT/process_$pid/cmdline.txt"

    cat "/proc/$pid/status" \
        > "$OUT/process_$pid/status.txt"

    cat "/proc/$pid/maps" \
        > "$OUT/process_$pid/maps.txt"

    readlink "/proc/$pid/exe" \
        > "$OUT/process_$pid/executable.txt"

    readlink "/proc/$pid/cwd" \
        > "$OUT/process_$pid/working_directory.txt"

    tr '\0' '\n' < "/proc/$pid/environ" \
        > "$OUT/process_$pid/environment.txt" 2>/dev/null || true

    pstree -aps "$pid" \
        > "$OUT/process_$pid/parent_tree.txt" 2>&1 || true

    if command -v systemctl >/dev/null; then
        systemctl --user status "$pid" \
            > "$OUT/process_$pid/systemd_status.txt" 2>&1 || true
    fi

done

echo "=== PIPEWIRE CONFIGURATION REFERENCES ==="

for dir in \
    "$HOME/.config/pipewire" \
    "$HOME/.config/wireplumber" \
    /etc/pipewire \
    /usr/share/pipewire
do

    [[ -d "$dir" ]] || continue

    safe=$(echo "$dir" | tr '/' '_')

    find "$dir" -type f \
        -printf '%p\n' \
        > "$OUT/${safe}_files.txt"

    grep -RInE \
        'filter.chain|filter-chain|libpipewire-module-filter-chain' \
        "$dir" \
        > "$OUT/${safe}_filter_references.txt" 2>&1 || true

done

echo "=== ALSA MIXER ==="

run mixer_current.txt amixer -c 0 contents

echo "=== CODEC PIN STATUS ==="

if [[ -r /proc/asound/card0/codec#0 ]]; then
    cp /proc/asound/card0/codec#0 "$OUT/codec.txt"

    grep -n -A18 -E \
        'Node 0x18|Node 0x19|Node 0x1a|Node 0x1b' \
        "$OUT/codec.txt" \
        > "$OUT/relevant_codec_pins.txt"
fi

echo "=== PIPEWIRE INVENTORY ==="

run pw_nodes.txt pw-cli ls Node
run pw_modules.txt pw-cli ls Module
run pw_status.txt wpctl status -n

echo "=== EXECUTABLE PACKAGE VERIFICATION ==="

if command -v dpkg-query >/dev/null; then
    dpkg-query -S /usr/bin/pipewire \
        > "$OUT/pipewire_package.txt" 2>&1 || true

    dpkg-query -W pipewire pipewire-bin \
        >> "$OUT/pipewire_package.txt" 2>&1 || true
fi

echo "=== FILE HASHES ==="

sha512sum /usr/bin/pipewire \
    /usr/bin/wireplumber \
    /usr/bin/pipewire-pulse \
    > "$OUT/executable_hashes.txt" 2>&1 || true

echo "=== COMPLETE ==="

tar -czf "$OUT.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"

echo "Report: $OUT"
echo "Archive: $OUT.tar.gz"
