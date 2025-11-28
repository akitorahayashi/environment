# ansible/ansible.just

# Determine project root (fixed regardless of caller)
# When imported into the root justfile, justfile_directory() returns the root directory.
root_dir := justfile_directory()

# Common: Ansible Playbook execution wrapper
# @hidden
_run_ansible role profile tag *args="":
    @if [ ! -f {{root_dir}}/.env ]; then echo "❌ Error: .env not found"; exit 1; fi
    @export $(grep -v '^#' {{root_dir}}/.env | xargs) && \
    export ANSIBLE_CONFIG={{root_dir}}/ansible/ansible.cfg && \
    uv run ansible-playbook -i {{root_dir}}/ansible/hosts {{root_dir}}/ansible/playbook.yml \
      --limit localhost \
      --tags "{{tag}}" \
      -e "profile={{profile}}" \
      -e "repo_root_path={{root_dir}}" \
      {{args}}
