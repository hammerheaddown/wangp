# WanGP RunPod Template — built & hosted via GitHub (no local Docker needed)

Kills the reinstall-on-boot cycle. GitHub Actions builds the image for free and
stores it at `ghcr.io`, then RunPod pulls it. You never install Docker locally
and never wait for pip reinstalls on a fresh pod again. Models stay on your
network volume, so the image stays lean (~8-10 GB).

---

## Repo layout

Put these three files in a new GitHub repo (e.g. `hammerheaddown/wangp`):

```
wangp/
├── Dockerfile
├── start.sh
└── .github/
    └── workflows/
        └── build.yml      <-- the build.yml file goes HERE
```

IMPORTANT: `build.yml` must live at `.github/workflows/build.yml` or GitHub
won't run it.

---

## Step 1 — Create the repo and push the files

No command line needed: github.com → New repository → name it `wangp` → Create.
Then "Add file → Upload files" to drag in `Dockerfile` and `start.sh`. For the
workflow, click "Add file → Create new file", type
`.github/workflows/build.yml` as the filename (the slashes auto-create the
folders), paste the contents, and commit.

Or via git:

```bash
git clone https://github.com/hammerheaddown/wangp.git
cd wangp
mkdir -p .github/workflows
# copy Dockerfile and start.sh into wangp/
# copy build.yml into .github/workflows/
git add .
git commit -m "WanGP RunPod template"
git push
```

---

## Step 2 — Let the build run

The moment you push, open the repo's **Actions** tab. The `build-wangp-image`
workflow runs (clones Wan2GP, pip-installs everything once — a few minutes).
When it's green, your image exists at:

```
ghcr.io/hammerheaddown/wangp:latest
```

If a run fails, open it to read the log. The workflow already frees disk space
up front, which is the usual culprit for large CUDA images.

---

## Step 3 — Make the image public (one time)

GHCR images start private. To let RunPod pull it without credentials:

1. GitHub profile → **Packages** tab → click `wangp`.
2. **Package settings** → **Danger Zone** → **Change visibility** → **Public**.

(Or keep it private and add GHCR credentials in RunPod's template — but public
is simpler for a personal tool.)

---

## Step 4 — Create the RunPod template

RunPod console → **Templates → New Template**:

| Field | Value |
|---|---|
| Name | `wangp` |
| Container Image | `ghcr.io/hammerheaddown/wangp:latest` |
| Container Disk | `20` GB |
| Volume Mount Path | `/workspace` |
| Expose HTTP Ports | `7860`  ← gets you the clean proxy URL |
| Expose TCP Ports | `22` |
| Container Start Command | leave blank |

Optional env var:

| Key | Value |
|---|---|
| `HF_TOKEN` | your HuggingFace token (for gated downloads like the Lightricks IC-LoRAs) |

Baking `HF_TOKEN` here means future gated `wget`/`hf download` calls just work
without re-exporting it every session.

---

## Step 5 — Deploy

**Pods → Deploy** → pick GPU → choose the `wangp` template → **attach your
existing network volume** (the one with Wan2GP + your loras in
`/workspace/Wan2GP/loras/ltx2`) → Deploy.

The Connect panel now shows **HTTP Service [Port 7860]**. Click it:

```
https://<POD_ID>-7860.proxy.runpod.net
```

Boots in seconds, deps already present, clean URL, no `--share`, no SSH tunnel.

---

## Updating WanGP later

Push any change to the repo (or hit "Run workflow" on the Actions tab). GitHub
rebuilds and pushes `:latest`; redeploy on RunPod to pick it up.

To pin a specific Wan2GP version, edit the clone line in the Dockerfile:

```dockerfile
RUN git clone https://github.com/deepbeepmeep/Wan2GP.git && \
    cd Wan2GP && git checkout <COMMIT_SHA>
```

---

## Why this saves money

No GPU minutes burned on pip reinstalls each launch; boot-to-UI is seconds. You
only pay GPU rate while generating, and can spin down freely knowing the next
spin-up is instant.
