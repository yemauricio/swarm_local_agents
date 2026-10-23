# Distributed Linux Agent Platform

Linux-only, llama.cpp-based bootstrap for ordinary PCs/laptops.

Architecture:

```text
User/UI -> Supervisor -> Linux workers
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

`auto` selects coordinator when an GPU with >=8 GB VRAM is detected, otherwise worker.
Models are GGUF files placed in `models/`. The installer does not hard-code model download URLs.
llama.cpp is built locally. CUDA is enabled automatically when `nvcc` and an NVIDIA GPU are available.
Ollama by default
