# Default Workflow Configuration

**Date:** October 12, 2025

## Overview

The WAN 2.2 RunPod template now automatically loads the `wan_upscale_wrapper_ngrok.json` workflow when ComfyUI starts. This provides users with an immediate, ready-to-use workflow for WAN 2.2 video upscaling.

## Workflow Details

### File Information
- **Workflow Name:** `wan_upscale_wrapper_ngrok.json`
- **Purpose:** WAN 2.2 video upscaling with ngrok integration
- **Location in Image:** `/etc/default_workflow.json`
- **ComfyUI Location:** `/comfyui/user/default/workflows/default.json`

### Features
The default workflow includes:
- WAN 2.2 video model integration
- Upscaling capabilities
- Ngrok tunnel support for remote access
- Pre-configured nodes for optimal video processing
- Ready-to-use setup for immediate video generation

## Implementation

### Docker Image Setup

The workflow is embedded in the Docker image during build:

```dockerfile
# Copy default workflow
COPY wan_upscale_wrapper_ngrok.json /etc/default_workflow.json
```

**File:** `Dockerfile.ci` (Line 80-81)

### Runtime Configuration

During container startup, the workflow is copied to ComfyUI's default location:

```bash
# Copy default workflow to ComfyUI
if [ -f /etc/default_workflow.json ]; then
    echo "📄 Setting up default workflow (wan_upscale_wrapper_ngrok.json)..."
    mkdir -p /comfyui/user/default/workflows
    cp /etc/default_workflow.json /comfyui/user/default/workflows/default.json
    echo "✅ Default workflow configured - will auto-load on ComfyUI startup"
fi
```

**File:** `scripts/runtime-init.sh` (Lines 29-35)

## User Experience

### On First Launch
1. Container starts and runs runtime initialization
2. Default workflow is copied to ComfyUI's user directory
3. ComfyUI loads with the workflow automatically opened
4. User sees the complete WAN 2.2 upscaling workflow ready to use

### Benefits
- **Immediate Productivity:** No need to search for or create workflows
- **Best Practices:** Pre-configured with optimal settings
- **Learning Tool:** Users can study the workflow to understand WAN 2.2 usage
- **Consistency:** All deployments start with the same baseline workflow
- **Time Saving:** Eliminates manual workflow setup steps

## Technical Details

### Directory Structure
```
/comfyui/
├── user/
│   └── default/
│       └── workflows/
│           └── default.json  ← Auto-loaded by ComfyUI
```

### ComfyUI Behavior
- ComfyUI checks `/comfyui/user/default/workflows/default.json` on startup
- If the file exists, it's automatically loaded in the UI
- Users can still create and save other workflows
- The default workflow can be modified and saved

### Workflow Persistence
- **Container Restart:** Workflow persists if `/comfyui` is on a volume
- **Fresh Container:** Workflow is re-copied from `/etc/default_workflow.json`
- **User Modifications:** Saved to `/comfyui/user/default/workflows/default.json`

## Customization

### Changing the Default Workflow

To use a different workflow as default:

1. **Replace the workflow file:**
   ```bash
   # In your local repository
   cp your_workflow.json wan_upscale_wrapper_ngrok.json
   ```

2. **Rebuild the image:**
   ```bash
   git add wan_upscale_wrapper_ngrok.json
   git commit -m "chore: Update default workflow"
   git push origin master
   ```

3. **GitHub Actions will automatically build and deploy**

### Disabling Auto-Load

To disable automatic workflow loading:

1. **Remove the workflow copy step from `runtime-init.sh`:**
   ```bash
   # Comment out or remove lines 29-35
   ```

2. **Or delete the file in the running container:**
   ```bash
   rm /comfyui/user/default/workflows/default.json
   ```

## Workflow Content

The `wan_upscale_wrapper_ngrok.json` workflow includes:

### Node Configuration
- **Total Nodes:** 329 nodes
- **Total Links:** 585 connections
- **Workflow ID:** e4f5641b-4ad8-4b5f-9542-3b4dcb09f126

### Key Components
1. **WAN Video Model Nodes:** For loading and configuring WAN 2.2 models
2. **Upscaling Nodes:** For video resolution enhancement
3. **Ngrok Integration:** For remote access and sharing
4. **Reroute Nodes:** For clean workflow organization
5. **Processing Pipeline:** Complete video processing chain

### Workflow Capabilities
- Text-to-video generation
- Video upscaling
- Frame interpolation
- Quality enhancement
- Remote access via ngrok

## Troubleshooting

### Workflow Not Loading

**Symptom:** ComfyUI starts but workflow doesn't auto-load

**Solutions:**
1. Check if file exists:
   ```bash
   ls -la /comfyui/user/default/workflows/default.json
   ```

2. Check runtime init logs:
   ```bash
   # Look for "Setting up default workflow" message
   ```

3. Verify file permissions:
   ```bash
   chmod 644 /comfyui/user/default/workflows/default.json
   ```

### Workflow Errors

**Symptom:** Workflow loads but shows errors

**Solutions:**
1. Ensure all custom nodes are installed (they are in this template)
2. Check that all required models are downloaded
3. Verify ComfyUI version compatibility (v0.3.55+)

### Workflow Modifications Not Saving

**Symptom:** Changes to workflow don't persist

**Solutions:**
1. Ensure `/comfyui` is mounted to a persistent volume
2. Check write permissions on `/comfyui/user/default/workflows/`
3. Save workflow with a different name to test

## Version History

### 2025-10-12
- Initial implementation of default workflow auto-load
- Added `wan_upscale_wrapper_ngrok.json` as default
- Configured automatic setup in runtime initialization
- Created comprehensive documentation

## References

- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI)
- [WAN 2.2 Model Documentation](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)
- [Ngrok Documentation](https://ngrok.com/docs)

## Future Enhancements

- [ ] Add multiple workflow templates to choose from
- [ ] Create workflow selection UI during container startup
- [ ] Add workflow validation before auto-load
- [ ] Include workflow documentation in ComfyUI UI
- [ ] Create workflow gallery with examples

