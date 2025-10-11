#!/bin/bash

# WAN 2.2 RunPod Template - Build and Deploy to GitHub Container Registry
# This script helps you build and deploy the Docker image to GHCR

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="wan22-runpod"
DEFAULT_TAG="latest"
DOCKERFILE="Dockerfile.wan22"
GITHUB_USER="lum3on"
REGISTRY="ghcr.io"

# Functions
print_header() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is installed"
}

# Check GitHub token
check_github_token() {
    print_header "GitHub Container Registry Setup"
    echo ""
    echo "To push to GHCR, you need a GitHub Personal Access Token (PAT)."
    echo ""
    echo "If you don't have one yet:"
    echo "1. Go to: https://github.com/settings/tokens"
    echo "2. Click 'Generate new token (classic)'"
    echo "3. Select scopes: write:packages, read:packages, delete:packages"
    echo "4. Copy the token"
    echo ""
    read -p "Do you have a GitHub PAT ready? (y/n): " has_token
    
    if [[ $has_token != "y" ]]; then
        print_info "Please create a GitHub PAT first, then run this script again."
        exit 0
    fi
}

# Login to GHCR
login_ghcr() {
    print_header "Login to GitHub Container Registry"
    
    read -sp "Enter your GitHub Personal Access Token: " github_token
    echo ""
    
    echo "$github_token" | docker login ${REGISTRY} -u ${GITHUB_USER} --password-stdin
    
    if [ $? -eq 0 ]; then
        print_success "Successfully logged in to GHCR"
    else
        print_error "Failed to login to GHCR"
        exit 1
    fi
}

# Build the Docker image
build_image() {
    local tag=$1
    print_header "Building Docker Image"
    print_info "This may take 30-60 minutes depending on your internet connection..."
    print_info "The image will include:"
    echo "  - ComfyUI v0.3.55"
    echo "  - CUDA 12.8.1 + PyTorch 2.8.0"
    echo "  - WAN 2.2 models (14B fp16)"
    echo "  - Custom LoRAs and upscale models"
    echo "  - SageAttention3 for Blackwell GPUs"
    echo "  - JupyterLab on port 8189"
    echo ""
    
    docker build \
        -f ${DOCKERFILE} \
        -t ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}:${tag} \
        --progress=plain \
        .
    
    print_success "Docker image built: ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}:${tag}"
}

# Test the image locally
test_image() {
    local tag=$1
    print_header "Testing Docker Image"
    
    print_info "Starting container for testing..."
    docker run --rm -d \
        --name wan22-test \
        --gpus all \
        -p 8188:8188 \
        -p 8189:8189 \
        -e SERVE_API_LOCALLY=true \
        ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}:${tag}
    
    print_info "Waiting for services to start (60 seconds)..."
    sleep 60
    
    # Test ComfyUI API
    if curl -f http://localhost:8188/ &> /dev/null; then
        print_success "ComfyUI API is responding on port 8188"
    else
        print_error "ComfyUI API is not responding"
    fi
    
    # Test JupyterLab
    if curl -f http://localhost:8189/ &> /dev/null; then
        print_success "JupyterLab is responding on port 8189"
    else
        print_error "JupyterLab is not responding on port 8189"
    fi
    
    print_info "Stopping test container..."
    docker stop wan22-test
    
    print_success "Testing complete!"
}

# Push to GHCR
push_to_ghcr() {
    local tag=$1
    
    print_header "Pushing to GitHub Container Registry"
    print_info "Pushing image (this may take a while)..."
    
    docker push ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}:${tag}
    
    print_success "Image pushed to GHCR: ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}:${tag}"
}

# Show final instructions
show_final_instructions() {
    local tag=$1
    print_header "Deployment Complete!"
    echo ""
    print_success "Your image is now available at:"
    echo "  ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}:${tag}"
    echo ""
    print_info "Next steps for RunPod deployment:"
    echo ""
    echo "1. Go to: https://www.runpod.io/console/serverless/user/templates"
    echo "2. Click 'New Template'"
    echo "3. Configure:"
    echo "   - Template Name: WAN 2.2 ComfyUI"
    echo "   - Docker Image: ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}:${tag}"
    echo "   - Container Disk: 50 GB (minimum)"
    echo "   - Expose HTTP Ports: 8188,8189"
    echo "   - Environment Variables (optional):"
    echo "     * SERVE_API_LOCALLY=true"
    echo "     * COMFY_LOG_LEVEL=DEBUG"
    echo ""
    echo "4. Create Serverless Endpoint:"
    echo "   - Go to: https://www.runpod.io/console/serverless/user/endpoints"
    echo "   - Click 'New Endpoint'"
    echo "   - Select your template"
    echo "   - Choose GPU (RTX 5090 or B200 recommended)"
    echo "   - Deploy!"
    echo ""
    print_info "Services available after deployment:"
    echo "  - ComfyUI API: http://<pod-ip>:8188 (with SageAttention3)"
    echo "  - JupyterLab: http://<pod-ip>:8189 (full filesystem access)"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    print_header "WAN 2.2 RunPod Template - GHCR Deployment"
    echo "1. Build Docker image"
    echo "2. Test image locally (requires GPU)"
    echo "3. Login and push to GHCR"
    echo "4. Full workflow (build, test, push)"
    echo "5. Quick build and push (skip testing)"
    echo "6. Exit"
    echo ""
    read -p "Select an option (1-6): " choice
    
    case $choice in
        1)
            read -p "Enter tag (default: ${DEFAULT_TAG}): " tag
            tag=${tag:-$DEFAULT_TAG}
            build_image $tag
            ;;
        2)
            read -p "Enter tag to test (default: ${DEFAULT_TAG}): " tag
            tag=${tag:-$DEFAULT_TAG}
            test_image $tag
            ;;
        3)
            read -p "Enter tag (default: ${DEFAULT_TAG}): " tag
            tag=${tag:-$DEFAULT_TAG}
            check_github_token
            login_ghcr
            push_to_ghcr $tag
            show_final_instructions $tag
            ;;
        4)
            read -p "Enter tag (default: ${DEFAULT_TAG}): " tag
            tag=${tag:-$DEFAULT_TAG}
            
            build_image $tag
            test_image $tag
            check_github_token
            login_ghcr
            push_to_ghcr $tag
            show_final_instructions $tag
            ;;
        5)
            read -p "Enter tag (default: ${DEFAULT_TAG}): " tag
            tag=${tag:-$DEFAULT_TAG}
            
            build_image $tag
            check_github_token
            login_ghcr
            push_to_ghcr $tag
            show_final_instructions $tag
            ;;
        6)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            show_menu
            ;;
    esac
}

# Main execution
main() {
    print_header "WAN 2.2 RunPod Template - GHCR Builder"
    echo ""
    print_info "GitHub User: ${GITHUB_USER}"
    print_info "Registry: ${REGISTRY}"
    print_info "Image: ${REGISTRY}/${GITHUB_USER}/${IMAGE_NAME}"
    echo ""
    
    # Check prerequisites
    check_docker
    
    # Show menu
    show_menu
}

# Run main function
main

