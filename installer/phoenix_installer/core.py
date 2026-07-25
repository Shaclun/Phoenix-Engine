"""System, Docker, configuration, and Phoenix Engine operations."""

from __future__ import annotations

import html
import json
import os
import platform
import re
import secrets
import shlex
import shutil
import socket
import string
import subprocess
import sys
import tempfile
import time
import webbrowser
import zipfile
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Callable, ClassVar, Sequence

DOCKER_DESKTOP_URL = "https://www.docker.com/products/docker-desktop/"
REQUIRED_ITEMS = (
    "docker-compose.yml", "config.xml", "data.xml", "mds.xml", "faceani.xml",
    "migrations", "gamemodes/phoenix", "database/modules", "lib",
)


@dataclass(slots=True)
class CommandResult:
    command: list[str]
    returncode: int
    stdout: str = ""
    stderr: str = ""

    @property
    def ok(self) -> bool:
        return self.returncode == 0


@dataclass(slots=True, frozen=True)
class DockerPortOwner:
    """A process reserving the database host port during reset preflight."""

    kind: str
    port: int
    container_id: str = ""
    container_name: str = ""
    compose_project: str = ""
    compose_service: str = ""

    @property
    def display_name(self) -> str:
        if self.compose_project and self.compose_service:
            return f"{self.compose_project}/{self.compose_service}"
        return self.container_name or self.container_id[:12] or "host service"


@dataclass(slots=True)
class DatabaseResetPreflight:
    """Result that must be safe before a destructive Compose volume reset."""

    safe: bool
    conflict: DockerPortOwner | None = None
    error: str = ""


@dataclass(slots=True)
class DiagnosticItem:
    level: str
    key: str
    values: dict[str, object] = field(default_factory=dict)


@dataclass(slots=True)
class DBConfig:
    host: str = "127.0.0.1"
    port: int = 3306
    user: str = "phoenix"
    password: str = ""
    database: str = "phoenix"
    encoding: str = "utf8mb4"
    root_password: str = ""

    def application_env(self) -> str:
        return (
            f"DATABASE_HOST={self.host}\nDATABASE_PORT={self.port}\n"
            f"DATABASE_USERNAME={self.user}\nDATABASE_PASSWORD={self.password}\n"
            f"DATABASE_DBNAME={self.database}\nDATABASE_ENCODING={self.encoding}\n"
        )

    def mysql_env(self) -> str:
        return (
            f"MYSQL_USER={self.user}\nMYSQL_PASSWORD={self.password}\n"
            f"MYSQL_ROOT_PASSWORD={self.root_password}\nMYSQL_DATABASE={self.database}\n"
        )


@dataclass(slots=True)
class ServerConfig:
    """Editable G2O and CEF deployment settings."""

    description_max_length: ClassVar[int] = 400

    public: bool = False
    debug: bool = True
    host_name: str = "Phoenix Engine"
    description: str = "<center><b>Phoenix Engine</b></center>"
    max_slots: int = 32
    game_port: int = 28970
    master_url: str = "https://api.gothic-online.com"
    world: str = r"NEWWORLD\NEWWORLD.ZEN"
    web_source: str = "gamemodes/phoenix/web"
    addon_path: str = "addons/PhoenixWeb.zip"

    @property
    def packed_cef(self) -> bool:
        """Public projects distribute their web UI through a G2O ZIP resource."""
        return self.public

    def cef_url(self, project: Path) -> str:
        if self.packed_cef:
            return "cef://index.html"
        return (project / self.web_source / "index.html").resolve().as_uri()


def _tag_attributes(text: str, tag: str) -> dict[str, str]:
    match = re.search(rf"<{tag}\b([^>]*)/?>", text, flags=re.IGNORECASE)
    if not match:
        return {}
    values: dict[str, str] = {}
    for key, double_quoted, single_quoted, bare in re.findall(
            r"([\w:-]+)\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([^\s/>]+))", match.group(1)):
        values[key] = html.unescape(double_quoted or single_quoted or bare)
    return values


def _bool_value(value: str, default: bool) -> bool:
    normalized = value.strip().lower()
    if normalized in {"true", "1", "yes"}:
        return True
    if normalized in {"false", "0", "no"}:
        return False
    return default


