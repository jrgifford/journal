#!/bin/bash
# Wrapper script for building with Docker Compose using proper user permissions

# Set user ID and group ID to match host user
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

echo "Using USER_ID=$USER_ID and GROUP_ID=$GROUP_ID"

# Build the image first if it doesn't exist
if [[ "$(docker images -q journallatex 2> /dev/null)" == "" ]]; then
    echo "Building Docker image..."
    docker compose build
fi

# Run the command
if [ $# -eq 0 ]; then
    # No arguments - run default make command
    docker compose run --rm journallatex
else
    # Run with provided arguments
    docker compose run --rm journallatex "$@"
fi