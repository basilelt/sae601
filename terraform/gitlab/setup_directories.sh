#!/bin/bash

echo "Creating necessary directories..."
mkdir -p files
mkdir -p "${PWD}/templates"
mkdir -p "${PWD}/files"

echo "Making scripts executable..."
chmod +x *.sh
chmod +x scripts/*.sh

echo "Directory structure created!"
echo "Setup complete!"