def _int_value(value: str, default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def load_server_config(project: Path) -> ServerConfig:
    """Read G2O's XML-like config while tolerating its unquoted attributes."""
    path = project / "config.xml"
    try:
        text = path.read_text(encoding="utf-8-sig")
    except OSError:
        return ServerConfig()
    attributes = _tag_attributes(text, "config")
    master = _tag_attributes(text, "master")
    world = _tag_attributes(text, "world")
    debug_match = re.search(r"<debug\b[^>]*>\s*(true|false|1|0)\s*</debug>", text, flags=re.IGNORECASE)
    description_match = re.search(r"<description\b[^>]*>\s*<!\[CDATA\[(.*?)\]\]>\s*</description>", text,
                                  flags=re.IGNORECASE | re.DOTALL)
    return ServerConfig(
        public=_bool_value(attributes.get("public", "false"), False),
        debug=_bool_value(debug_match.group(1), True) if debug_match else True,
        host_name=attributes.get("host_name", "Phoenix Engine"),
        description=description_match.group(1).strip() if description_match else "",
        max_slots=_int_value(attributes.get("max_slots", "32"), 32),
        game_port=_int_value(attributes.get("port", "28970"), 28970),
        master_url=master.get("url", "https://api.gothic-online.com"),
        world=world.get("name", r"NEWWORLD\NEWWORLD.ZEN"),
    )


def _read_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for raw_line in path.read_text(encoding="utf-8-sig").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip()
    except OSError:
        pass
    return values


def load_db_config(project: Path) -> DBConfig:
    """Load existing paired configuration without exposing secrets."""
    app = _read_env(project / ".env")
    mysql = _read_env(project / "config" / "mysql.env")
    try:
        port = int(app.get("DATABASE_PORT", "3306"))
    except ValueError:
        port = 3306
    return DBConfig(
        host=app.get("DATABASE_HOST", "127.0.0.1"),
        port=port,
        user=app.get("DATABASE_USERNAME", mysql.get("MYSQL_USER", "phoenix")),
        password=app.get("DATABASE_PASSWORD", mysql.get("MYSQL_PASSWORD", generate_password())),
        database=app.get("DATABASE_DBNAME", mysql.get("MYSQL_DATABASE", "phoenix")),
        encoding=app.get("DATABASE_ENCODING", "utf8mb4"),
        root_password=mysql.get("MYSQL_ROOT_PASSWORD", generate_password()),
    )


def resource_path(relative: str) -> Path:
    """Resolve resources both in source trees and PyInstaller bundles."""
    base = Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parents[1]))
    return base / relative


def _looks_like_root(path: Path) -> bool:
    return (path / "docker-compose.yml").is_file() and (path / "config.xml").is_file()


def detect_project_root() -> Path:
    """Find a project root near the executable, script, or current directory."""
    starts = [Path.cwd(), Path(sys.executable).resolve().parent, Path(__file__).resolve().parents[2]]
    seen: set[Path] = set()
    for start in starts:
        for candidate in (start, *list(start.parents)[:5]):
            if candidate not in seen and _looks_like_root(candidate):
                return candidate
            seen.add(candidate)
    return Path.cwd()


def generate_password(length: int = 24) -> str:
    """Generate a strong password containing every major character class."""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*_-+="
    required = [secrets.choice(string.ascii_lowercase), secrets.choice(string.ascii_uppercase),
                secrets.choice(string.digits), secrets.choice("!@#$%^&*_-+=")]
    chars = required + [secrets.choice(alphabet) for _ in range(max(12, length) - len(required))]
    secrets.SystemRandom().shuffle(chars)
    return "".join(chars)


def validate_db_config(config: DBConfig) -> str | None:
    if not 1 <= config.port <= 65535:
        return "invalid_port"
    if not re.fullmatch(r"[A-Za-z0-9_-]+", config.user) or not re.fullmatch(r"[A-Za-z0-9_-]+", config.database):
        return "invalid_name"
    if not config.password or not config.root_password or "\n" in config.password or "\n" in config.root_password:
        return "password_mismatch"
    if not config.host.strip() or "\n" in config.host or not re.fullmatch(r"[A-Za-z0-9._:-]+", config.host):
        return "invalid_name"
    if not re.fullmatch(r"[A-Za-z0-9_-]+", config.encoding):
        return "invalid_name"
    return None


def _safe_project_path(project: Path, relative: str) -> Path | None:
    if not relative.strip() or Path(relative).is_absolute():
        return None
    root = project.resolve()
    candidate = (root / relative).resolve()
    try:
        candidate.relative_to(root)
    except ValueError:
        return None
    return candidate


def validate_server_config(project: Path, config: ServerConfig) -> str | None:
    if not config.host_name.strip() or len(config.host_name) > 32 or any(ord(char) < 32 for char in config.host_name):
        return "invalid_server_name"
    if not 1 <= config.max_slots <= 1000:
        return "invalid_slots"
    if not 1 <= config.game_port <= 65535:
        return "invalid_game_port"
    if not re.fullmatch(r"https?://[^\s<>]+", config.master_url):
        return "invalid_master_url"
    if not config.world.strip() or "\n" in config.world or "\r" in config.world:
        return "invalid_world"
    if "]]>" in config.description or len(config.description) > config.description_max_length:
        return "invalid_description"
    source = _safe_project_path(project, config.web_source)
    if source is None or not (source / "index.html").is_file():
        return "invalid_web_source"
    addon = _safe_project_path(project, config.addon_path)
    if addon is None or addon.suffix.lower() != ".zip":
        return "invalid_addon_path"
    return None


