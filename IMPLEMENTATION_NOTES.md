# WAN 2.2 RunPod Template - Implementation Notes

## 🎯 Project Overview

This project creates a custom RunPod Docker template for WAN 2.2 video generation with full support for:
- CUDA 12.8.1 (Blackwell GPUs: RTX 5090, B200)
- PyTorch 2.8.0
- SageAttention3 (CRITICAL for Blackwell performance)
- ComfyUI with WAN Video Wrapper
- JupyterLab for backend access

## 🔑 Critical Components

### 1. SageAttention3 Installation

**Why it's critical:**
- Optimized attention mechanism specifically for Blackwell architecture
- Provides significant performance improvements on RTX 5090 and B200 GPUs
- Must be compiled with specific CUDA architecture flags

**Implementation:**
```dockerfile
# Stage 3: Install SageAttention3 with Blackwell Optimization
ENV EXT_PARALLEL=4
ENV NVCC_APPEND_FLAGS="--threads 8 -gencode arch=compute_120,code=sm_120"
ENV MAX_JOBS=4
ENV TORCH_CUDA_ARCH_LIST=12.0

RUN git clone https://github.com/thu-ml/SageAttention && \
    cd SageAttention && \
    uv pip install .
```

**ComfyUI Startup:**
```bash
python -u /comfyui/main.py --use-sage-attention
```

### 2. Port Configuration

**IMPORTANT:** Ports have been specifically configured as:
- **8188** - ComfyUI API (standard)
- **8189** - JupyterLab (NOT 8888)

This avoids conflicts and follows RunPod best practices.

### 3. Model Downloads

All WAN 2.2 models are pre-downloaded during Docker build:

**Text Encoders** (`/comfyui/models/text_encoders/`):
- t5xxl_fp8_e4m3fn.safetensors
- clip_l.safetensors

**CLIP Vision** (`/comfyui/models/clip_vision/`):
- sigclip_vision_patch14_384.safetensors

**Transformer** (`/comfyui/models/diffusion_models/`):
- wan2.2_1.3B_fp8_scaled.safetensors (main model)

**VAE** (`/comfyui/models/vae/`):
- wan_vae.safetensors

## 📁 File Structure

```
Wan2.2_runpod/
├── Dockerfile.wan22              # Main Dockerfile (multi-stage build)
├── docker-compose.wan22.yml      # Local testing configuration
├── build_and_deploy.sh           # Build and deployment script
├── README_WAN22_RUNPOD.md        # User documentation
├── IMPLEMENTATION_NOTES.md       # This file
├── comfy_Triton+sageattn.bat     # Reference Windows setup script
├── runpod-worker-comfyui/        # Cloned RunPod worker repository
└── wan-video-wrapper-temp/       # Cloned WAN wrapper repository
```

## 🏗️ Docker Build Stages

### Stage 1: Base
- CUDA 12.8.1 runtime
- Python 3.12
- ComfyUI installation via comfy-cli
- PyTorch 2.8.0 with CUDA 12.8 support

### Stage 2: Custom Nodes
- ComfyUI Manager
- WAN Video Wrapper
- All required dependencies

### Stage 3: SageAttention3
- Clone SageAttention repository
- Compile with Blackwell-specific flags
- Install and cleanup

### Stage 4: Models
- Download all WAN 2.2 models
- Place in correct ComfyUI directories

### Stage 5: JupyterLab
- Install JupyterLab
- Configure for port 8189
- Set root directory to /comfyui

### Stage 6: Final
- Copy RunPod handler
- Create custom startup script
- Configure environment

## 🚀 Deployment Process

### Local Build & Test
```bash
# Make script executable (Linux/Mac)
chmod +x build_and_deploy.sh

# Run build script
./build_and_deploy.sh

# Or manually:
docker build -f Dockerfile.wan22 -t wan22-runpod:latest .
docker-compose -f docker-compose.wan22.yml up -d
```

### Push to Docker Hub
```bash
docker tag wan22-runpod:latest yourusername/wan22-runpod:latest
docker push yourusername/wan22-runpod:latest
```

