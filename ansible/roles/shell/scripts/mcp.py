#!/usr/bin/env python3
"""MCP Configuration Management CLI."""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


def validate_server_name(name: str, command: str) -> None:
    """Validate that server name is provided."""
    if not name:
        print("Error: MCP server name is required")
        print(f"Usage: {command} <mcp-server-name>")
        sys.exit(1)


def validate_local_config(suggest_init: bool = False) -> None:
    """Validate that .mcp.json exists in current directory."""
    if not Path(".mcp.json").exists():
        print("Error: .mcp.json file not found in current directory")
        if suggest_init:
            print("Run 'mcp-ini' first to create .mcp.json")
        sys.exit(1)


def validate_global_config() -> None:
    """Validate that ~/.mcp.json exists."""
    global_config = Path.home() / ".mcp.json"
    if not global_config.exists():
        print("Error: ~/.mcp.json file not found")
        sys.exit(1)


def server_exists_global(name: str) -> bool:
    """Check if server exists in global config."""
    global_config = Path.home() / ".mcp.json"
    with open(global_config) as f:
        data = json.load(f)
    return name in data.get("mcpServers", {})


def server_exists_local(name: str) -> bool:
    """Check if server exists in local config."""
    with open(".mcp.json") as f:
        data = json.load(f)
    return name in data.get("mcpServers", {})


def show_available_servers(config_file: Path) -> None:
    """Show available servers in config."""
    with open(config_file) as f:
        data = json.load(f)
    servers = list(data.get("mcpServers", {}).keys())
    if servers:
        print("Available servers:")
        for server in servers:
            print(f"  {server}")
    else:
        print("No servers available")


def cmd_ini() -> None:
    """Initialize .mcp.json in current directory."""
    if Path(".mcp.json").exists():
        print(".mcp.json file already exists in current directory")
        sys.exit(1)

    with open(".mcp.json", "w") as f:
        json.dump({"mcpServers": {}}, f, indent=2)
    print("✅ Created .mcp.json with mcpServers key in current directory")


def cmd_ini_f() -> None:
    """Initialize .mcp.json from global config."""
    validate_global_config()
    if Path(".mcp.json").exists():
        print(".mcp.json file already exists in current directory")
        sys.exit(1)

    global_config = Path.home() / ".mcp.json"
    shutil.copy(global_config, ".mcp.json")
    print("✅ Created .mcp.json in current directory from ~/.mcp.json")


def cmd_ls() -> None:
    """List available MCP servers."""
    validate_global_config()
    global_config = Path.home() / ".mcp.json"

    with open(global_config) as f:
        data = json.load(f)

    servers = data.get("mcpServers", {})
    if not servers:
        print("No MCP servers found in ~/.mcp.json")
        sys.exit(1)

    print("Available MCP servers:")
    print("=====================")

    for name, config in servers.items():
        command = config.get("command")
        if command:
            args = config.get("args", [])
            full_command = f"{command} {' '.join(args)}" if args else command
            description = config.get("description", "No description available")

            print(f"[{name}]")
            print(f"{full_command}")
            print(f"- {description}")
            print()
        else:
            print(f"[{name}]: No command found")
            print()


def cmd_a(names: list[str]) -> None:
    """Add servers to local config."""
    validate_local_config(suggest_init=True)
    validate_global_config()

    for name in names:
        validate_server_name(name, "mcp-a")

        if not server_exists_global(name):
            print(f"Error: MCP server '{name}' not found in ~/.mcp.json")
            show_available_servers(Path.home() / ".mcp.json")
            continue

        if server_exists_local(name):
            print(f"Error: MCP server '{name}' already exists in local .mcp.json")
            continue

        # Get server config from global
        global_config = Path.home() / ".mcp.json"
        with open(global_config) as f:
            global_data = json.load(f)

        server_config = global_data["mcpServers"][name]

        # Add to local
        with open(".mcp.json") as f:
            local_data = json.load(f)

        local_data["mcpServers"][name] = server_config

        with open(".mcp.json", "w") as f:
            json.dump(local_data, f, indent=2)

        print(f"✅ Added MCP server '{name}' to local .mcp.json")


def cmd_rm(name: str) -> None:
    """Remove server from local config."""
    validate_server_name(name, "mcp-rm")
    validate_local_config()

    if not server_exists_local(name):
        print(f"Error: MCP server '{name}' not found in local .mcp.json")
        print("Available servers in local config:")
        show_available_servers(Path(".mcp.json"))
        sys.exit(1)

    with open(".mcp.json") as f:
        data = json.load(f)

    del data["mcpServers"][name]

    with open(".mcp.json", "w") as f:
        json.dump(data, f, indent=2)

    print(f"✅ Removed MCP server '{name}' from local .mcp.json")


def cmd_cmd(name: str) -> None:
    """Show command for server and copy to clipboard."""
    validate_server_name(name, "mcp-cmd")
    validate_global_config()

    if not server_exists_global(name):
        print(f"Error: MCP server '{name}' not found in ~/.mcp.json")
        show_available_servers(Path.home() / ".mcp.json")
        sys.exit(1)

    global_config = Path.home() / ".mcp.json"
    with open(global_config) as f:
        data = json.load(f)

    config = data["mcpServers"][name]
    command = config.get("command")
    if not command:
        print(f"Error: No command found for MCP server '{name}'")
        sys.exit(1)

    args = config.get("args", [])
    full_command = f"{command} {' '.join(args)}" if args else command

    print(f"Command for '{name}': {full_command}")

    # Copy to clipboard
    add_format = f"{name} {full_command}"
    try:
        subprocess.run(["pbcopy"], input=add_format.encode(), check=True)
        print(f"📋 Copied to clipboard: {add_format}")
    except subprocess.CalledProcessError:
        print("Failed to copy to clipboard")


def main():
    parser = argparse.ArgumentParser(description="MCP Configuration Management")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # ini
    subparsers.add_parser("ini", help="Initialize .mcp.json in current directory")

    # ini-f
    subparsers.add_parser("ini-f", help="Initialize .mcp.json from global config")

    # ls
    subparsers.add_parser("ls", help="List available MCP servers")

    # a
    parser_a = subparsers.add_parser("a", help="Add server to local config")
    parser_a.add_argument("names", nargs="+", help="Server names")

    # rm
    parser_rm = subparsers.add_parser("rm", help="Remove server from local config")
    parser_rm.add_argument("name", help="Server name")

    # cmd
    parser_cmd = subparsers.add_parser("cmd", help="Show command for server")
    parser_cmd.add_argument("name", help="Server name")

    args = parser.parse_args()

    if args.command == "ini":
        cmd_ini()
    elif args.command == "ini-f":
        cmd_ini_f()
    elif args.command == "ls":
        cmd_ls()
    elif args.command == "a":
        cmd_a(args.names)
    elif args.command == "rm":
        cmd_rm(args.name)
    elif args.command == "cmd":
        cmd_cmd(args.name)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
