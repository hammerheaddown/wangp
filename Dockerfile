# WanGP RunPod template
# Bakes Wan2GP + mmgp + all Python deps INTO the image so a fresh pod boots
# ready in seconds. Models stay on your network volume (mounted at /workspace),
# so the image stays lean. Port 7860 is exposed for the RunPod HTTP proxy.

FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    PIP_NO_CACHE_DIR=1

# System deps (ffmpeg for video, git for the clone, build tools for any wheels)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ffmpeg build-essential ninja-build tmux \
    && rm -rf /var/lib/apt/lists/*

# Clone Wan2GP into the IMAGE (not the volume) so deps and code ship together.
# At runtime your volume mounts at /workspace; this lives at /opt instead.
WORKDIR /opt
RUN git clone --depth=1 https://github.com/deepbeepmeep/Wan2GP.git

WORKDIR /opt/Wan2GP

# Install all WanGP requirements (this is what pulls mmgp, gradio, etc.)
# torch is already in the base image, so we don't reinstall it.
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir hf_transfer "huggingface_hub[cli]"

# Copy the launch script in and make it executable
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 7860

CMD ["/opt/start.sh"]