def _atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        if os.name != "nt":
            os.chmod(temporary, 0o600)
        os.replace(temporary, path)
        if os.name != "nt":
            path.chmod(0o600)
    except Exception:
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


def save_db_config(project: Path, config: DBConfig) -> list[Path]:
    """Back up and atomically write the paired application and MySQL env files."""
    targets = [(project / ".env", config.application_env()),
               (project / "config" / "mysql.env", config.mysql_env())]
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backups: list[Path] = []
    for path, content in targets:
        current = None
        try:
            current = path.read_text(encoding="utf-8")
        except OSError:
            pass
        if current == content:
            continue
        if path.exists():
            backup = path.with_name(f"{path.name}.{stamp}.bak")
            shutil.copy2(path, backup)
            backups.append(backup)
        _atomic_write(path, content)
    return backups


def _xml_attribute(value: str) -> str:
    return (value.replace("&", "&amp;").replace('"', "&quot;")
            .replace("<", "&lt;").replace(">", "&gt;"))


def _replace_required(text: str, pattern: str,
                      replacement: str | Callable[[re.Match[str]], str], flags: int = 0) -> str:
    replacer = replacement if callable(replacement) else (lambda _match: replacement)
    updated, count = re.subn(pattern, replacer, text, count=1, flags=flags)
    if count != 1:
        raise ValueError("config_structure_invalid")
    return updated


def _set_downloader_compression(text: str, enabled: bool) -> str:
    """Set G2O transport compression without replacing other downloader settings."""
    value = "true" if enabled else "false"
    downloader = re.search(r"<downloader\b[^>]*>.*?</downloader>", text,
                           flags=re.IGNORECASE | re.DOTALL)
    if downloader:
        block = downloader.group(0)
        if re.search(r"<compress\b[^>]*>.*?</compress>", block, flags=re.IGNORECASE | re.DOTALL):
            updated_block = re.sub(r"<compress\b([^>]*)>.*?</compress>",
                                   lambda match: f"<compress{match.group(1)}>{value}</compress>",
                                   block, count=1, flags=re.IGNORECASE | re.DOTALL)
        else:
            updated_block = block.replace("</downloader>", f"\n\t\t<compress>{value}</compress>\n\t</downloader>", 1)
        return text[:downloader.start()] + updated_block + text[downloader.end():]
    block = f"\t<downloader>\n\t\t<compress>{value}</compress>\n\t</downloader>\n\n"
    marker = "\t<!-- Ids -->"
    return text.replace(marker, block + marker, 1) if marker in text else text.replace("</server>", block + "</server>", 1)


def build_web_archive(project: Path, config: ServerConfig) -> Path:
    """Build a verified, atomic CEF addon with the VFS path required by G2O."""
    problem = validate_server_config(project, config)
    if problem:
        raise ValueError(problem)
    source = _safe_project_path(project, config.web_source)
    destination = _safe_project_path(project, config.addon_path)
    if source is None or destination is None:
        raise ValueError("invalid_web_source")
    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{destination.stem}.", suffix=".zip", dir=destination.parent)
    os.close(fd)
    temporary = Path(temporary_name)
    try:
        files = sorted(path for path in source.rglob("*") if path.is_file())
        if not files:
            raise ValueError("invalid_web_source")
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for path in files:
                if path.is_symlink():
                    continue
                resolved = path.resolve()
                try:
                    relative = resolved.relative_to(source.resolve())
                except ValueError as error:
                    raise ValueError("invalid_web_source") from error
                archive_name = "/".join(part.upper() for part in relative.parts)
                archive.write(resolved, f"_WORK/DATA/WEB/{archive_name}")
        with zipfile.ZipFile(temporary, "r") as archive:
            if "_WORK/DATA/WEB/INDEX.HTML" not in archive.namelist() or archive.testzip() is not None:
                raise ValueError("web_archive_invalid")
        if destination.exists():
            stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            shutil.copy2(destination, destination.with_name(f"{destination.name}.{stamp}.bak"))
        os.replace(temporary, destination)
        # G2O regenerates these files on startup. Remove transport artifacts
        # produced by the previous nested-ZIP configuration.
        stale_transport = project / "cache" / "addons" / f"{destination.name.lower()}.zip"
        stale_metadata = project / "cache" / "internal" / "addons.xml"
        for stale in (stale_transport, stale_metadata):
            try:
                stale.unlink(missing_ok=True)
            except OSError:
                pass
        return destination
    except Exception:
        try:
            temporary.unlink()
        except OSError:
            pass
        raise


