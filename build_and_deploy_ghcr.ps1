# WAN 2.2 RunPod Template - Build and Deploy to GitHub Container Registry (PowerShell)
# This script helps you build and deploy the Docker image to GHCR on Windows

# Configuration
$IMAGE_NAME = "wan22-runpod"
$DEFAULT_TAG = "latest"
$DOCKERFILE = "Dockerfile.wan22"
$GITHUB_USER = "lum3on"
$REGISTRY = "ghcr.io"

# Functions
function Print-Header {
    param([string]$Message)
    Write-Host "================================" -ForegroundColor Green
    Write-Host $Message -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
}

function Print-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Print-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if Docker is installed
function Check-Docker {
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Print-Error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    }
    Print-Success "Docker is installed"
}

# Check GitHub token
function Check-GitHubToken {
    Print-Header "GitHub Container Registry Setup"
    Write-Host ""
    Write-Host "To push to GHCR, you need a GitHub Personal Access Token (PAT)."
    Write-Host ""
    Write-Host "If you don't have one yet:"
    Write-Host "1. Go to: https://github.com/settings/tokens"
    Write-Host "2. Click 'Generate new token (classic)'"
    Write-Host "3. Select scopes: write:packages, read:packages, delete:packages"
    Write-Host "4. Copy the token"
    Write-Host ""
    $hasToken = Read-Host "Do you have a GitHub PAT ready? (y/n)"
    
    if ($hasToken -ne "y") {
        Print-Info "Please create a GitHub PAT first, then run this script again."
        exit 0
    }
}

# Login to GHCR
function Login-GHCR {
    Print-Header "Login to GitHub Container Registry"
    
    $secureToken = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    $token | docker login $REGISTRY -u $GITHUB_USER --password-stdin
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Successfully logged in to GHCR"
    } else {
        Print-Error "Failed to login to GHCR"
        exit 1
    }
}

# Build the Docker image
function Build-Image {
    param([string]$Tag)
    
    Print-Header "Building Docker Image"
    Print-Info "This may take 30-60 minutes depending on your internet connection..."
    Print-Info "The image will include:"
    Write-Host "  - ComfyUI v0.3.55"
    Write-Host "  - CUDA 12.8.1 + PyTorch 2.8.0"
    Write-Host "  - WAN 2.2 models (14B fp16)"
    Write-Host "  - Custom LoRAs and upscale models"
    Write-Host "  - SageAttention3 for Blackwell GPUs"
    Write-Host "  - JupyterLab on port 8189"
    Write-Host ""
    
    docker build `
        -f $DOCKERFILE `
        -t "$REGISTRY/$GITHUB_USER/${IMAGE_NAME}:$Tag" `
        --progress=plain `
        .
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Docker image built: $REGISTRY/$GITHUB_USER/${IMAGE_NAME}:$Tag"
    } else {
        Print-Error "Failed to build Docker image"
        exit 1
    }
}

# Test the image locally
function Test-Image {
    param([string]$Tag)
    
    Print-Header "Testing Docker Image"
    
    Print-Info "Starting container for testing..."
    docker run --rm -d `
        --name wan22-test `
        --gpus all `
        -p 8188:8188 `
        -p 8189:8189 `
        -e SERVE_API_LOCALLY=true `
        "$REGISTRY/$GITHUB_USER/${IMAGE_NAME}:$Tag"
    
    Print-Info "Waiting for services to start (60 seconds)..."
    Start-Sleep -Seconds 60
    
    # Test ComfyUI API
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8188/" -TimeoutSec 5 -ErrorAction Stop
        Print-Success "ComfyUI API is responding on port 8188"
    } catch {
        Print-Error "ComfyUI API is not responding"
    }
    
    # Test JupyterLab
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8189/" -TimeoutSec 5 -ErrorAction Stop
        Print-Success "JupyterLab is responding on port 8189"
    } catch {
        Print-Error "JupyterLab is not responding on port 8189"
    }
    
    Print-Info "Stopping test container..."
    docker stop wan22-test
    
    Print-Success "Testing complete!"
}

# Push to GHCR
function Push-ToGHCR {
    param([string]$Tag)
    
    Print-Header "Pushing to GitHub Container Registry"
    Print-Info "Pushing image (this may take a while)..."
    
    docker push "$REGISTRY/$GITHUB_USER/${IMAGE_NAME}:$Tag"
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Image pushed to GHCR: $REGISTRY/$GITHUB_USER/${IMAGE_NAME}:$Tag"
    } else {
        Print-Error "Failed to push image to GHCR"
        exit 1
    }
}

