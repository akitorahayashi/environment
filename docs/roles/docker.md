# Docker Role

The `docker` role keeps a set of Docker images cached locally so AI services and tooling can run without extra network time.

## Tag
- `docker`

Call `just docker-images` to execute it. The tag is also available in `ansible/playbook.yml` for CI usage.

## Tasks
- Read `ansible/roles/docker/config/common/images.txt` and convert it into a list of repository tags.
- Pull each image using `docker pull`, reporting the result for visibility.
- After pulling, display the local images table with `docker images --format 'table {{.Repository}}:{{.Tag}}'`.

Update `images.txt` to adjust which images are preloaded—currently it includes `voicevox/voicevox_engine:cpu-ubuntu22.04-latest`, `ollama/ollama:latest`, and `mcp/sequentialthinking`.
