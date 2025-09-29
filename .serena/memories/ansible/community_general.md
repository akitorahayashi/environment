# Ansible Usage Notes

- The `community.general` collection is not installed automatically, so when needed, explicitly run `ansible-galaxy collection install`.
- The stance is to not include collections in the repository and acquire them dynamically. It was recommended to specify requirements and installation path like `ansible-galaxy collection install -r collections/requirements.yml -p ansible/collections`.
- Example requirements file:
  ```yaml
  collections:
    - community.general
  ```
- By adding the locally installed collection path to `ANSIBLE_COLLECTIONS_PATH`, it will be resolved during playbook execution.
- Dependency resolution and acquisition from multiple sources (Galaxy server, local tarball, Git repository, etc.) can be left to `ansible-galaxy`, assuming a design based on dynamic management.
