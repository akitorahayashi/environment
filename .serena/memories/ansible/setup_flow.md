# Ansible Collection Management Flow

- All Ansible collections required by the project are listed in `ansible/collections/requirements.yml`.
- Collections are installed into the repo-local cache (`.ansible/collections`) rather than the home directory to avoid permission issues.
- The cache and download directories (`.ansible/collections`, `.ansible/galaxy_cache`, `.ansible/tmp`) are created automatically by the `just ansible-collections` recipe.
- `just ansible-collections` runs automatically at the start of `just common`, ensuring collection dependencies are present before any roles execute when `make macbook` or `make mac-mini` call `just common`.
- Developers can run `just ansible-collections` manually after updating `ansible/collections/requirements.yml`; otherwise, the automated invocation keeps collections current.
- `ANSIBLE_COLLECTIONS_PATH`, `ANSIBLE_GALAXY_CACHE_DIR`, and related environment variables are exported in `_run_ansible` so every playbook run uses the repo-local paths.
