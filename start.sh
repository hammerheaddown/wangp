#!/usr/bin/env bash
# Launches WanGP on boot.
#
# Code + Python deps are baked into the image at /opt/Wan2GP (no reinstall).
# Your persistent data lives on the network volume mounted at /workspace.
#
# Your existing volume already has a full Wan2GP checkout at /workspace/Wan2GP
# from the original install, including:
#   /workspace/Wan2GP/loras    (your IC-LoRAs, incl. loras/ltx2)
#   /workspace/Wan2GP/ckpts    (downloaded model weights)
#   /workspace/Wan2GP/outputs  (generated videos)
#
# We point the BAKED repo's data dirs at those volume folders via symlinks so
# everything you've already downloaded is reused and new files persist. Nothing
# re-downloads.
set -euo pipefail

BAKED=/opt/Wan2GP
VOL=/workspace
VOLREPO="$VOL/Wan2GP"          # your existing checkout on the volume

# --- Resolve persistent data dirs -------------------------------------------
# Prefer the dirs in your existing volume checkout; create them if missing so a
# brand-new volume still works.
LORAS_DIR="$VOLREPO/loras"
CKPTS_DIR="$VOLREPO/ckpts"
OUTPUTS_DIR="$VOLREPO/outputs"
SETTINGS_DIR="$VOL/settings"

mkdir -p "$LORAS_DIR" "$CKPTS_DIR" "$OUTPUTS_DIR" "$SETTINGS_DIR"

# --- Link volume data into the baked repo -----------------------------------
# -n so we replace any dir/symlink the image shipped with, pointing it at the
# volume instead. The whole loras tree is linked, so loras/ltx2 (and any other
# family subfolders you add later) come across automatically.
ln -sfn "$LORAS_DIR"   "$BAKED/loras"
ln -sfn "$CKPTS_DIR"   "$BAKED/ckpts"
ln -sfn "$OUTPUTS_DIR" "$BAKED/outputs"

cd "$BAKED"

export HF_HUB_ENABLE_HF_TRANSFER=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# --listen binds 0.0.0.0 so the RunPod proxy on :7860 can reach it.
# Port 7860 is exposed in the template, so no --share needed.
exec python wgp.py \
    --listen \
    --server-port 7860 \
    --settings "$SETTINGS_DIR"
