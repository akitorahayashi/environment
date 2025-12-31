"""Application context for dependency injection."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from menv.protocols import (
        AnsiblePathsProtocol,
        AnsibleRunnerProtocol,
        ConfigDeployerProtocol,
        ConfigStorageProtocol,
        VersionCheckerProtocol,
    )


@dataclass
class AppContext:
    """Application context container for DI."""

    config_storage: ConfigStorageProtocol
    ansible_paths: AnsiblePathsProtocol
    ansible_runner: AnsibleRunnerProtocol
    version_checker: VersionCheckerProtocol
    config_deployer: ConfigDeployerProtocol
