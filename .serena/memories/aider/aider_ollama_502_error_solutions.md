# Fundamental Solutions for Aider + Ollama 502 Errors

## Root Causes of the Problem
- **Server Load**: High memory usage on the Ollama server side
- **Insufficient Context**: Default 2k context is inadequate for large models
- **Processing Load**: Overload due to batch processing of many files

## Countermeasures on the Aider Side

### 1. Extend Timeout
```bash
# .env or environment variable
export AIDER_TIMEOUT=600  # Extend to 10 minutes
```

### 2. Optimize Context Settings
Create `.aider.model.settings.yml`:
```yaml
- name: ollama/deepseek-v3.1:671b-cloud  
  edit_format: diff  
  use_repo_map: true  
  streaming: true  
  extra_params:  
    num_ctx: 32768      # Expanded for large models
    temperature: 0.1
```

### 3. Dynamic Context Adjustment
- Use Ollama dynamic context adjustment feature in aider v0.74.0 or later
- Automatically optimize context size according to processing content

## Improvements for Ollama Integration

### 1. Server Startup Settings
```bash
# Pre-set context length
export OLLAMA_CONTEXT_LENGTH=32768
# Start server (set environment variable if auto-starting)
```

### 2. Memory Optimization
- Reduce memory usage by adjusting quantization level
- Secure system resources for large models

## Review of Processing Strategies

### 1. File Splitting Approach
```bash
# Bad example: batch processing
ai -y -m "summarize" -e md  # Process all .md files at once

# Good example: stepwise processing
ai file1.md file2.md        # Process a few files at a time
/add file3.md file4.md      # Add files as needed
/drop file1.md              # Remove unnecessary files
/tokens                     # Monitor token usage
```

### 2. Lightweight Model Usage Strategy
```bash
# .env setting
export AIDER_WEAK_MODEL=ollama/qwen3:0.6b  # For light tasks

# Switch models
ai-st qwen3:0.6b           # Switch to lightweight model
ai-st deepseek-v3.1:671b-cloud  # For large-scale tasks
```

## Error Handling and Fallback

### 1. Manual Fallback Procedure
How to respond to 502 errors:
1. `/model qwen3:0.6b` - Switch to lightweight model
2. `/clear` - Clear chat history  
3. Split files and reprocess
4. `/tokens` - Check usage

### 2. Preventive Settings
```bash
# Set generous timeout
export AIDER_TIMEOUT=900  # 15 minutes

# Use lightweight model as default
ai-st qwen3:0.6b

# Use large model only for large tasks
ai-st deepseek-v3.1:671b-cloud
ai -y -m "complex task" specific_files.md
ai-st qwen3:0.6b  # Switch back to lightweight model after completion
```

## Practical Operation Patterns

### Daily Use (Lightweight & Fast)
```bash
ai-st qwen3:0.6b
ai -y -m "fix typos" document.md
ai -y -e py  # Process Python files
```

### Important Tasks (High Quality & Time Tolerant)
```bash
ai-st deepseek-v3.1:671b-cloud
export AIDER_TIMEOUT=1800  # 30 minutes
ai -y -m "comprehensive analysis" key_files.md
ai-st qwen3:0.6b  # Switch back after completion
```

### Batch File Processing
```bash
# Example batch processing script
for file in *.md; do
    ai -y -m "process this file" "$file"
    sleep 30  # Reduce server load
done
```

## Monitoring and Optimization

### 1. Monitor Token Usage
```bash
/tokens                    # Current usage
/token-count               # Detailed info
```

### 2. Performance Indicators
- Response time: Lightweight model < 30s, Large model < 5min
- Error rate: 502 errors within 10% is normal range
- Memory usage: Keep under 80% of system resources

## Key Points

- **Aider does not have automatic fallback** - manual response required
- **502 errors are Ollama-side issues** - server optimization is the fundamental solution
- **File splitting is most effective** - avoid batch processing
- **Use lightweight model as default** - use large models only when necessary