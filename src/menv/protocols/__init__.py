"""Protocol definitions for menv."""

from menv.protocols.ansible_paths import AnsiblePathsProtocol
from menv.protocols.ansible_runner import AnsibleRunnerProtocol
from menv.protocols.config_deployer import ConfigDeployerProtocol, DeployResult
from menv.protocols.config_storage import ConfigStorageProtocol
from menv.protocols.version_checker import VersionCheckerProtocol

__all__ = [
    "AnsiblePathsProtocol",
    "AnsibleRunnerProtocol",
    "ConfigDeployerProtocol",
    "ConfigStorageProtocol",
    "DeployResult",
    "VersionCheckerProtocol",
]
