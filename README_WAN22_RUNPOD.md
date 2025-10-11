# WAN 2.2 RunPod Compute Template

A custom RunPod **COMPUTE** Docker template for WAN 2.2 video generation with CUDA 12.8, PyTorch 2.8, ComfyUI, ComfyUI Manager, WAN Video Wrapper, and JupyterLab.

**Template Type:** Compute (not serverless)
**ComfyUI:** Port 8188 (directly accessible)
**JupyterLab:** Port 8189 (full backend access)

## 🎯 Features

- **CUDA 12.8.1** - Latest CUDA support for Blackwell GPUs (RTX 5090, B200)
- **PyTorch 2.8.0** - Latest PyTorch with CUDA 12.8 support
- **Python 3.12** - Modern Python runtime
- **ComfyUI** - Latest version with full workflow support
- **SageAttention3** - Optimized attention mechanism for Blackwell GPUs (CRITICAL for performance)
- **ComfyUI Manager** - Easy custom node management
- **WAN Video Wrapper** - Complete WAN 2.2 video generation support
- **JupyterLab** - Full file system access for backend management
- **Pre-downloaded Models** - All WAN 2.2 models included (fp8 scaled for efficiency)

## 📦 What's Included

### Custom Nodes
- **ComfyUI-Manager** - Node package manager
- **ComfyUI-WanVideoWrapper** - WAN 2.2 video generation nodes

### Pre-installed Models
All models are downloaded during Docker build:

- **Text Encoders** (`/comfyui/models/text_encoders/`)
  - `t5xxl_fp8_e4m3fn.safetensors`
  - `clip_l.safetensors`

- **CLIP Vision** (`/comfyui/models/clip_vision/`)
  - `sigclip_vision_patch14_384.safetensors`

- **Transformer** (`/comfyui/models/diffusion_models/`)
  - `wan2.2_1.3B_fp8_scaled.safetensors` (main video model)

- **VAE** (`/comfyui/models/vae/`)
  - `wan_vae.safetensors`

### Services
- **ComfyUI API** - Port 8188 (with SageAttention3 enabled)
- **JupyterLab** - Port 8189 (full file system access)

## 🚀 Quick Start

### Option 1: Build Locally

```bash
# Clone this repository
git clone <your-repo-url>
cd Wan2.2_runpod

# Build the Docker image
docker build -f Dockerfile.wan22 -t wan22-runpod:latest .

# Run with docker-compose
docker-compose -f docker-compose.wan22.yml up -d
```

### Option 2: Deploy to RunPod (Compute Pod)

**Public Image Available:** `ghcr.io/lum3on/wan22-runpod:latest`

1. **Use Pre-built Image (Recommended)**
   - The image is already built and public on GitHub Container Registry
   - No need to build locally unless you want to customize

