# Aider Timeout Configuration and Optimization

## Basic Timeout Settings

### Default Settings
- **Default Timeout**: None (Unlimited)
- **Actual Behavior**: Applied per API call
- **Scope**: All LLM API communications (including Ollama)

### How to Configure

#### 1. Command Line Argument
```bash
aider --timeout 300        # 5 minutes
aider --timeout 1800       # 30 minutes  
aider --timeout 3600       # 1 hour
```

#### 2. Environment Variable
```bash
export AIDER_TIMEOUT=300
aider [other-options]
```

#### 3. Configuration File
Add to `.aider.conf.yml`:
```yaml
timeout: 300
```

## Practical Timeout Settings

### Recommended Values by Task Size
- **Single file edit**: 300 seconds (5 minutes)
- **Multiple file operations**: 900 seconds (15 minutes)
- **Full project translation**: 1800-3600 seconds (30 minutes - 1 hour)
- **Large-scale refactoring**: 3600 seconds or more (1 hour+)

### Settings for Benchmark Environments
- **Long-duration testing**: 86400 seconds (24 hours)
- **CI/CD environments**: Adjust as needed

## Ollama-Specific Optimization

### Server-Side Settings
```bash
# Increase context size (important)
export OLLAMA_CONTEXT_LENGTH=8192

# API Base settings
export OLLAMA_API_BASE=http://127.0.0.1:11434
export OLLAMA_API_KEY=<api-key>  # Only if needed
```

### Troubleshooting
```bash
# Disable SSL verification (if needed)
aider --no-verify-ssl --timeout 1800

# Settings for large models
aider --timeout 3600 --model ollama/deepseek-v3.1:671b-cloud
```

## Error Patterns and Solutions

### "Command timed out after 2m 0.0s"
- **Cause**: Timeout setting on aider side (default 120 seconds)
- **Solution**: Extend timeout with `--timeout` option

### "502 Bad Gateway: upstream error"  
- **Cause**: Ollama server-side issue
- **Solution 1**: Increase context size
- **Solution 2**: Restart server
- **Solution 3**: Use a lighter model

### "unmarshal: invalid character"
- **Cause**: Ollama response format error
- **Solution**: Improve server stability and implement retry strategy

## Recommended Workflow

### 1. Environment Setup
```bash
# Add to .zshrc or .bashrc
export AIDER_TIMEOUT=1800
export OLLAMA_CONTEXT_LENGTH=8192
```

### 2. Project-Specific Settings
```yaml
# .aider.conf.yml
timeout: 3600
model: ollama/qwen3:0.6b
no-auto-commit: true
no-gitignore: true
```

### 3. For Large-Scale Tasks
```bash
# Check Ollama server status beforehand
ollama list

# Run with sufficient timeout
aider --timeout 7200  # 2 hours
```

## Troubleshooting

### Timeout Decision Flow
1. **Completes within 2 minutes** → Normal
2. **Timeout at 2 minutes** → Extend `--timeout`
3. **502 error occurs** → Check Ollama server
4. **Repeated errors** → Switch to lighter model

### Stability Improvement Techniques
- **Stepwise processing**: Break large tasks into smaller ones
- **Model selection**: Use lighter models for stability
- **Resource monitoring**: Check CPU/memory usage
- **Resource monitoring**: Monitor Ollama daemon resource usage

## Key Points

- Timeout settings apply **per API call**
- Ollama server **context size** greatly affects performance
- For large tasks, set a **sufficiently generous timeout**
- When errors occur, it's important to distinguish between **aider vs Ollama** issues