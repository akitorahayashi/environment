# Aider Model Settings (`.aider.model.settings.yml`) Reference

This is a reference for configuring `aider`'s behavior in detail for each model. This file can be placed in the home directory or project root for use.

---

## 1. Basic Settings

Define the basic behavior and identifiers of the model.

-   **`name`**: A unique identifier for the model. This serves as the key for `aider` to apply settings. (Example: `ollama/qwen2.5-coder:32b-instruct-fp16`)
-   **`edit_format`**: Specifies the output format for code editing.
    -   `whole`: Replaces the entire file.
    -   `diff`: Outputs changes in diff format. **(Recommended)**
    -   `udiff`: Outputs in unified diff format.
    -   `architect`: Takes a two-stage approach of design and implementation.
-   **`use_repo_map`**: When set to `true`, generates a repository-wide structure map and enables automatic identification of related files. Particularly effective for large repositories.

---

## 2. Behavior Control Settings

Control `aider`'s interactive behavior and execution timing.

-   **`send_undo_reply`**: Controls whether to send a confirmation response from the model when executing the `undo` command. Usually `false` is fine.
-   **`lazy`**: Lazy execution mode. When `true`, changes are not applied immediately, and user approval is awaited.
-   **`reminder`**: Specifies the format for sending reminder messages (such as context summaries).
    -   `user`: Sends as a user message.
    -   `sys`: Sends as a system message. **(Recommended)**
-   **`examples_as_sys_msg`**: When `true`, examples in the prompt are treated as system messages.

---

## 3. System Settings

Adjust `aider`'s internal behavior and integration with APIs.

-   **`cache_control`**: Enables/disables the prompt caching feature.
-   **`caches_by_default`**: Whether to use caching by default.
-   **`use_system_prompt`**: Controls the use of system prompts. `true` is recommended to stabilize model behavior.
-   **`use_temperature`**: Specify `true` or a specific floating-point number (e.g., `0.7`) to enable the `temperature` parameter, which controls output diversity.
-   **`streaming`**: When `true`, displays responses from the model in real-time streaming.

---

## 4. Other Available Options

Additional options for more advanced customization.

-   **`weak_model_name`**: Specifies an auxiliary model for lightweight tasks such as generating commit messages.
-   **`overeager`**: When `true`, attempts more aggressive edits (wider-ranging changes).
-   **`editor_model_name`**: Specifies the editor model when using `edit_format: architect` mode.
-   **`editor_edit_format`**: Specifies the edit format for the above editor model.
-   **`reasoning_tag`**: Specifies a tag for displaying the model's thought process.
-   **`system_prompt_prefix`**: Specifies custom text to add before the system prompt.
-   **`accepts_settings`**: Specifies a list of special settings (provider-specific features, etc.) that the model accepts.

---

## 5. `extra_params`

Specify additional parameters to pass directly to the model provider's API (Ollama, OpenAI, etc.). This allows leveraging provider-specific features not standardly supported by `aider`.

-   **`num_ctx`**: (For Ollama) Specifies the context window size. It is **strongly recommended** to set an appropriate value like `8192`, as too small a value may cause older conversations to be lost.
-   **`max_tokens`**: (For OpenAI, etc.) Specifies the maximum number of tokens to generate in the response.
-   **`temperature`**, **`top_p`**: Adjust the model's output diversity or randomness.

### Configuration Example (For Ollama)

```yaml
- name: ollama/qwen2.5-coder:32b-instruct-fp16
  edit_format: diff
  use_repo_map: true
  use_system_prompt: true
  streaming: true
  extra_params:
    num_ctx: 8192
```