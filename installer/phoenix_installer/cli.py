"""Interactive Linux terminal interface for Phoenix Engine Setup."""

from __future__ import annotations

import argparse
import getpass
import platform
from pathlib import Path
from typing import Callable

from .core import (
    DBConfig,
    PhoenixCore,
    ServerConfig,
    build_web_archive,
    format_command,
    generate_password,
    load_db_config,
    load_server_config,
    save_db_config,
    save_server_config,
    validate_db_config,
    validate_server_config,
)
from .i18n import LANGUAGES, tr


class PhoenixCLI:
    """Menu-driven interface sharing the same safe backend as the GUI."""

    def __init__(self, project: Path | None = None, language: str | None = None) -> None:
        self.language = language if language in LANGUAGES else "en"
        self.core = PhoenixCore(project)
        self.db_config = load_db_config(self.core.project)
        self.server_config = load_server_config(self.core.project)

    def t(self, key: str, **values: object) -> str:
        return tr(self.language, key, **values)

    def _ask(self, key: str, default: str = "", secret: bool = False) -> str:
        suffix = f" [{default}]" if default and not secret else ""
        reader = getpass.getpass if secret else input
        value = reader(f"{self.t(key)}{suffix}: ").strip()
        return value or default

    def _confirm(self, key: str, default: bool = False, **values: object) -> bool:
        hint = "Y/n" if default else "y/N"
        answer = input(f"{self.t(key, **values)} [{hint}]: ").strip().lower()
        if not answer:
            return default
        return answer in {"y", "yes", "t", "tak", "j", "ja", "д", "да"}
    def _select_language(self) -> None:
        print("\nPhoenix Engine Setup CLI")
        for index, (code, name) in enumerate(LANGUAGES.items(), 1):
            print(f"  {index}. {name} ({code})")
        choices = list(LANGUAGES)
        answer = input("Language / Język [English]: ").strip().lower()
        if answer.isdigit() and 1 <= int(answer) <= len(choices):
            self.language = choices[int(answer) - 1]
        elif answer in LANGUAGES:
            self.language = answer

    def _select_project(self) -> bool:
        value = self._ask("cli_project_prompt", str(self.core.project))
        project = Path(value).expanduser().resolve()
        if not project.is_dir() or not (project / "config.xml").is_file():
            print(f"[ERROR] {self.t('invalid_project')}")
            return False
        self.core.set_project(project)
        self.db_config = load_db_config(project)
        self.server_config = load_server_config(project)
        return True

    def _diagnostics(self) -> None:
        print(f"\n=== {self.t('diagnostics')} ===")
        labels = {"ok": "OK", "warning": "WARN", "error": "ERROR"}
        for item in self.core.diagnostics(self.server_config):
            print(f"[{labels[item.level]}] {self.t(item.key, **item.values)}")

    def _configure_server(self) -> None:
        current = self.server_config
        public = self._confirm("public_project", current.public)
        debug = self._confirm("debug_mode", current.debug)
        try:
            config = ServerConfig(
                public=public,
                debug=debug,
                host_name=self._ask("server_name", current.host_name),
                description=self._ask("server_description", current.description),
                max_slots=int(self._ask("max_slots", str(current.max_slots))),
                game_port=int(self._ask("game_port", str(current.game_port))),
                master_url=self._ask("master_url", current.master_url),
                world=self._ask("world_path", current.world),
                web_source=self._ask("web_source", current.web_source).replace("\\", "/"),
                addon_path=current.addon_path,
            )
        except ValueError:
            print(f"[ERROR] {self.t('invalid_server_numbers')}")
            return
        problem = validate_server_config(self.core.project, config)
        if problem:
            print(f"[ERROR] {self.t(problem)}")
            return
        print(self.t("cli_cef_preview", url=config.cef_url(self.core.project)))
        if not self._confirm("cli_save_confirm", False):
            return
        try:
            _backups, archive = save_server_config(self.core.project, config)
        except (OSError, PermissionError, ValueError) as error:
            key = str(error) or "config_structure_invalid"
            print(f"[ERROR] {self.t(key)}")
            return
        self.server_config = config
        print(f"[OK] {self.t('server_saved')}")
        if archive:
            print(f"[OK] {self.t('web_package_built', path=archive)}")

    def _configure_database(self) -> None:
        current = self.db_config
        generated_user = generate_password()
        generated_root = generate_password()
        try:
            config = DBConfig(
                host=self._ask("db_host", current.host),
                port=int(self._ask("db_port", str(current.port))),
                user=self._ask("db_user", current.user),
                password=self._ask("cli_db_password", current.password or generated_user, secret=True),
                database=self._ask("db_name", current.database),
                encoding=self._ask("db_encoding", current.encoding),
                root_password=self._ask("cli_root_password", current.root_password or generated_root, secret=True),
            )
        except ValueError:
            print(f"[ERROR] {self.t('invalid_port')}")
            return
        problem = validate_db_config(config)
        if problem:
            print(f"[ERROR] {self.t(problem)}")
            return
        if not self._confirm("cli_save_confirm", False):
            return
        try:
            save_db_config(self.core.project, config)
        except (OSError, PermissionError) as error:
            print(f"[ERROR] {error}")
            return
        self.db_config = config
        print(f"[OK] {self.t('config_saved')}")

    @staticmethod
    def _print_result(result: object) -> None:
        stdout = getattr(result, "stdout", "").strip()
        stderr = getattr(result, "stderr", "").strip()
        if stdout:
            print(stdout)
        if stderr:
            print(stderr)
    def _install_docker(self) -> None:
        try:
            commands = self.core.docker_install_commands()
        except PermissionError as error:
            print(f"[ERROR] {error}")
            return
        if not commands:
            print(f"[ERROR] {self.t('compose_unavailable')}")
            return
        print("\n".join(format_command(command) for command in commands))
        if self._confirm("docker_confirm", False, command="\n".join(format_command(c) for c in commands)):
            self._print_result(self.core.install_docker(commands))

    def _add_docker_group(self) -> None:
        try:
            command = self.core.docker_group_command()
        except PermissionError as error:
            print(f"[ERROR] {error}")
            return
        if command and self._confirm("group_confirm", False, command=format_command(command)):
            self._print_result(self.core.add_user_to_docker_group(command))

    def _build_web(self) -> None:
        try:
            archive = build_web_archive(self.core.project, self.server_config)
            print(f"[OK] {self.t('web_package_built', path=archive)}")
        except (OSError, PermissionError, ValueError) as error:
            print(f"[ERROR] {self.t(str(error) or 'web_archive_invalid')}")

    def _start_database(self) -> None:
        result = self.core.start_database()
        self._print_result(result)
        if result.ok:
            healthy = self.core.wait_for_health(self.db_config.port, 120)
            print(f"[{'OK' if healthy else 'ERROR'}] {self.t('db_healthy' if healthy else 'db_unhealthy')}")

    def _launch_server(self) -> None:
        ok, key = self.core.launch_server()
        print(f"[{'OK' if ok else 'ERROR'}] {self.t(key) if key in {'native_missing', 'server_started'} else key}")

    def _backup_database(self) -> bool:
        ok, path, error = self.core.create_backup(self.db_config)
        print(f"[{'OK' if ok else 'ERROR'}] " +
              (self.t("backup_done", path=path) if ok else self.t("operation_failed", error=error)))
        return ok

    def _reset_database(self) -> None:
        if self._confirm("backup_question", True) and not self._backup_database():
            return
        typed = input(self.t("type_db_name", name=self.db_config.database) + " ").strip()
        if typed != self.db_config.database:
            print(self.t("name_not_match"))
            return
        if not self._confirm("reset_confirm", False):
            return

        preflight = self.core.preflight_database_reset(self.db_config.port)
        if not preflight.safe:
            if preflight.error:
                print(f"[ERROR] {self.t('operation_failed', error=preflight.error)}")
                return
            conflict = preflight.conflict
            if conflict is None:
                print(f"[ERROR] {self.t('reset_preflight_failed')}")
                return
            if conflict.kind != "docker":
                print(f"[ERROR] {self.t('reset_host_conflict', port=conflict.port)}")
                return
            if not self._confirm(
                "reset_foreign_container",
                False,
                port=conflict.port,
                owner=conflict.display_name,
                container=conflict.container_id[:12],
            ):
                print(self.t("reset_cancelled"))
                return
            stopped, error = self.core.stop_conflicting_container(conflict)
            if not stopped:
                print(f"[ERROR] {self.t('reset_stop_failed', error=error)}")
                return

        ok, error = self.core.reset_database(self.db_config.port)
        print(f"[{'OK' if ok else 'ERROR'}] " +
              (self.t("reset_done") if ok else self.t("operation_failed", error=error)))
    def _menu(self) -> dict[str, tuple[str, Callable[[], object]]]:
        return {
            "1": ("diagnostics", self._diagnostics),
            "2": ("server", self._configure_server),
            "3": ("database", self._configure_database),
            "4": ("build_web", self._build_web),
            "5": ("install_docker", self._install_docker),
            "6": ("docker_group", self._add_docker_group),
            "7": ("start_db", self._start_database),
            "8": ("stop_db", lambda: self._print_result(self.core.stop_database())),
            "9": ("db_status", lambda: self._print_result(self.core.database_status())),
            "10": ("db_logs", lambda: self._print_result(self.core.database_logs())),
            "11": ("health", lambda: print(self.t("db_healthy" if self.core.wait_for_health(
                self.db_config.port, 30) else "db_unhealthy"))),
            "12": ("cli_backup", self._backup_database),
            "13": ("reset_db", self._reset_database),
            "14": ("start_server", self._launch_server),
        }

    def run(self) -> int:
        if platform.system() != "Linux":
            print("PhoenixEngineSetupCLI is available only on Linux.")
            return 2
        self._select_language()
        if not self._select_project():
            return 1
        print(f"\nPhoenix Engine — {self.core.project}")
        while True:
            menu = self._menu()
            print(f"\n=== {self.t('cli_main_menu')} ===")
            for number, (key, _action) in menu.items():
                print(f" {number:>2}. {self.t(key)}")
            print(f"  0. {self.t('close')}")
            choice = input("> ").strip()
            if choice == "0":
                return 0
            selected = menu.get(choice)
            if not selected:
                print(self.t("cli_invalid_choice"))
                continue
            try:
                selected[1]()
            except KeyboardInterrupt:
                print(f"\n{self.t('cli_cancelled')}")
            except EOFError:
                return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Phoenix Engine Linux console setup")
    parser.add_argument("--project", type=Path, help="Phoenix Engine project root")
    parser.add_argument("--language", choices=tuple(LANGUAGES), help="Interface language")
    args = parser.parse_args(argv)
    try:
        return PhoenixCLI(args.project, args.language).run()
    except (KeyboardInterrupt, EOFError):
        print()
        return 130