def save_server_config(project: Path, config: ServerConfig) -> tuple[list[Path], Path | None]:
    """Save G2O settings, CEF URL and optional packed addon with backups."""
    problem = validate_server_config(project, config)
    if problem:
        raise ValueError(problem)
    config_path = project / "config.xml"
    manager_path = project / "gamemodes" / "phoenix" / "modules" / "web" / "client" / "manager.nut"
    try:
        config_text = config_path.read_text(encoding="utf-8-sig")
        manager_text = manager_path.read_text(encoding="utf-8-sig")
    except OSError as error:
        raise ValueError("config_structure_invalid") from error

    public_value = "true" if config.public else "false"
    debug_value = "true" if config.debug else "false"
    config_line = (f'<config public={public_value} host_name="{_xml_attribute(config.host_name.strip())}" '
                   f'max_slots={config.max_slots} port={config.game_port} />')
    updated = _replace_required(config_text, r"<debug\b([^>]*)>.*?</debug>",
                                lambda match: f"<debug{match.group(1)}>{debug_value}</debug>",
                                re.IGNORECASE | re.DOTALL)
    updated = _replace_required(updated, r"<config\b[^>]*/>", config_line, re.IGNORECASE)
    updated = _replace_required(updated, r"<master\b[^>]*/>",
                                f'<master url="{_xml_attribute(config.master_url)}" />', re.IGNORECASE)
    updated = _replace_required(updated, r"<world\b[^>]*/>",
                                f'<world name="{_xml_attribute(config.world)}" />', re.IGNORECASE)
    updated = _replace_required(updated, r"<description\b[^>]*>.*?</description>",
                                f"<description>\n        <![CDATA[{config.description.strip()}]]>\n    </description>",
                                re.IGNORECASE | re.DOTALL)

    # G2O accepts client archives as <resource zip="..." />. Clean up both
    # the supported entry and the legacy invalid <addon> entry produced by
    # older installer builds before applying the selected visibility mode.
    archive_name = re.escape(Path(config.addon_path).name)
    updated = re.sub(rf"\s*<(?:addon|resource)\b[^>]*{archive_name}[^>]*/>", "", updated,
                     flags=re.IGNORECASE)
    archive_path: Path | None = None
    if config.packed_cef:
        archive_path = build_web_archive(project, config)
        # The archive is already a valid G2O ZIP resource. Disable the default
        # transport recompression so clients receive phoenixweb.zip, not a
        # nested phoenixweb.zip.zip package.
        updated = _set_downloader_compression(updated, False)
        addon_source = _xml_attribute(config.addon_path.replace("\\", "/"))
        resource_line = f'\t<resource zip="{addon_source}" />\n\n'
        marker = "\t<!-- Ids -->"
        if marker in updated:
            updated = updated.replace(marker, resource_line + marker, 1)
        else:
            updated = updated.replace("</server>", resource_line + "</server>", 1)

    cef_url = config.cef_url(project)
    manager_updated = _replace_required(manager_text, r'(?m)^(\s*url\s*=\s*)"[^"]*"',
                                        lambda match: f'{match.group(1)}"{cef_url}"')
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backups: list[Path] = []
    for path, old, new in ((config_path, config_text, updated), (manager_path, manager_text, manager_updated)):
        if old == new:
            continue
        backup = path.with_name(f"{path.name}.{stamp}.bak")
        shutil.copy2(path, backup)
        backups.append(backup)
        _atomic_write(path, new)
    return backups, archive_path


def run_command(command: Sequence[str], cwd: Path | None = None, timeout: int = 60,
                env: dict[str, str] | None = None) -> CommandResult:
    """Run an argument-vector command without a shell and normalize common failures."""
    argv = [str(part) for part in command]
    try:
        completed = subprocess.run(argv, cwd=cwd, capture_output=True, text=True,
                                   timeout=timeout, check=False, env=env)
        return CommandResult(argv, completed.returncode, completed.stdout, completed.stderr)
    except subprocess.TimeoutExpired as error:
        stdout = error.stdout.decode(errors="replace") if isinstance(error.stdout, bytes) else (error.stdout or "")
        stderr = error.stderr.decode(errors="replace") if isinstance(error.stderr, bytes) else (error.stderr or "")
        return CommandResult(argv, 124, stdout, stderr or f"Timeout after {timeout}s")
    except FileNotFoundError as error:
        return CommandResult(argv, 127, "", str(error))
    except PermissionError as error:
        return CommandResult(argv, 126, "", str(error))
    except OSError as error:
        return CommandResult(argv, 1, "", str(error))


def port_is_open(port: int, host: str = "127.0.0.1", timeout: float = 0.5) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


def _find_executable(name: str) -> str | None:
    """Find CLI tools even when a GUI process has a stale or reduced PATH."""
    discovered = shutil.which(name)
    if discovered:
        return discovered
    if os.name != "nt":
        return None
    executable = name if name.lower().endswith(".exe") else f"{name}.exe"
    candidates = [
        Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Docker" / "Docker" / "resources" / "bin" / executable,
        Path(os.environ.get("LOCALAPPDATA", "")) / "Docker" / "resources" / "bin" / executable,
        Path(os.environ.get("USERPROFILE", "")) / ".docker" / "bin" / executable,
    ]
    return str(next((path for path in candidates if path.is_file()), "")) or None


