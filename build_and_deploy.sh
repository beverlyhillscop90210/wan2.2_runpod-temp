#!/bin/bash

# WAN 2.2 RunPod Template - Build and Deploy Script
# This script helps you build and deploy the Docker image to RunPod

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="wan22-runpod"
DEFAULT_TAG="latest"
DOCKERFILE="Dockerfile.wan22"

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

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is installed"
}

# Check if NVIDIA Docker runtime is available
check_nvidia_docker() {
    if ! docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu24.04 nvidia-smi &> /dev/null; then
        print_error "NVIDIA Docker runtime is not available. Please install nvidia-docker2."
        exit 1
    fi
    print_success "NVIDIA Docker runtime is available"
}

# Build the Docker image
build_image() {
    local tag=$1
    print_header "Building Docker Image"
    print_info "This may take 30-60 minutes depending on your internet connection..."
    
    docker build \
        -f ${DOCKERFILE} \
        -t ${IMAGE_NAME}:${tag} \
        --progress=plain \
        .
    
    print_success "Docker image built: ${IMAGE_NAME}:${tag}"
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
        ${IMAGE_NAME}:${tag}
    
    print_info "Waiting for services to start (60 seconds)..."
    sleep 60
    
    # Test ComfyUI API
    if curl -f http://localhost:8188/ &> /dev/null; then
        print_success "ComfyUI API is responding"
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

# Tag image for Docker Hub
tag_for_hub() {
    local username=$1
    local tag=$2
    
    print_header "Tagging Image for Docker Hub"
    docker tag ${IMAGE_NAME}:${tag} ${username}/${IMAGE_NAME}:${tag}
    print_success "Tagged as ${username}/${IMAGE_NAME}:${tag}"
}

# Push to Docker Hub
push_to_hub() {
    local username=$1
    local tag=$2
    
    print_header "Pushing to Docker Hub"
    print_info "Logging in to Docker Hub..."
    docker login
    
    print_info "Pushing image (this may take a while)..."
    docker push ${username}/${IMAGE_NAME}:${tag}
    
    print_success "Image pushed to Docker Hub: ${username}/${IMAGE_NAME}:${tag}"
}

# Main menu
show_menu() {
    echo ""
    print_header "WAN 2.2 RunPod Template - Build & Deploy"
    echo "1. Build Docker image"
    echo "2. Test image locally"
    echo "3. Tag and push to Docker Hub"
    echo "4. Full workflow (build, test, push)"
    echo "5. Exit"
    echo ""
    read -p "Select an option (1-5): " choice
    
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
            read -p "Enter your Docker Hub username: " username
            if [ -z "$username" ]; then
                print_error "Username cannot be empty"
                exit 1
            fi
            read -p "Enter tag (default: ${DEFAULT_TAG}): " tag
            tag=${tag:-$DEFAULT_TAG}
            tag_for_hub $username $tag
            push_to_hub $username $tag
            ;;
        4)
            read -p "Enter your Docker Hub username: " username
            if [ -z "$username" ]; then
                print_error "Username cannot be empty"
                exit 1
            fi
            read -p "Enter tag (default: ${DEFAULT_TAG}): " tag
            tag=${tag:-$DEFAULT_TAG}
            
            build_image $tag
            test_image $tag
            tag_for_hub $username $tag
            push_to_hub $username $tag
            
            print_success "Full workflow complete!"
            echo ""
            print_info "Next steps:"
            echo "1. Go to https://www.runpod.io/console/serverless/user/templates"
            echo "2. Create a new template with image: ${username}/${IMAGE_NAME}:${tag}"
            echo "3. Set Container Disk to 50 GB"
            echo "4. Expose HTTP Ports: 8188,8189"
            echo "5. Deploy your endpoint!"
            echo ""
            echo "IMPORTANT: ComfyUI will start with SageAttention3 enabled for optimal Blackwell GPU performance!"
            ;;
        5)
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
    print_header "WAN 2.2 RunPod Template Builder"
    
    # Check prerequisites
    check_docker
    check_nvidia_docker
    
    # Show menu
    show_menu
}

# Run main function
main

