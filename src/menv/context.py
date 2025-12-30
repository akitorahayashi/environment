"""Application context for dependency injection."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from menv.protocols import ConfigStorage


@dataclass
class AppContext:
    """Application context container for DI."""

    config_storage: ConfigStorage
