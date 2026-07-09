# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN git clone https://github.com/scraed/LanPaint /comfyui/custom_nodes/LanPaint
RUN git clone https://github.com/goodguy1963/ComfyUI-ThinkingLLM.git /comfyui/custom_nodes/comfyui-thinkingllm

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/jiangchengchengNLP/qwen3-4b-fp8-scaled/resolve/main/qwen3_4b_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'qwen3_4b_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors' --relative-path models/vae --filename 'flux2-vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/YuCollection/FLUX.2-klein-4B-bf16/resolve/main/flux-2-klein-4b.safetensors' --relative-path models/diffusion_models --filename 'flux-2-klein-4b-bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# Upgrade transformers library so that it knows how to read gemma4 architectures
RUN pip install --no-cache-dir --upgrade transformers accelerate

# =====================================================================
# DOWNLOAD VIA HUGGING FACE BUCKET (PUBLIC) TO Qwen-VL PATH
# =====================================================================
# 1. Install the Hugging Face CLI tool inside the image layer
RUN curl -LsSf https://hf.co/cli/install.sh | bash

# 2. Add both common fallback execution bins directly to the system environment path
ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"

# 3. Setup destination and sync the bucket contents using the discovered 'hf' binary path
RUN mkdir -p /comfyui/models/LLM/Qwen-VL/gemma-4-E2B-it && \
    hf sync hf://buckets/wamarohan/gemma-4-E2B-it-bucket /comfyui/models/LLM/Qwen-VL/gemma-4-E2B-it

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/male-model-photography-male-model-portfolio-shoot-in-delhi-noida-gurgaon-gurugram-2_orig.jpg' "https://cool-anteater-319.convex.cloud/api/storage/98bc207e-b9d4-400a-9735-6da7d78dbedc"
RUN wget --progress=dot:giga -O '/comfyui/input/model.webp' "https://cool-anteater-319.convex.cloud/api/storage/e38c01d9-0326-4a11-a8f8-f0a7440974f4"