def _docker_port_owners(port: int) -> tuple[list[DockerPortOwner], CommandResult | None]:
    """Return Docker containers publishing a port, preserving inspection errors."""
    docker = _find_executable("docker")
    if not docker:
        return [], CommandResult([], 127, "", "Docker CLI was not found")
    containers = run_command([docker, "ps", "-q", "--filter", f"publish={port}"], timeout=15)
    if not containers.ok:
        return [], containers
    owners: list[DockerPortOwner] = []
    for container_id in containers.stdout.splitlines():
        container_id = container_id.strip()
        if not container_id:
            continue
        inspected = run_command([docker, "inspect", container_id], timeout=15)
        if not inspected.ok:
            return [], inspected
        try:
            payload = json.loads(inspected.stdout)
            container = payload[0]
            labels = container.get("Config", {}).get("Labels") or {}
            container_name = str(container.get("Name", "")).lstrip("/")
        except (IndexError, KeyError, TypeError, json.JSONDecodeError):
            return [], CommandResult(
                inspected.command, 1, "", f"Invalid Docker inspection result for container {container_id}"
            )
        owners.append(DockerPortOwner(
            kind="docker",
            port=port,
            container_id=container_id,
            container_name=container_name,
            compose_project=str(labels.get("com.docker.compose.project", "")),
            compose_service=str(labels.get("com.docker.compose.service", "")),
        ))
    return owners, None


def docker_service_on_port(port: int) -> str | None:
    """Identify a running Docker/Compose service publishing a host port."""
    owners, error = _docker_port_owners(port)
    return owners[0].display_name if owners and error is None else None


def _command_failure(stage: str, result: CommandResult) -> str:
    """Keep the command, exit code, stdout, and stderr for actionable failures."""
    lines = [f"{stage} failed (exit code {result.returncode})."]
    if result.command:
        lines.append(f"Command: {format_command(result.command)}")
    if result.stdout.strip():
        lines.extend(("stdout:", result.stdout.rstrip()))
    if result.stderr.strip():
        lines.extend(("stderr:", result.stderr.rstrip()))
    return "\n".join(lines)


