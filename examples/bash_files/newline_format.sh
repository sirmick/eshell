#!/bin/bash
# Clean newline-separated commands example

echo "Hello, World!"
ls -la
pwd
whoami

echo "Processing files in /tmp"
ls -la /tmp

echo "Listing all text files:"
ls -la | grep "\.txt"

# Simple commands
cd /tmp
rm *.tmp
echo "Done!"