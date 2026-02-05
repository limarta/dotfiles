#!/bin/bash

# Configuration
REPO_URL="git@github.com:limarta/qwen_experiments.git"
MAX_PRICE="0.13"
MIN_RAM="16.0"     # 16GB in MB
MIN_SPEED="1200"    # 1000 Mbps
REGION="[US, CA]"   # North America
COMPUTE_CAP="90"   # Min Compute Capability (7.5+ filters out old cards)
IMAGE="pytorch/pytorch" # Standard image, change if needed
LABEL_TAG="rental"

# Function to spin up the workspace
function start_workspace() {
    echo "🔍 Searching for GPU..."
    
    # Search for offers matching criteria
    # Sorting by dlperf_usd (performance per dollar) to get the best value
    # vastai search offers "dph < 0.13 inet_down >= 1200 inet_up>=1200 gpu_arch=nvidia geolocation in [US, CA] rentable=true gpu_ram>=16.0"
    # vastai search offers "dph < 0.13 inet_down >= 1200 inet_up>=1200 gpu_arch=nvidia geolocation in [US, CA] rentable=true gpu_ram>=16.0 cpu_ram>=16.0" -o "gpu_ram-, inet_up-"
    OFFER_ID=$(vastai search offers "gpu_ram >= ${MIN_RAM} cpu_ram>=${MIN_RAM} inet_down >= ${MIN_SPEED} inet_up>= ${MIN_SPEED} dph < ${MAX_PRICE} geolocation in [US, CA] gpu_arch=nvidia rentable=true" -o "gpu_ram-, dlperf_usd-" --raw | jq -r '.[0].id')

    if [ -z "$OFFER_ID" ] || [ "$OFFER_ID" == "null" ]; then
        echo "❌ No matching GPUs found. Try adjusting your price or specs."
        exit 1
    fi

    echo "✅ Found Offer ID: $OFFER_ID"
    echo "🚀 Renting instance..."

    # Create the instance (allocating 32GB disk space by default)
    # Using --raw to parse the new Contract ID
    NEW_ID=$(vastai create instance $OFFER_ID --image $IMAGE --disk 32 --ssh --direct --raw | jq -r '.new_contract')
    # NEW_ID=$(vastai create instance $OFFER_ID --image $IMAGE --disk 32 --ssh --direct --raw)

    if [ -z "$NEW_ID" ] || [ "$NEW_ID" == "null" ]; then
        echo "❌ Failed to rent instance."
        exit 1
    fi

    echo "🏷️  Tagging instance $NEW_ID as '$LABEL_TAG'..."
    vastai label instance $NEW_ID $LABEL_TAG

    echo "⏳ Waiting for instance to become available (this takes a minute)..."
    
    # Wait loop until the instance is running and has an SSH port
    while true; do
        STATUS=$(vastai show instance $NEW_ID --raw | jq -r '.actual_status')
        SSH_HOST=$(vastai show instance $NEW_ID --raw | jq -r '.ssh_host')
        
        if [ "$STATUS" == "running" ] && [ "$SSH_HOST" != "null" ]; then
            break
        fi
        sleep 5
        echo -n "."
    done
    echo ""

    setup_instance $NEW_ID
}

# Function to SSH into an instance and run the setup payload
function setup_instance() {
    local INSTANCE_ID=$1

    if [ -z "$INSTANCE_ID" ]; then
        echo "❌ No instance ID provided."
        exit 1
    fi

    # Get SSH Connection string and parse into user@host and port
    SSH_URL=$(vastai ssh-url $INSTANCE_ID)
    SSH_USER_HOST=$(echo $SSH_URL | sed 's|ssh://||' | cut -d: -f1)
    SSH_PORT=$(echo $SSH_URL | sed 's|ssh://||' | cut -d: -f2)
    echo "🔌 Connection ready: $SSH_URL"

    echo "🛠️  Setting up workspace..."
    ssh -A -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER_HOST << EOF
        touch ~/.no_auto_tmux
        # Install uv if not already present
        if ! command -v uv &> /dev/null; then
            echo "Installing uv..."
            curl -LsSf https://astral.sh/uv/install.sh | sh
            source \$HOME/.local/bin/env
        else
            echo "uv already installed, skipping..."
        fi

        # Add GitHub host key if not already known
        mkdir -p ~/.ssh
        ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null

        # Clone and Sync
        if [ ! -d "repo" ]; then
            git clone $REPO_URL repo
        fi
        cd repo
        uv sync

        echo "✅ Setup Complete!"
EOF

    echo "🎉 Instance $INSTANCE_ID is ready!"
    echo "   Connect with: vastai ssh-url $INSTANCE_ID"
}

# Function to destroy the workspace
function destroy_workspace() {
    echo "🔍 Looking for instances tagged '$LABEL_TAG'..."
    
    # Find all instances with the specific label
    INSTANCE_IDS=$(vastai show instances --raw | jq -r ".[] | select(.label == \"$LABEL_TAG\") | .id")

    if [ -z "$INSTANCE_IDS" ]; then
        echo "ℹ️  No instances found with label '$LABEL_TAG'."
        exit 0
    fi

    for ID in $INSTANCE_IDS; do
        echo "🔥 Destroying instance $ID..."
        vastai destroy instance $ID
    done
    
    echo "💀 All tagged instances destroyed."
}

# CLI Argument Parsing
if [ "$1" == "start" ]; then
    start_workspace
elif [ "$1" == "setup" ]; then
    setup_instance $2
elif [ "$1" == "destroy" ]; then
    destroy_workspace
else
    echo "Usage: $0 {start|setup <instance_id>|destroy}"
    exit 1
fi
