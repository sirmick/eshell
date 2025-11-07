#!/bin/bash
# Redirections and Complex Pipelines Example

# Basic redirections
echo "Hello World" > output.txt
cat < input.txt >> combined.txt
echo "Error message" 2> errors.log

# Multiple redirections
sort < unsorted_data.txt > sorted_data.txt 2> errors.txt

# Complex pipelines with multiple stages
cat /var/log/syslog | grep ERROR | sed 's/ERROR/[ERROR]/g' | sort > processed_errors.txt

# Data processing pipeline
ls -la | awk '{print $9}' | grep -v "^$" | sort | uniq -c | sort -nr

# Real-world log analysis
cat access.log | 
    grep -E "(GET|POST|PUT|DELETE)" | 
    cut -d'"' -f4 | 
    grep -E "^[0-9]{3}$" | 
    sort | uniq -c | 
    sort -nr

# Complex multi-stage pipeline
find . -type f -name "*.py" | 
    grep -v __pycache__ | 
    grep -v test_ | 
    xargs grep -r "import" | 
    cut -d':' -f1 | 
    sort | uniq

# Pipeline with redirection
cat data.csv | 
    tail -n +2 | 
    grep -v ",NA," | 
    awk -F',' '{print $1, $3}' | 
    sort | 
    uniq -c | 
    sort -nr > analysis_results.txt

# Error handling with redirections
command_not_found 2>/dev/null || echo "Command failed"