# Aider's File Search and Discovery Capabilities and Usage

## Core Features

### 1. Automatic Understanding via Repo-map Feature
- **Overall Analysis**: Automatically analyzes the entire codebase using tree-sitter
- **Dependency Graph**: Grasps definitions and usage locations of functions, variables, and classes
- **Dynamic Optimization**: Selects highly relevant files using graph ranking algorithms
- **Token Control**: Adjustable size with `--map-tokens` setting (default 1k tokens)

### 2. File Search and Discovery Patterns
- **Tracking Specific Elements**: Automatically identifies files where functions/variables are used
- **Discovery of Related Files**: Proposes optimal file sets based on dependencies
- **Context Reference**: Provides context by referencing files outside the editing targets

## Practical Usage Methods

### Command Line Launch
```bash
# Specify files with wildcards
aider src/*.py

# Target entire directory
aider src/
```

### File Management Within Session
```bash
/add <filename>        # Add single file
/add src/*.py         # Pattern matching
/add src              # Recursive directory addition
/read-only <file>     # Read-only file
/ls                   # List current files
/drop <filename>      # Remove file
```

## Best Practices

### 1. Principle of Minimality
- **Add only the minimum necessary files**
- Since repo-map automatically provides related context, excessive additions are inefficient
- Include only files that need editing in the session

### 2. Step-by-Step Approach
- Divide work into small steps
- Dynamically adjust file sets with `/drop` and `/add` as needed
- Keep the session's focus clear

### 3. Handling Large Repositories
- Limit working scope with `--subtree-only`
- Exclude unnecessary parts with `.aiderignore` file
- Prioritize performance optimization

## Automation Features

### Implicit Automatic Discovery
- **File Identification**: LLM uses repo-map to automatically identify necessary files
- **Addition Suggestions**: Automatically suggests adding related files
- **File Creation**: Suggests creation when specifying non-existent files

### Detection and Processing Features
- **URL Detection**: Automatically suggests scraping when pasting URLs
- **Dependency Analysis**: Automatic tracking of import/include statements
- **Code Structure Understanding**: Automatic grasp of class and function hierarchies

## Usage Scenario Examples

### Refactoring Work
1. `/add` only the main files
2. Aider automatically identifies related files
3. Propose additional files as needed

### Bug Fixing
1. Start from the problematic file
2. Automatically analyze impact scope with repo-map
3. Dynamically add related test files

### New Feature Development
1. `/add` the implementation target files
2. Gradually add interface-related files
3. Include test and documentation files as well

## Important Points to Understand

- Aider **edits only specified files**, but **references the entire repository**
- Explicit search commands are unnecessary due to repo-map functionality
- Dynamic and interactive file management is the most effective approach