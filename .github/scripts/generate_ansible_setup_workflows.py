#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / ".github/ansible-setup-targets.yml"
WORKFLOWS = ROOT / ".github/workflows"
HEADER = (
    "# This file is auto-generated. Do not edit manually.\n"
    "# Source: .github/ansible-setup-targets.yml\n\n"
)
CHECKOUT = "actions/checkout@93cb6efe18208431cddfb8368fd83d5badbf9bfd # v5.0.1"
PATHS_FILTER = "dorny/paths-filter@fbd0ab8f3e69293af611ebaee6363fc25e6d187d # v3.0.2"
UPLOAD_ARTIFACT = "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1"
SHARED_PATHS = [
    "src/assets/ansible/playbook.yml",
    "src/assets/ansible/ansible.cfg",
    ".github/ansible-setup-targets.yml",
    ".github/scripts/generate_ansible_setup_workflows.py",
]


def indent(lines: list[str], spaces: int) -> list[str]:
    prefix = " " * spaces
    return [f"{prefix}{line}" if line else "" for line in lines]


def setup_workflow(target: str, config: dict[str, object]) -> str:
    commands = [f'"$RUNNER_TEMP/mev-bin/mev" make {command}' for command in config["commands"]]
    verify = list(config.get("verify", []))
    env = config.get("env", {})

    lines = [
        f"name: Setup {config['name']}",
        "",
        "on:",
        "  workflow_call:",
        "",
        "permissions:",
        "  contents: read",
        "",
        "jobs:",
        f"  setup-{target}:",
        "    runs-on: macos-15",
        "    steps:",
        "      - name: Checkout repository",
        f"        uses: {CHECKOUT}",
        "        with:",
        "          persist-credentials: false",
        "",
        "      - name: Download mev binary",
        "        uses: ./.github/actions/download-mev-binary",
        "",
        "      - name: Setup Ansible environment",
        "        uses: ./.github/actions/setup-ansible",
        "",
        f"      - name: Run {target} setup",
        "        shell: bash",
    ]
    if env:
        lines.append("        env:")
        lines.extend(f'          {key}: "{value}"' for key, value in env.items())
    lines.extend(["        run: |", "          set -euo pipefail"])
    lines.extend(indent(commands, 10))

    if verify:
        lines.extend(
            [
                "",
                f"      - name: Verify {target} setup",
                "        shell: bash",
                "        run: |",
                "          set -euo pipefail",
            ]
        )
        lines.extend(indent(verify, 10))

    return HEADER + "\n".join(lines) + "\n"


