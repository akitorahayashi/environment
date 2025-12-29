"""Path resolution for package-internal Ansible resources."""

from importlib.resources import as_file, files
from pathlib import Path


def get_ansible_dir() -> Path:
    """Get the path to the ansible directory within the package.

    Returns:
        Path to the ansible directory.
    """
    source = files("menv").joinpath("ansible")
    with as_file(source) as ansible_path:
        return Path(ansible_path)


def get_playbook_path() -> Path:
    """Get the path to the main playbook.yml file.

    Returns:
        Path to playbook.yml.
    """
    return get_ansible_dir() / "playbook.yml"


def get_ansible_config_path() -> Path:
    """Get the path to ansible.cfg configuration file.

    Returns:
        Path to ansible.cfg.
    """
    return get_ansible_dir() / "ansible.cfg"
