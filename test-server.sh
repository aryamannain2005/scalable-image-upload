#!/bin/bash
# Test script to verify the scalable image upload server

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVERS=("http://localhost:3001" "http://localhost:3002")
LOAD_BALANCER="http://localhost:80"
TEST_IMAGE="test-image.jpg"

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to check if servers are running
check_servers() {
    echo ""
    echo "=================================================="
    echo "Checking Server Health"
    echo "=================================================="
    
    for server in "${SERVERS[@]}"; do
        echo "Checking $server..."
        response=$(curl -s -o /dev/null -w "%{http_code}" "$server/health")
        
        if [ "$response" = "200" ]; then
            print_success "$server is running"
        else
            print_error "$server is not responding (HTTP $response)"
            return 1
        fi
    done
    
    echo ""
}

# Function to create a test image
create_test_image() {
    if [ ! -f "$TEST_IMAGE" ]; then
        print_info "Creating test image..."
        # Create a simple 1x1 pixel JPEG
        python3 << 'EOF'
from PIL import Image
import os

# Create a simple test image
img = Image.new('RGB', (100, 100), color='red')
img.save('test-image.jpg')
print("Test image created: test-image.jpg")
EOF
        
        if [ ! -f "$TEST_IMAGE" ]; then
            print_error "Could not create test image. Please create one manually."
            return 1
        fi
    fi
    print_success "Test image ready: $TEST_IMAGE"
}

# Function to test upload
test_upload() {
    echo ""
    echo "=================================================="
    echo "Testing Image Upload"
    echo "=================================================="
    
    # Check if test image exists
    if [ ! -f "$TEST_IMAGE" ]; then
        print_error "Test image not found: $TEST_IMAGE"
        return 1
    fi
    
    # Test on individual servers
    echo ""
    print_info "Testing individual servers..."
    for server in "${SERVERS[@]}"; do
        echo "Uploading to $server..."
        response=$(curl -s -X POST \
            -F "image=@$TEST_IMAGE" \
            "$server/upload")
        
        if echo "$response" | grep -q "url"; then
            print_success "Upload to $server successful"
            echo "Response: $response" | head -n 1
        else
            print_error "Upload to $server failed"
            echo "Response: $response"
        fi
    done
    
    # Test through load balancer
    echo ""
    print_info "Testing through load balancer..."
    echo "Uploading through $LOAD_BALANCER..."
    response=$(curl -s -X POST \
        -F "image=@$TEST_IMAGE" \
        "$LOAD_BALANCER/upload")
    
    if echo "$response" | grep -q "url"; then
        print_success "Upload through load balancer successful"
        echo "Response: $response" | head -n 1
    else
        print_error "Upload through load balancer failed"
        echo "Response: $response"
    fi
}

# Function to test load distribution
test_load_distribution() {
    echo ""
    echo "=================================================="
    echo "Testing Load Distribution (5 requests)"
    echo "=================================================="
    
    # Counter for servers
    declare -A server_count
    server_count["3001"]=0
    server_count["3002"]=0
    
    for i in {1..5}; do
        echo "Request $i..."
        response=$(curl -s -X POST \
            -F "image=@$TEST_IMAGE" \
            "$LOAD_BALANCER/upload")
        
        if echo "$response" | grep -q "3001"; then
            ((server_count["3001"]++))
            echo "  → Handled by server 3001"
        elif echo "$response" | grep -q "3002"; then
            ((server_count["3002"]++))
            echo "  → Handled by server 3002"
        fi
    done
    
    echo ""
    echo "Load Distribution Summary:"
    echo "  Server 3001: ${server_count["3001"]} requests"
    echo "  Server 3002: ${server_count["3002"]} requests"
}

# Function to test error handling
test_error_handling() {
    echo ""
    echo "=================================================="
    echo "Testing Error Handling"
    echo "=================================================="
    
    # Test: No file provided
    print_info "Test 1: Upload without file"
    response=$(curl -s -X POST "$SERVERS[0]/upload")
    if echo "$response" | grep -q "error"; then
        print_success "Properly returns error when no file is provided"
    else
        print_error "Should return error when no file is provided"
    fi
    
    # Test: Invalid file type (create a text file)
    print_info "Test 2: Upload invalid file type"
    echo "This is not an image" > test.txt
    response=$(curl -s -X POST -F "image=@test.txt" "$SERVERS[0]/upload")
    if echo "$response" | grep -q "error"; then
        print_success "Properly rejects non-image files"
    else
        print_error "Should reject non-image files"
    fi
    rm -f test.txt
}

# Main execution
main() {
    echo ""
    echo "=================================================="
    echo "Scalable Image Upload Server - Test Suite"
    echo "=================================================="
    
    # Check if servers are running
    if ! check_servers; then
        print_error "Servers are not running. Please start them first:"
        echo "  npm run start:both"
        exit 1
    fi
    
    # Create test image
    if ! create_test_image; then
        exit 1
    fi
    
    # Run tests
    test_upload
    test_load_distribution
    test_error_handling
    
    echo ""
    echo "=================================================="
    echo "Tests Completed"
    echo "=================================================="
    echo ""
}

# Run main function
main