### RunPod Template Configuration
1. Go to RunPod Templates
2. Create new template:
   - Docker Image: `yourusername/wan22-runpod:latest`
   - Container Disk: 50 GB minimum
   - Expose HTTP Ports: `8188,8189`
   - Environment Variables (optional):
     - `SERVE_API_LOCALLY=true`
     - `COMFY_LOG_LEVEL=DEBUG`

## 🔧 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVE_API_LOCALLY` | `false` | Enable local API serving |
| `COMFY_LOG_LEVEL` | `DEBUG` | ComfyUI logging level |
| `REFRESH_WORKER` | `false` | Refresh worker after each job |
| `EXT_PARALLEL` | `4` | SageAttention parallel compilation |
| `MAX_JOBS` | `4` | Max compilation jobs |
| `TORCH_CUDA_ARCH_LIST` | `12.0` | CUDA architecture for compilation |

## 📊 Resource Requirements

### Build Time
- **Duration**: 30-60 minutes (depending on internet speed)
- **Disk Space**: ~30 GB during build
- **Network**: ~15 GB download (models + dependencies)

### Runtime
- **Image Size**: ~15-20 GB
- **Minimum Disk**: 50 GB
- **Recommended GPU**: RTX 5090 or B200
- **Minimum VRAM**: 24 GB

## 🐛 Known Issues & Solutions

### Issue: SageAttention compilation fails
**Solution:** Ensure CUDA 12.8 drivers are installed and NVCC is available

### Issue: Models not loading
**Solution:** Check model paths in JupyterLab, verify downloads completed

### Issue: JupyterLab not accessible
**Solution:** Verify port 8189 is exposed and not blocked by firewall

### Issue: ComfyUI crashes on startup
**Solution:** Check GPU compatibility, ensure --use-sage-attention flag is present

## 📚 References

### Source Repositories
- [RunPod Worker ComfyUI](https://github.com/runpod-workers/worker-comfyui)
- [WAN Video Wrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper)
- [SageAttention](https://github.com/thu-ml/SageAttention)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)

### Model Sources
- [WAN Video Models](https://huggingface.co/Kijai/WanVideo_comfy)
- [FP8 Scaled Models](https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled)

### Documentation
- [RunPod Docs](https://docs.runpod.io/)
- [ComfyUI Wiki](https://github.com/comfyanonymous/ComfyUI/wiki)

## ✅ Testing Checklist

Before deploying to production:

- [ ] Docker image builds successfully
- [ ] ComfyUI starts with SageAttention enabled
- [ ] JupyterLab accessible on port 8189
- [ ] All models loaded correctly
- [ ] Test workflow executes successfully
- [ ] GPU utilization is optimal
- [ ] No memory leaks during extended use

## 🔄 Update Process

To update the template:

1. Update base image version in Dockerfile
2. Update model URLs if new versions available
3. Rebuild Docker image
4. Test thoroughly
5. Push to Docker Hub with new tag
6. Update RunPod template

## 📝 Maintenance Notes

### Regular Updates
- Check for ComfyUI updates monthly
- Monitor WAN Video Wrapper for new features
- Update PyTorch when new CUDA-compatible versions release
- Review SageAttention for performance improvements

### Security
- JupyterLab has no password by default (for ease of use)
- Consider adding authentication for production deployments
- Keep base images updated for security patches

## 🎓 Learning Resources

### For Users
- ComfyUI workflow basics
- WAN Video generation techniques
- JupyterLab file management

### For Developers
- Docker multi-stage builds
- CUDA compilation flags
- RunPod serverless architecture

## 🤝 Contributing

To contribute improvements:
1. Fork the repository
2. Create feature branch
3. Test changes thoroughly
4. Submit pull request with detailed description

## 📞 Support

For issues:
1. Check this implementation notes
2. Review README troubleshooting section
3. Check RunPod Discord
4. Open GitHub issue with logs

---

**Last Updated:** 2025-10-09
**Version:** 1.0
**Maintainer:** AI IDE Agent