2. **Create RunPod Compute Template**
   - Go to [RunPod Console](https://www.runpod.io/console/pods)
   - Click "New Template" or use existing template
   - Set Docker Image: `ghcr.io/lum3on/wan22-runpod:latest`
   - Container Disk: 50 GB (minimum)
   - **Expose HTTP Ports:** `8188,8189` (CRITICAL!)
   - Environment Variables (optional):
     - `COMFY_LOG_LEVEL=DEBUG`

3. **Deploy Compute Pod**
   - Go to [RunPod Pods](https://www.runpod.io/console/pods)
   - Click "Deploy" or "New Pod"
   - Select your template
   - Configure GPU (RTX 5090 or B200 recommended for SageAttention3)
   - **Important:** Make sure ports 8188 and 8189 are exposed
   - Deploy!

4. **Access Your Services**
   - Once deployed, RunPod will provide you with connection URLs
   - **ComfyUI:** `https://<pod-id>-8188.proxy.runpod.net`
   - **JupyterLab:** `https://<pod-id>-8189.proxy.runpod.net`

## 🔧 Usage

### Accessing Services

After deployment on RunPod, you can access:

- **ComfyUI Interface**: `https://<pod-id>-8188.proxy.runpod.net`
- **JupyterLab**: `https://<pod-id>-8189.proxy.runpod.net`

**Note:** RunPod provides HTTPS proxy URLs for exposed ports. Replace `<pod-id>` with your actual pod ID.

### JupyterLab Access

JupyterLab provides full file system access to:
- `/comfyui/` - ComfyUI root directory
- `/comfyui/models/` - All model directories
- `/comfyui/custom_nodes/` - Custom nodes
- `/comfyui/output/` - Generated outputs
- `/comfyui/input/` - Input files

**Note**: JupyterLab is configured with no password for easy access. In production, consider adding authentication.

### Using ComfyUI

1. **Access the Web Interface:**
   - Open `https://<pod-id>-8188.proxy.runpod.net` in your browser
   - You'll see the ComfyUI interface
   - Load workflows from the WAN Video Wrapper examples

2. **Using the API:**
   ```bash
   # Get system stats
   curl https://<pod-id>-8188.proxy.runpod.net/system_stats

   # Submit a workflow (use ComfyUI's API format)
   curl -X POST https://<pod-id>-8188.proxy.runpod.net/prompt \
     -H "Content-Type: application/json" \
     -d '{"prompt": {...}}'
   ```

## 📁 Directory Structure

```
/comfyui/
├── models/
│   ├── text_encoders/      # T5 and CLIP text encoders
│   ├── clip_vision/        # CLIP vision models
│   ├── diffusion_models/   # WAN transformer models
│   ├── vae/                # VAE models
│   ├── checkpoints/        # Additional checkpoints
│   ├── loras/              # LoRA models
│   └── ...
├── custom_nodes/
│   ├── ComfyUI-Manager/
│   └── ComfyUI-WanVideoWrapper/
├── input/                  # Input files
├── output/                 # Generated outputs
└── workflows/              # Saved workflows
```

## 🎨 Example Workflows

Check the `example_workflows/` directory in the WAN Video Wrapper for sample workflows:
- Text-to-Video (T2V)
- Image-to-Video (I2V)
- Video-to-Video (V2V)
- Camera control
- And more!

## 🔍 Model Sources

All models are sourced from:
- **Main Models**: [Kijai/WanVideo_comfy](https://huggingface.co/Kijai/WanVideo_comfy)
- **FP8 Scaled Models**: [Kijai/WanVideo_comfy_fp8_scaled](https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled)

## 💾 Storage Requirements

- **Docker Image**: ~15-20 GB
- **Models**: ~10-15 GB (included in image)
- **Runtime**: 5-10 GB (for outputs and temp files)
- **Recommended Total**: 50 GB minimum

## ⚙️ Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `COMFY_LOG_LEVEL` | `DEBUG` | ComfyUI logging level (DEBUG, INFO, WARNING, ERROR) |

## 🐛 Troubleshooting

### ComfyUI not starting
- Check logs: `docker logs wan22-comfyui`
- Verify GPU is available: `nvidia-smi`
- Ensure CUDA 12.8 drivers are installed

### Models not loading
- Check model paths in JupyterLab
- Verify models were downloaded during build
- Check disk space: `df -h`

### JupyterLab not accessible
- Verify port 8189 is exposed in RunPod template
- Check that the pod is running
- Try accessing via RunPod's proxy URL: `https://<pod-id>-8189.proxy.runpod.net`

### ComfyUI not accessible
- Verify port 8188 is exposed in RunPod template
- Check that ComfyUI started successfully in pod logs
- Try accessing via RunPod's proxy URL: `https://<pod-id>-8188.proxy.runpod.net`

## 📚 Additional Resources

- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI)
- [WAN Video Wrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper)
- [RunPod Documentation](https://docs.runpod.io/)
- [Original RunPod Worker](https://github.com/runpod-workers/worker-comfyui)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is based on:
- [runpod-workers/worker-comfyui](https://github.com/runpod-workers/worker-comfyui) - AGPL-3.0
- [kijai/ComfyUI-WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper) - Apache-2.0

## 🙏 Acknowledgments

- RunPod team for the original worker-comfyui
- Kijai for the WAN Video Wrapper
- ComfyUI community
- WAN Video team

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check the RunPod Discord
- Review ComfyUI documentation

---

**Built with ❤️ for the ComfyUI and RunPod community**

