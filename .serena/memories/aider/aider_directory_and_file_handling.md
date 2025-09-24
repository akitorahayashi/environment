# Aider Directory and File Handling Specifications

## Directory Behavior When Specified

### Directory Specification in Command Line Arguments
- **Single Directory Specification**: Treated as the Git repository root, files are not automatically added.
- **No Automatic File Addition**: With only directory arguments, files are not added to the chat.

### Directory Processing with /add Command
```bash
/add directory/          # Add files within the directory
/add directory/*.md      # Add only specific extensions
```

## File Selection and Filtering Rules

### Git Tracking Dependency
- **Basic Principle**: Only files tracked by Git are targeted.
- **Untracked Files**: Files ignored by .gitignore or untracked files are excluded.

### Pattern Matching
- **Wildcard Support**: Patterns like `*.md`, `src/*.py` can be used.
- **Glob Processing**: Processed by the glob_filtered_to_repo method.
- **Special Character Escaping**: Special characters in file paths are automatically escaped.

## File Reading Restrictions

### Restrictions Outside Git Repository
- **Outside Root Directory**: Files other than images cannot be added outside the repository.
- **Security Restrictions**: File access is restricted beyond repository boundaries.

### Special Character Handling
- **Unicode Characters**: Generally processable.
- **OS-Specific Restrictions**: Restrictions on filenames containing quotes in Windows environments.
- **Path Processing**: Automatic escaping handles special characters.

## Causes of "empty file" Error

### Main Causes
1. **File Read Failure**: When content is None in io.read_text method.
2. **Permission Issues**: Insufficient file access permissions.
3. **Character Encoding**: Invalid character encoding.
4. **Git Tracking**: Attempting to read untracked files.

## Combination with --message Option

### Basic Usage
```bash
# Correct patterns
aider --message "summarize" directory/*.md

# Note on directory specification
aider --message "analyze" directory/  # Files not automatically added
```

### Best Practices
- **Minimal Files**: Specify only the necessary minimum files.
- **Leverage repo-map**: Utilize automatic context provision.
- **Token Efficiency**: Avoid increased costs from excessive file additions.

### Performance Optimization
```bash
# Limit working scope
aider --subtree-only --message "task" files

# Exclude unnecessary parts (using .aiderignore file)
aider --message "task" files
```

## Practical Usage Examples

### Normal Operation Patterns
```bash
# Summarize Markdown files
aider --yes --message "summarize all content" docs/*.md

# Analyze specific directory
aider --yes --message "analyze code" src/**/*.py

# Support for multiple extensions
aider --yes --message "review" *.{js,ts,jsx,tsx}
```

### Problem Avoidance Patterns
```bash
# Run within Git repository
cd /path/to/git-repo
aider --message "task" files

# Explicit file specification
aider --message "task" file1.md file2.md file3.md
```

## Troubleshooting

### Notes When Implementing -d Option
1. **Shell Glob Expansion**: `directory/*` is expanded by the shell in advance.
2. **Untracked Files**: Errors if expanded files are not Git-tracked.
3. **Path Normalization**: Unify relative and absolute paths.
4. **Extension Filtering**: Explicit extension filtering as needed.

### Solutions
- **Check Git Status**: Confirm file tracking status in advance.
- **Explicit Path Specification**: Specify specific files rather than wildcards.
- **Error Handling**: Proper handling when file reading fails.

## Important Points

- Aider's file processing is **Git-centric design**.
- Directory specification alone does **not automatically add files**.
- **Pattern matching** and **/add command** are the actual addition methods.
- **repo-map feature** recommends specifying the minimum necessary files.