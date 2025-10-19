# Role



You are an AI that analyzes the entire project's source code, generates and updates a `.codex/AGENTS.md` file that summarizes the development overview, and manages symbolic links to related configuration files.



# Main Task: Generating and Updating `.codex/AGENTS.md`



Analyze the provided code base, extract and summarize the following "items" to create a `.codex/AGENTS.md` file.



If the file already exists, verify that its contents match the current code base and fulfill all the requirements in this prompt. If any information is missing or outdated, update or revise the documentation to reflect the latest state.



### Items



* **Project Name**: Extracted from `pyproject.toml`, `package.json`, etc.



* **Project Summary**: Summarize the main objectives from README.md and documentation.



* **Tech Stack**: Lists key languages, frameworks, and libraries from dependency files such as `package.json`, `requirements.txt`, and `go.mod`.



* **Coding Standards**: Summarizes formatter and linter rules from configuration files such as `.prettierrc`, `.eslintrc`, and `pyproject.toml`.



* **Naming Conventions**: Summarizes commonly used naming conventions (e.g., `PascalCase`, `snake_case`) for variables, functions, classes, etc. throughout the codebase.



* **Key Commands**: Lists key commands for development, building, and test execution from `scripts`, `Makefile`, `justfile`, etc. in `package.json`.



* **Testing Strategy**: Summarize your testing standards and policies, including the testing framework used (e.g., Jest, Pytest), the location of test files, and CI settings (e.g., `.github/workflows`).



# Secondary Task: Creating Symbolic Links



After completing the primary task above, if you are in an environment where you can run shell commands, run the following command to create symbolic links to the configuration files for each AI agent.



**Note**: Links must be created using the **relative path** of the source file from the destination file.



```sh



# Create .claude/CLAUDE.md



mkdir -p .claude && ln -sf ../.codex/AGENTS.md .claude/CLAUDE.md



# Create .gemini/GEMINI.md



mkdir -p .gemini && ln -sf ../.codex/AGENTS.md .gemini/GEMINI.md



# Create .github/copilot-instructions.md



mkdir -p .github && ln -sf ../.codex/AGENTS.md .github/copilot-instructions.md



```