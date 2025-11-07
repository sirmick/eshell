#!/bin/bash
# Basic Commands Example
# This script demonstrates basic command parsing

# Simple commands without separators
echo hello
pwd
date
whoami

# Commands with semicolons
echo "start"; ls; echo "done"
mkdir test; cd test; touch file.txt; rm file.txt

# Mixed newlines and semicolons
echo test
ls /tmp; pwd
echo "end"

# Command with options and arguments
ls -la /var/log
grep "error" log.txt > errors.log