def verify_workflow(targets: dict[str, dict[str, object]]) -> str:
    names = list(targets)
    setup_outputs = [f"setup_{name.replace('-', '_')}" for name in names]
    target_paths = sorted(
        {
            f"src/assets/ansible/roles/{role}/**"
            for config in targets.values()
            for role in config["roles"]
        }
        | set(SHARED_PATHS)
    )
    any_setup = "\n          ".join(
        [f"steps.filter.outputs.{name} == 'true' ||" for name in setup_outputs[:-1]]
        + [f"steps.filter.outputs.{setup_outputs[-1]} == 'true'"]
    )

    lines = [
        "name: Verify Ansible Setup",
        "",
        "on:",
        "  push:",
        '    branches: [ "main" ]',
        "    paths:",
    ]
    lines.extend(f"      - '{path}'" for path in target_paths)
    lines.append("      - '.github/workflows/setup-*.yml'")
    lines.extend(
        [
            "  pull_request:",
            '    branches: [ "main" ]',
            "    paths:",
        ]
    )
    lines.extend(f"      - '{path}'" for path in target_paths)
    lines.extend(
        [
            "      - '.github/workflows/setup-*.yml'",
            "  workflow_dispatch:",
            "    inputs:",
            "      target:",
            "        description: 'Setup target to run'",
            "        required: false",
            "        default: 'all'",
            "        type: choice",
            "        options:",
            "          - all",
        ]
    )
    lines.extend(f"          - {name}" for name in names)
    lines.extend(
        [
            "",
            "jobs:",
            "  changes:",
            "    name: Detect setup-related changes",
            "    runs-on: ubuntu-latest",
            "    permissions:",
            "      contents: read",
            "      pull-requests: read",
            "    outputs:",
        ]
    )
    lines.extend(f"      {name}: ${{{{ steps.filter.outputs.{name} }}}}" for name in setup_outputs)
    lines.extend(
        [
            "      any_setup: >-",
            "        ${{",
            f"          {any_setup}",
            "        }}",
            "    steps:",
            "      - name: Checkout code",
            f"        uses: {CHECKOUT}",
            "        with:",
            "          fetch-depth: 0",
            "          persist-credentials: false",
            "",
            "      - name: Detect changed paths",
            "        id: filter",
            f"        uses: {PATHS_FILTER}",
            "        with:",
            "          filters: |",
        ]
    )
    for name, config in targets.items():
        output = f"setup_{name.replace('-', '_')}"
        lines.append(f"            {output}:")
        lines.extend(f"              - 'src/assets/ansible/roles/{role}/**'" for role in config["roles"])
        lines.append(f"              - '.github/workflows/setup-{name}.yml'")

    lines.extend(
        [
            "",
            "  build-mev:",
            "    name: Build mev binary",
            "    needs: changes",
            "    runs-on: macos-15",
            "    permissions:",
            "      contents: read",
            "    if: |",
            "      github.event_name == 'workflow_dispatch' ||",
            "      needs.changes.outputs.any_setup == 'true'",
            "    steps:",
            "      - name: Checkout repository",
            f"        uses: {CHECKOUT}",
            "        with:",
            "          persist-credentials: false",
            "",
            "      - name: Setup build environment",
            "        uses: ./.github/actions/setup-build",
            "",
            "      - name: Build mev binary",
            "        run: cargo build --release --locked",
            "",
            "      - name: Prepare mev binary artifact",
            "        shell: bash",
            "        run: |",
            "          set -euo pipefail",
            '          mkdir -p "$RUNNER_TEMP/mev-artifact"',
            '          cp target/release/mev "$RUNNER_TEMP/mev-artifact/mev"',
            '          chmod +x "$RUNNER_TEMP/mev-artifact/mev"',
            "",
            "      - name: Upload mev binary artifact",
            f"        uses: {UPLOAD_ARTIFACT}",
            "        with:",
            "          name: mev-${{ runner.os }}-${{ runner.arch }}",
            "          path: ${{ runner.temp }}/mev-artifact/mev",
            "          if-no-files-found: error",
            "          retention-days: 1",
        ]
    )

    for name in names:
        output = f"setup_{name.replace('-', '_')}"
        lines.extend(
            [
                "",
                f"  setup-{name}:",
                "    needs:",
                "      - changes",
                "      - build-mev",
                "    permissions:",
                "      contents: read",
                "    if: |",
                f"      (github.event_name == 'workflow_dispatch' && (github.event.inputs.target == 'all' || github.event.inputs.target == '{name}')) ||",
                f"      needs.changes.outputs.{output} == 'true'",
                f"    uses: ./.github/workflows/setup-{name}.yml",
            ]
        )

    return HEADER + "\n".join(lines) + "\n"


def generated_files(targets: dict[str, dict[str, object]]) -> dict[Path, str]:
    files = {
        WORKFLOWS / f"setup-{name}.yml": setup_workflow(name, config)
        for name, config in targets.items()
    }
    files[WORKFLOWS / "verify-ansible-setup.yml"] = verify_workflow(targets)
    return files


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    manifest = yaml.safe_load(MANIFEST.read_text())
    targets = manifest["targets"]
    expected = generated_files(targets)
    setup_files = set(WORKFLOWS.glob("setup-*.yml"))
    stale = setup_files - set(expected)

    if args.check:
        mismatches = [path for path, content in expected.items() if not path.exists() or path.read_text() != content]
        for path in [*mismatches, *sorted(stale)]:
            print(f"generated workflow is stale: {path.relative_to(ROOT)}", file=sys.stderr)
        return 1 if mismatches or stale else 0

    for path in stale:
        path.unlink()
    for path, content in expected.items():
        path.write_text(content)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
