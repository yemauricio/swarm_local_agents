# Distributed Linux Agent Platform

Linux-only, llama.cpp-based bootstrap for ordinary PCs/laptops.

Architecture:

```text
User/UI -> Big Linux coordinator (Qwen + llama.cpp) -> Linux workers
```

Install on any Linux machine:

```bash
./deploy/install.sh auto
```

Or explicitly:

```bash
./deploy/install.sh coordinator
./deploy/install.sh worker
```

`auto` selects coordinator when an NVIDIA GPU with >=8 GB VRAM is detected, otherwise worker.

Models are GGUF files placed in `models/`. The installer does not hard-code model download URLs.

llama.cpp is built locally. CUDA is enabled automatically when `nvcc` and an NVIDIA GPU are available.

The next scaling layer should add registration, heartbeat, capability discovery, scheduling, and node approval.
