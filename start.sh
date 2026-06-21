#!/usr/bin/env bash
# Launches WanGP on boot. The code + deps live baked in at /opt/Wan2GP.
# Your persistent data (models, loras, outputs) lives on the volume at
# /workspace. We symlink the volume dirs into the baked repo so models you've
# already downloaded are reused and new ones persist across pod restarts.
set -euo pipefail

BAKED=/opt/Wan2GP
VOL=/workspace

# Persistent dirs on the volume (created once, survive restarts)
mkdir -p "$VOL/models/wan2gp" "$VOL/loras" "$VOL/outputs" "$VOL/settings"

# Point the baked repo's data dirs at the volume.
# ckpts = downloaded model weights (the big stuff you don't want to re-pull)
ln -sfn "$VOL/models/wan2gp" "$BAKED/ckpts"
ln -sfn "$VOL/loras"         "$BAKED/loras"
ln -sfn "$VOL/outputs"       "$BAKED/outputs"

cd "$BAKED"

export HF_HUB_ENABLE_HF_TRANSFER=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# --listen binds 0.0.0.0 so the RunPod proxy on :7860 can reach it.
# No --share needed once the port is exposed in the template (which it is).
# Add --share back here only if you ever want the gradio.live fallback too.
exec python wgp.py \
    --listen \
    --server-port 7860 \
    --settings "$VOL/settings"