class PhoenixCore:
    """Stateful facade for diagnostics and lifecycle operations."""

    def __init__(self, project: Path | None = None) -> None:
        self.project = (project or detect_project_root()).resolve()
        self.system = platform.system()
        self.architecture = platform.machine() or "unknown"
        self.compose_base: list[str] | None = None

    def set_project(self, project: Path) -> None:
        self.project = project.resolve()
        self.compose_base = None

    def detect_compose(self) -> list[str] | None:
        docker = _find_executable("docker")
        if docker:
            result = run_command([docker, "compose", "version"], timeout=15)
            if result.ok:
                self.compose_base = [docker, "compose"]
                return self.compose_base
        legacy = _find_executable("docker-compose")
        if legacy:
            result = run_command([legacy, "version"], timeout=15)
            if result.ok:
                self.compose_base = [legacy]
                return self.compose_base
        self.compose_base = None
        return None

    def _compose(self, arguments: Sequence[str], timeout: int = 120) -> CommandResult:
        base = self.compose_base or self.detect_compose()
        if not base:
            return CommandResult([], 127, "", "Docker Compose unavailable")
        command = [*base, *arguments]
        result = run_command(command, self.project, timeout)
        denied = result.returncode in (126, 13) or "permission denied" in result.stderr.lower()
        if denied and self.system == "Linux" and shutil.which("pkexec"):
            result = run_command(["pkexec", *command], self.project, timeout)
        return result

    def diagnostics(self, server_config: ServerConfig | None = None) -> list[DiagnosticItem]:
        server_config = server_config or load_server_config(self.project)
        items = [DiagnosticItem("ok", "system_info", {"system": self.system, "arch": self.architecture})]
        for relative in REQUIRED_ITEMS:
            if (self.project / relative).exists():
                items.append(DiagnosticItem("ok", "status_ok", {"item": relative}))
            else:
                items.append(DiagnosticItem("error", "blocking_missing", {"item": relative}))
        runtime = "G2O_Server.x64.exe" if self.system == "Windows" else "G2O_Server.x64"
        runtime_path = self.project / runtime
        if self.system == "Windows" and not runtime_path.is_file():
            items.append(DiagnosticItem("error", "blocking_missing", {"item": runtime}))
        elif self.system == "Linux" and not (runtime_path.is_file() and os.access(runtime_path, os.X_OK)):
            items.append(DiagnosticItem("warning", "warning_missing", {"item": runtime}))
        elif runtime_path.exists():
            items.append(DiagnosticItem("ok", "status_ok", {"item": runtime}))

        web_index = self.project / server_config.web_source / "index.html"
        items.append(DiagnosticItem("ok" if web_index.is_file() else "error",
                                    "cef_source_ok" if web_index.is_file() else "cef_source_missing",
                                    {"path": str(web_index)}))
        if server_config.packed_cef:
            archive = self.project / server_config.addon_path
            items.append(DiagnosticItem("ok" if archive.is_file() else "error",
                                        "cef_package_ok" if archive.is_file() else "cef_package_missing",
                                        {"path": str(archive)}))
        items.append(DiagnosticItem("ok", "cef_mode_info", {"url": server_config.cef_url(self.project)}))

        docker = _find_executable("docker")
        docker_available = bool(docker)
        items.append(DiagnosticItem("ok" if docker_available else "warning",
                                    "docker_found" if docker_available else "docker_missing"))
        daemon = bool(docker) and run_command([docker, "info"], timeout=15).ok
        items.append(DiagnosticItem("ok" if daemon else "warning", "daemon_ok" if daemon else "daemon_bad"))
        compose = self.detect_compose()
        items.append(DiagnosticItem("ok" if compose else "warning",
                                    "compose_found" if compose else "compose_missing",
                                    {"compose": " ".join(compose or [])}))
        running_services: set[str] = set()
        configured_services: set[str] = set()
        if compose:
            configured_result = self._compose(["ps", "--services"], timeout=20)
            running_result = self._compose(["ps", "--services", "--status", "running"], timeout=20)
            if configured_result.ok:
                configured_services = {line.strip() for line in configured_result.stdout.splitlines() if line.strip()}
            if running_result.ok:
                running_services = {line.strip() for line in running_result.stdout.splitlines() if line.strip()}
            if configured_services:
                items.append(DiagnosticItem("ok", "existing_installation", {
                    "services": ", ".join(sorted(configured_services)),
                }))

        db_port = load_db_config(self.project).port
        for port, service in ((db_port, "mysql-server"), (server_config.game_port, "game-server")):
            busy = port_is_open(port)
            docker_owner = docker_service_on_port(port) if busy and docker_available else None
            if not busy:
                items.append(DiagnosticItem("ok", "port_free", {"port": port}))
            elif service in running_services:
                items.append(DiagnosticItem("ok", "port_project_service", {"port": port, "service": service}))
            elif docker_owner:
                items.append(DiagnosticItem("ok", "port_docker_service", {"port": port, "service": docker_owner}))
                if not configured_services:
                    items.append(DiagnosticItem("ok", "existing_installation", {"services": docker_owner}))
            else:
                items.append(DiagnosticItem("warning", "port_in_use_continue", {"port": port}))
        state = "unavailable"
        if compose:
            status = self._compose(["ps", "mysql-server"], timeout=20)
            state = (status.stdout or status.stderr).strip() or "unavailable"
        items.append(DiagnosticItem("ok" if "running" in state.lower() or "healthy" in state.lower() else "warning",
                                    "mysql_state", {"state": state}))
        return items

    def ensure_docker_ready(self, timeout: int = 90) -> CommandResult:
        """Resolve Docker from GUI-safe paths and wait for Docker Desktop when needed."""
        docker = _find_executable("docker")
        if not docker:
            return CommandResult([], 127, "", "Docker CLI was not found")
        result = run_command([docker, "info"], self.project, timeout=20)
        if result.ok:
            return result
        if self.system != "Windows" or not self.start_docker_desktop():
            return result
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            time.sleep(3)
            result = run_command([docker, "info"], self.project, timeout=20)
            if result.ok:
                self.compose_base = None
                return result
        return CommandResult(result.command, 124, result.stdout,
                             result.stderr or "Docker Desktop did not become ready before timeout")

    def start_database(self) -> CommandResult:
        ready = self.ensure_docker_ready()
        return self._compose(["up", "-d"], timeout=300) if ready.ok else ready

    def stop_database(self) -> CommandResult:
        ready = self.ensure_docker_ready()
        return self._compose(["down"], timeout=180) if ready.ok else ready

    def database_status(self) -> CommandResult:
        ready = self.ensure_docker_ready()
        return self._compose(["ps", "--all"], timeout=30) if ready.ok else ready

    def database_logs(self) -> CommandResult:
        ready = self.ensure_docker_ready()
        return self._compose(["logs", "--tail", "120", "mysql-server"], timeout=30) if ready.ok else ready

    def wait_for_health(self, port: int = 3306, timeout: int = 120) -> bool:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            ps_result = self._compose(["ps", "mysql-server"], timeout=20)
            container_result = self._compose(["ps", "-q", "mysql-server"], timeout=20)
            container_id = container_result.stdout.strip().splitlines()
            healthy = False
            if container_result.ok and container_id:
                docker = _find_executable("docker")
                inspect = run_command(
                    [docker or "docker", "inspect", "--format", "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}", container_id[0]],
                    self.project, 20,
                )
                if not inspect.ok and self.system == "Linux" and shutil.which("pkexec"):
                    inspect = run_command(["pkexec", "docker", "inspect", "--format",
                                           "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}",
                                           container_id[0]], self.project, 20)
                healthy = inspect.ok and inspect.stdout.strip().lower() == "healthy"
            if ps_result.ok and healthy and port_is_open(port, timeout=1.0):
                return True
            time.sleep(3)
        return False

    def create_backup(self, config: DBConfig) -> tuple[bool, Path | None, str]:
        backup_dir = self.project / "backups"
        backup_dir.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        path = backup_dir / f"{config.database}-{stamp}.sql"
        result = self._compose([
            "exec", "-T", "-e", f"MYSQL_PWD={config.root_password}",
            "mysql-server", "mysqldump", "-uroot", "--single-transaction",
            "--routines", "--events", config.database,
        ], timeout=600)
        if not result.ok:
            return False, None, result.stderr.strip()
        try:
            _atomic_write(path, result.stdout)
            return True, path, ""
        except OSError as error:
            return False, None, str(error)

    def preflight_database_reset(self, port: int = 3306) -> DatabaseResetPreflight:
        """Block destructive reset until the configured host port is safely available."""
        ready = self.ensure_docker_ready()
        if not ready.ok:
            return DatabaseResetPreflight(False, error=_command_failure("Docker readiness check", ready))

        own_result = self._compose(["ps", "--all", "-q", "mysql-server"], timeout=30)
        if not own_result.ok:
            return DatabaseResetPreflight(False, error=_command_failure("Compose service inspection", own_result))
        own_ids = {value.strip() for value in own_result.stdout.splitlines() if value.strip()}

        owners, inspection_error = _docker_port_owners(port)
        if inspection_error is not None:
            return DatabaseResetPreflight(
                False, error=_command_failure("Docker port inspection", inspection_error)
            )

        own_port_is_published = False
        for owner in owners:
            is_own = any(
                owner.container_id == own_id
                or owner.container_id.startswith(own_id)
                or own_id.startswith(owner.container_id)
                for own_id in own_ids
            )
            if is_own:
                own_port_is_published = True
                continue
            return DatabaseResetPreflight(False, conflict=owner)

        if own_port_is_published:
            return DatabaseResetPreflight(True)
        if port_is_open(port):
            return DatabaseResetPreflight(
                False, conflict=DockerPortOwner(kind="host", port=port)
            )
        return DatabaseResetPreflight(True)

    def stop_conflicting_container(self, expected: DockerPortOwner) -> tuple[bool, str]:
        """Stop only the explicitly confirmed container if it still owns the port."""
        if expected.kind != "docker" or not expected.container_id:
            return False, "The port conflict is not a stoppable Docker container."
        current = self.preflight_database_reset(expected.port)
        if current.safe:
            return True, ""
        if current.error:
            return False, current.error
        conflict = current.conflict
        if conflict is None or conflict.kind != "docker":
            return False, "The port owner changed; no container was stopped."
        same_container = (
            conflict.container_id == expected.container_id
            or conflict.container_id.startswith(expected.container_id)
            or expected.container_id.startswith(conflict.container_id)
        )
        if not same_container:
            return False, "The port owner changed; no container was stopped."

        docker = _find_executable("docker")
        if not docker:
            return False, "Docker CLI was not found."
        result = run_command([docker, "stop", expected.container_id], self.project, timeout=120)
        denied = result.returncode in (126, 13) or "permission denied" in result.stderr.lower()
        if denied and self.system == "Linux" and shutil.which("pkexec"):
            result = run_command(["pkexec", docker, "stop", expected.container_id], self.project, timeout=120)
        if not result.ok:
            return False, _command_failure("Stopping conflicting Docker container", result)

        follow_up = self.preflight_database_reset(expected.port)
        if follow_up.safe:
            return True, ""
        if follow_up.error:
            return False, follow_up.error
        return False, "The database port is still occupied after stopping the confirmed container."

    def reset_database(self, port: int = 3306) -> tuple[bool, str]:
        preflight = self.preflight_database_reset(port)
        if not preflight.safe:
            if preflight.error:
                return False, preflight.error
            conflict = preflight.conflict
            if conflict and conflict.kind == "docker":
                return False, (
                    f"Reset blocked before volume removal: port {port} is owned by "
                    f"Docker container {conflict.display_name} ({conflict.container_id[:12]})."
                )
            return False, f"Reset blocked before volume removal: port {port} is used by a host service."

        down = self._compose(["down", "-v"], timeout=300)
        if not down.ok:
            return False, _command_failure("docker compose down -v", down)
        up = self._compose(["up", "-d"], timeout=300)
        if not up.ok:
            return False, _command_failure("docker compose up -d", up)
        if self.wait_for_health(port, 180):
            return True, ""

        status = self._compose(["ps", "--all"], timeout=30)
        if not status.ok:
            return False, "Database health timeout.\n" + _command_failure("Compose status", status)
        details = status.stdout.strip() or status.stderr.strip() or "No Compose status output."
        return False, f"Database health timeout after 180 seconds.\n{details}"

    def launch_server(self) -> tuple[bool, str]:
        executable = self.project / ("G2O_Server.x64.exe" if self.system == "Windows" else "G2O_Server.x64")
        if not executable.is_file() or (self.system != "Windows" and not os.access(executable, os.X_OK)):
            return False, "native_missing"
        try:
            if self.system == "Windows":
                subprocess.Popen([str(executable)], cwd=self.project,
                                 creationflags=subprocess.CREATE_NEW_CONSOLE)
            else:
                subprocess.Popen([str(executable)], cwd=self.project, start_new_session=True)
            return True, "server_started"
        except (FileNotFoundError, PermissionError, OSError) as error:
            return False, str(error)

    def _linux_id(self) -> str:
        try:
            values: dict[str, str] = {}
            for line in Path("/etc/os-release").read_text(encoding="utf-8").splitlines():
                if "=" in line:
                    key, value = line.split("=", 1)
                    values[key] = value.strip().strip('"')
            return values.get("ID", "").lower()
        except OSError:
            return ""

    def privilege_prefix(self) -> list[str]:
        if shutil.which("pkexec"):
            return ["pkexec"]
        if shutil.which("sudo") and sys.stdin is not None and sys.stdin.isatty():
            return ["sudo"]
        raise PermissionError("pkexec unavailable; sudo requires an interactive terminal")

    def docker_install_commands(self) -> list[list[str]]:
        if self.system == "Windows":
            if shutil.which("winget"):
                return [["winget", "install", "-e", "--id", "Docker.DockerDesktop",
                         "--accept-package-agreements", "--accept-source-agreements"]]
            return []
        prefix = self.privilege_prefix()
        distro = self._linux_id()
        if shutil.which("apt-get") or distro in {"debian", "ubuntu", "linuxmint", "pop"}:
            compose_package = ""
            for candidate in ("docker-compose-v2", "docker-compose-plugin", "docker-compose"):
                if run_command(["apt-cache", "show", candidate], timeout=20).ok:
                    compose_package = candidate
                    break
            packages = ["docker.io"] + ([compose_package] if compose_package else [])
            return [[*prefix, "apt-get", "update"],
                    [*prefix, "apt-get", "install", "-y", *packages],
                    [*prefix, "systemctl", "enable", "--now", "docker"]]
        if shutil.which("dnf") or distro in {"fedora", "rhel", "centos", "rocky", "almalinux"}:
            docker_package = "docker" if run_command(["dnf", "info", "docker"], timeout=20).ok else "moby-engine"
            compose_package = "docker-compose-plugin" if run_command(["dnf", "info", "docker-compose-plugin"], timeout=20).ok else "docker-compose"
            return [[*prefix, "dnf", "install", "-y", docker_package, compose_package],
                    [*prefix, "systemctl", "enable", "--now", "docker"]]
        if shutil.which("pacman") or distro in {"arch", "manjaro"}:
            return [[*prefix, "pacman", "-Sy", "--noconfirm", "docker", "docker-compose"],
                    [*prefix, "systemctl", "enable", "--now", "docker"]]
        if shutil.which("zypper") or distro in {"opensuse", "opensuse-leap", "opensuse-tumbleweed", "sles"}:
            return [[*prefix, "zypper", "--non-interactive", "install", "docker", "docker-compose"],
                    [*prefix, "systemctl", "enable", "--now", "docker"]]
        return []

    def install_docker(self, commands: Sequence[Sequence[str]]) -> CommandResult:
        last = CommandResult([], 0)
        for command in commands:
            last = run_command(command, self.project, timeout=1200)
            if not last.ok:
                return last
        if self.system == "Windows":
            self.start_docker_desktop()
        return last

    def start_docker_desktop(self) -> bool:
        if self.system != "Windows":
            return False
        candidates = [
            Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Docker" / "Docker" / "Docker Desktop.exe",
            Path(os.environ.get("LOCALAPPDATA", "")) / "Docker" / "Docker Desktop.exe",
        ]
        for candidate in candidates:
            if candidate.is_file():
                try:
                    subprocess.Popen([str(candidate)], cwd=candidate.parent)
                    return True
                except OSError:
                    continue
        return False

    def open_docker_website(self) -> None:
        webbrowser.open(DOCKER_DESKTOP_URL, new=2)

    def docker_group_command(self) -> list[str]:
        if self.system != "Linux":
            return []
        user = os.environ.get("USER") or os.environ.get("LOGNAME") or ""
        if not user or not re.fullmatch(r"[A-Za-z0-9_.-]+", user):
            return []
        return [*self.privilege_prefix(), "usermod", "-aG", "docker", user]

    def add_user_to_docker_group(self, command: Sequence[str]) -> CommandResult:
        return run_command(command, self.project, timeout=60)


def format_command(command: Sequence[str]) -> str:
    """Format a command for explicit user review without executing a shell."""
    argv = [str(value) for value in command]
    return subprocess.list2cmdline(argv) if os.name == "nt" else shlex.join(argv)