# Show final instructions
function Show-FinalInstructions {
    param([string]$Tag)
    
    Print-Header "Deployment Complete!"
    Write-Host ""
    Print-Success "Your image is now available at:"
    Write-Host "  $REGISTRY/$GITHUB_USER/${IMAGE_NAME}:$Tag"
    Write-Host ""
    Print-Info "Next steps for RunPod deployment:"
    Write-Host ""
    Write-Host "1. Go to: https://www.runpod.io/console/serverless/user/templates"
    Write-Host "2. Click 'New Template'"
    Write-Host "3. Configure:"
    Write-Host "   - Template Name: WAN 2.2 ComfyUI"
    Write-Host "   - Docker Image: $REGISTRY/$GITHUB_USER/${IMAGE_NAME}:$Tag"
    Write-Host "   - Container Disk: 50 GB (minimum)"
    Write-Host "   - Expose HTTP Ports: 8188,8189"
    Write-Host "   - Environment Variables (optional):"
    Write-Host "     * SERVE_API_LOCALLY=true"
    Write-Host "     * COMFY_LOG_LEVEL=DEBUG"
    Write-Host ""
    Write-Host "4. Create Serverless Endpoint:"
    Write-Host "   - Go to: https://www.runpod.io/console/serverless/user/endpoints"
    Write-Host "   - Click 'New Endpoint'"
    Write-Host "   - Select your template"
    Write-Host "   - Choose GPU (RTX 5090 or B200 recommended)"
    Write-Host "   - Deploy!"
    Write-Host ""
    Print-Info "Services available after deployment:"
    Write-Host "  - ComfyUI API: http://<pod-ip>:8188 (with SageAttention3)"
    Write-Host "  - JupyterLab: http://<pod-ip>:8189 (full filesystem access)"
    Write-Host ""
}

# Main menu
function Show-Menu {
    Write-Host ""
    Print-Header "WAN 2.2 RunPod Template - GHCR Deployment"
    Write-Host "1. Build Docker image"
    Write-Host "2. Test image locally (requires GPU)"
    Write-Host "3. Login and push to GHCR"
    Write-Host "4. Full workflow (build, test, push)"
    Write-Host "5. Quick build and push (skip testing)"
    Write-Host "6. Exit"
    Write-Host ""
    $choice = Read-Host "Select an option (1-6)"
    
    switch ($choice) {
        "1" {
            $tag = Read-Host "Enter tag (default: $DEFAULT_TAG)"
            if ([string]::IsNullOrWhiteSpace($tag)) { $tag = $DEFAULT_TAG }
            Build-Image -Tag $tag
        }
        "2" {
            $tag = Read-Host "Enter tag to test (default: $DEFAULT_TAG)"
            if ([string]::IsNullOrWhiteSpace($tag)) { $tag = $DEFAULT_TAG }
            Test-Image -Tag $tag
        }
        "3" {
            $tag = Read-Host "Enter tag (default: $DEFAULT_TAG)"
            if ([string]::IsNullOrWhiteSpace($tag)) { $tag = $DEFAULT_TAG }
            Check-GitHubToken
            Login-GHCR
            Push-ToGHCR -Tag $tag
            Show-FinalInstructions -Tag $tag
        }
        "4" {
            $tag = Read-Host "Enter tag (default: $DEFAULT_TAG)"
            if ([string]::IsNullOrWhiteSpace($tag)) { $tag = $DEFAULT_TAG }
            
            Build-Image -Tag $tag
            Test-Image -Tag $tag
            Check-GitHubToken
            Login-GHCR
            Push-ToGHCR -Tag $tag
            Show-FinalInstructions -Tag $tag
        }
        "5" {
            $tag = Read-Host "Enter tag (default: $DEFAULT_TAG)"
            if ([string]::IsNullOrWhiteSpace($tag)) { $tag = $DEFAULT_TAG }
            
            Build-Image -Tag $tag
            Check-GitHubToken
            Login-GHCR
            Push-ToGHCR -Tag $tag
            Show-FinalInstructions -Tag $tag
        }
        "6" {
            Print-Info "Exiting..."
            exit 0
        }
        default {
            Print-Error "Invalid option"
            Show-Menu
        }
    }
}

# Main execution
Print-Header "WAN 2.2 RunPod Template - GHCR Builder"
Write-Host ""
Print-Info "GitHub User: $GITHUB_USER"
Print-Info "Registry: $REGISTRY"
Print-Info "Image: $REGISTRY/$GITHUB_USER/$IMAGE_NAME"
Write-Host ""

# Check prerequisites
Check-Docker

# Show menu
Show-Menu

