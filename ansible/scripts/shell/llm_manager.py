"""Utility for managing local LLM processes used in environment development."""
from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys
import textwrap
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List

PID_DIR = Path(__file__).parent.parent.parent / ".tmp"


@dataclass(frozen=True)
class Service:
    """Definition of a managed process."""

    name: str
    command: List[str]
    log_filename: str
    pid_filename: str

    def log_path(self) -> Path:
        return PID_DIR / self.log_filename

    def pid_path(self) -> Path:
        return PID_DIR / self.pid_filename


def create_ollama_service(target_name: str) -> Service:
    port = "11435" if target_name == "mmn" else "11434"
    return Service(
        name="ollama",
        command=["ollama", "serve", "--host", f"0.0.0.0:{port}"],
        log_filename=f"ollama-{target_name}.log",
        pid_filename=f"ollama-{target_name}.pid",
    )


def create_mlx_service(target_name: str, port: int) -> Service:
    return Service(
        name="mlx",
        command=[
            "mlx_lm.server",
            "--model",
            "mlx-community/Llama-3.2-3B-Instruct-4bit",
            "--host",
            "0.0.0.0",
            "--port",
            str(port),
        ],
        log_filename=f"mlx-{target_name}.log",
        pid_filename=f"mlx-{target_name}.pid",
    )


TARGETS = {
    "mmn": (
        create_ollama_service("mmn"),
        create_mlx_service("mmn", 8081),
    ),
    "mbk": (
        create_ollama_service("mbk"),
        create_mlx_service("mbk", 8080),
    ),
}


def ensure_pid_dir() -> None:
    PID_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)


def is_process_running(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    else:
        return True


def read_pid(path: Path) -> int | None:
    if not path.exists():
        return None
    try:
        value = path.read_text().strip()
        return int(value)
    except (OSError, ValueError):
        return None


def write_pid(path: Path, pid: int) -> None:
    path.write_text(f"{pid}\n")


def remove_pid(path: Path) -> None:
    path.unlink(missing_ok=True)


def start_service(service: Service) -> None:
    ensure_pid_dir()
    pid_path = service.pid_path()
    pid = read_pid(pid_path)
    if pid and is_process_running(pid):
        print(f"• {service.name} already running (pid {pid})")
        return

    log_file = service.log_path()
    with log_file.open("ab", buffering=0) as log_handle:
        try:
            process = subprocess.Popen(
                service.command,
                stdout=log_handle,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
        except FileNotFoundError as exc:
            raise RuntimeError(
                f"Unable to start {service.name}: command '{service.command[0]}' not found"
            ) from exc
        else:
            write_pid(pid_path, process.pid)
            print(f"• Started {service.name} (pid {process.pid})")


def stop_service(service: Service, *, force: bool = False) -> None:
    pid_path = service.pid_path()
    pid = read_pid(pid_path)
    if pid:
        if not is_process_running(pid):
            remove_pid(pid_path)
            print(f"• {service.name} pid {pid} not running; cleaned up pid file")
            return

        sig = signal.SIGKILL if force else signal.SIGTERM
        try:
            os.kill(pid, sig)
        except OSError as exc:  # pragma: no cover - defensive
            print(f"• Failed to stop {service.name} (pid {pid}): {exc}")
        else:
            remove_pid(pid_path)
            print(f"• Stopped {service.name} (pid {pid})")
    else:
        try:
            subprocess.run(
                ["pkill", "-f", service.command[0]],
                check=True,
                capture_output=True,
            )
            print(f"• Stopped {service.name} (killed by process name)")
        except subprocess.CalledProcessError:
            print(f"• {service.name} is not running (no pid file or process found)")


def status_service(service: Service) -> None:
    pid = read_pid(service.pid_path())
    if pid and is_process_running(pid):
        print(f"• {service.name}: running (pid {pid})")
    else:
        print(f"• {service.name}: not running")


def list_targets() -> str:
    entries = [f"  - {name}" for name in sorted(TARGETS)]
    return "\n".join(entries)


def get_services(target: str) -> Iterable[Service]:
    try:
        return TARGETS[target]
    except KeyError as exc:
        raise SystemExit(
            textwrap.dedent(
                f"Unknown target '{target}'. Available targets:\n{list_targets()}"
            )
        ) from exc


def cmd_up(target: str) -> None:
    print(f"🚀 Starting {target} LLM runtimes...")
    for service in get_services(target):
        start_service(service)


def cmd_down(target: str, *, force: bool) -> None:
    print(f"🛑 Stopping {target} LLM runtimes...")
    for service in get_services(target):
        stop_service(service, force=force)


def cmd_ps(target: str) -> None:
    print(f"ℹ️  Status for {target} LLM runtimes:")
    for service in get_services(target):
        status_service(service)


def cmd_logs(target: str) -> None:
    print("Log files:")
    for service in get_services(target):
        print(f"• {service.name}: {service.log_path()}")
    print("Use 'tail -f <log>' to follow output.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Manage local LLM runtimes for development.",
    )
    parser.add_argument(
        "target",
        choices=sorted(TARGETS.keys()),
        help="Target environment to manage",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("up", help="Start the configured services")

    down_parser = subparsers.add_parser("down", help="Stop the configured services")
    down_parser.add_argument(
        "--force",
        action="store_true",
        help="Force-stop services using SIGKILL",
    )

    subparsers.add_parser("ps", help="Show running status of services")

    subparsers.add_parser("logs", help="Display log file locations")

    return parser


def main(argv: List[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    command_map = {
        "up": lambda a: cmd_up(a.target),
        "down": lambda a: cmd_down(a.target, force=getattr(a, 'force', False)),
        "ps": lambda a: cmd_ps(a.target),
        "logs": lambda a: cmd_logs(a.target),
    }

    try:
        command_func = command_map.get(args.command)
        if command_func:
            command_func(args)
        else:  # pragma: no cover - argparse enforces choices
            parser.error(f"Unknown command {args.command}")
            return 2
    except RuntimeError as exc:
        print(exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
