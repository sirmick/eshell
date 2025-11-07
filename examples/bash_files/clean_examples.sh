#!/bin/bash
# Clean examples demonstrating newline-separated commands

# Basic newline-separated commands
echo "Hello, World!"
ls -la
pwd

# Pipes with newlines
echo "Listing text files"
ls -la | grep "\.txt"

# Mixed syntax - newlines AND semicolons
echo hello; ls -la
pwd

# Conditional with proper newlines
if test -f file.txt; then
    echo "File exists"
fi

for file in *.txt; do
    echo "Processing $file"
done