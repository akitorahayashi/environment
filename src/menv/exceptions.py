"""Custom exceptions for menv."""


class MenvError(Exception):
    """Base exception for all menv errors."""

    pass


class AnsibleExecutionError(MenvError):
    """Raised when ansible-playbook execution fails."""

    def __init__(self, message: str, returncode: int | None = None) -> None:
        super().__init__(message)
        self.returncode = returncode


class VersionCheckError(MenvError):
    """Raised when version checking or upgrading fails."""

    pass


class AnsiblePathsError(MenvError):
    """Raised when resolving Ansible paths fails."""

    pass
