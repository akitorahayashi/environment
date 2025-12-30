"""Type definitions for menv configuration."""

from __future__ import annotations

from typing import TypedDict


class IdentityConfig(TypedDict):
    """Identity configuration for VCS."""

    name: str
    email: str


class MenvConfig(TypedDict):
    """Full menv configuration."""

    personal: IdentityConfig
    work: IdentityConfig
