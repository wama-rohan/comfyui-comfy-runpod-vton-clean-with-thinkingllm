# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN comfy node install --exit-on-fail lanpaint@1.4.10 --mode remote || (echo "WARN: lanpaint@1.4.10 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail lanpaint --mode remote)
RUN comfy node install --exit-on-fail comfyui-thinkingllm

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/jiangchengchengNLP/qwen3-4b-fp8-scaled/resolve/main/qwen3_4b_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'qwen3_4b_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors' --relative-path models/vae --filename 'flux2-vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/YuCollection/FLUX.2-klein-4B-bf16/resolve/main/flux-2-klein-4b.safetensors' --relative-path models/diffusion_models --filename 'flux-2-klein-4b-bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/male-model-photography-male-model-portfolio-shoot-in-delhi-noida-gurgaon-gurugram-2_orig.jpg' "https://cool-anteater-319.convex.cloud/api/storage/98bc207e-b9d4-400a-9735-6da7d78dbedc"
RUN wget --progress=dot:giga -O '/comfyui/input/model.webp' "https://cool-anteater-319.convex.cloud/api/storage/e38c01d9-0326-4a11-a8f8-f0a7440974f4"
