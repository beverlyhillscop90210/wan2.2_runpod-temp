# Custom Nodes Added to WAN 2.2 RunPod Template

**Date:** October 12, 2025

## Overview

Added 7 new ComfyUI custom nodes to enhance video workflow capabilities in the WAN 2.2 RunPod template. All nodes are installed during runtime initialization with their dependencies automatically managed.

## Custom Nodes Added

### 1. ComfyUI-KJNodes
- **Repository:** https://github.com/kijai/ComfyUI-KJNodes
- **Purpose:** Various quality of life and masking related nodes
- **Key Features:**
  - Set/Get nodes for cleaner workflows
  - ColorToMask for dynamic masking
  - ConditioningMultiCombine for efficient conditioning
  - GrowMaskWithBlur for mask manipulation
  - WidgetToString for dynamic parameter reading
- **Dependencies:** Installed from requirements.txt

### 2. ComfyUI-VideoHelperSuite
- **Repository:** https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
- **Purpose:** Comprehensive video workflow nodes
- **Key Features:**
  - Load Video with advanced frame control
  - Video Combine with audio support
  - Load Image Sequence
  - Batch manipulation (Split, Merge, Select Every Nth)
  - Advanced video previews
- **Dependencies:** Installed from requirements.txt

### 3. masquerade-nodes-comfyui
- **Repository:** https://github.com/BadCafeCode/masquerade-nodes-comfyui
- **Purpose:** Powerful mask-related operations
- **Key Features:**
  - Mask by Text (ClipSeg-based dynamic masking)
  - Mask Morphology (dilate, erode, open, close)
  - Combine Masks with multiple operations
  - Cut/Paste by Mask
  - Separate Mask Components
- **Dependencies:** No requirements.txt (dependency-free)

### 4. ComfyLiterals
- **Repository:** https://github.com/M1kep/ComfyLiterals
- **Purpose:** Literal value nodes for workflows
- **Key Features:**
  - Direct input of literal values
  - Cleaner workflow organization
- **Dependencies:** No requirements.txt

### 5. ComfyUI_Fill-Nodes
- **Repository:** https://github.com/filliptm/ComfyUI_Fill-Nodes
- **Purpose:** Fill and inpainting utilities
- **Key Features:**
  - Advanced fill operations
  - Inpainting helpers
- **Dependencies:** Installed from requirements.txt if present

### 6. ComfyUI_LayerStyle
- **Repository:** https://github.com/chflame163/ComfyUI_LayerStyle
- **Purpose:** Layer styling and effects
- **Key Features:**
  - Layer-based effects
  - Style transfer utilities
- **Dependencies:** Installed from requirements.txt if present

### 7. ComfyUI_LayerStyle_Advance
- **Repository:** https://github.com/chflame163/ComfyUI_LayerStyle_Advance
- **Purpose:** Advanced layer styling
- **Key Features:**
  - Extended layer effects
  - Advanced compositing
- **Dependencies:** Installed from requirements.txt if present

## Installation Process

All custom nodes are installed during runtime initialization in `scripts/runtime-init.sh`:

1. **Clone Phase:** Each repository is cloned into `/comfyui/custom_nodes/` if not already present
2. **Dependency Phase:** Dependencies are installed using `uv pip install` for speed
3. **Conditional Installation:** Only installs dependencies if `requirements.txt` exists

## Benefits

### Enhanced Video Workflows
- **VideoHelperSuite** provides comprehensive video I/O and manipulation
- **KJNodes** adds quality-of-life improvements for complex workflows
- **Masquerade** enables advanced masking for selective processing

### Better Composition Control
- **LayerStyle** nodes enable sophisticated compositing
- **Fill-Nodes** improve inpainting capabilities
- **Literals** simplify parameter management

### Workflow Efficiency
- All nodes work together seamlessly
- No manual dependency installation required
- Automatic updates on container restart

## Technical Details

### Runtime Installation Strategy
```bash
# Example pattern used for each node
if [ ! -d "ComfyUI-KJNodes" ]; then
    echo "Installing ComfyUI-KJNodes..."
    git clone https://github.com/kijai/ComfyUI-KJNodes.git
fi

# Conditional dependency installation
if [ -f "ComfyUI-KJNodes/requirements.txt" ]; then
    echo "  → ComfyUI-KJNodes..."
    uv pip install --no-cache -r ComfyUI-KJNodes/requirements.txt
fi
```

### Performance Optimizations
- **UV Package Manager:** 5-10x faster than pip
- **No-Cache Flag:** Reduces disk usage
- **Conditional Checks:** Skips already-installed nodes
- **Parallel-Ready:** Can be parallelized in future updates

## Compatibility

- **ComfyUI Version:** v0.3.56+
- **Python:** 3.10+
- **CUDA:** 12.8.1
- **PyTorch:** 2.8.0

## Usage Examples

### Video Processing with VideoHelperSuite
```
Load Video → Process Frames → Video Combine
```

### Advanced Masking with Masquerade
```
Image → Mask by Text → Mask Morphology → Inpaint
```

### Workflow Organization with KJNodes
```
Set Node → Complex Processing → Get Node
```

## Troubleshooting

### Node Not Appearing
- Restart ComfyUI after installation
- Check `/comfyui/custom_nodes/` for cloned repositories
- Review runtime logs for installation errors

### Dependency Conflicts
- All dependencies are installed with `--no-cache` to avoid conflicts
- UV package manager handles version resolution automatically
- Check logs for specific package conflicts

### Missing Features
- Some nodes may require specific models
- Check individual node documentation for requirements
- Ensure all dependencies installed successfully

## Future Enhancements

- [ ] Add more video-specific custom nodes
- [ ] Optimize dependency installation order
- [ ] Add version pinning for stability
- [ ] Create example workflows using these nodes
- [ ] Add automated testing for node functionality

## References

- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Manager](https://github.com/ltdrdata/ComfyUI-Manager)
- [UV Package Manager](https://github.com/astral-sh/uv)

## Changelog

### 2025-10-12
- Initial addition of 7 custom nodes
- Implemented runtime installation strategy
- Added conditional dependency management
- Created comprehensive documentation

