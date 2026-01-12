#!/usr/bin/env python3
"""
SGOS App Validator

Validates that an app directory has all required configuration for deployment.
Run before deployment to catch configuration issues early.

Usage:
    ./validate-app.py /path/to/app
    ./validate-app.py /srv/apps/sgos-phone/src
"""

import json
import os
import sys
from pathlib import Path


class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    RESET = "\033[0m"
    BOLD = "\033[1m"


def ok(msg: str) -> str:
    return f"{Colors.GREEN}✓{Colors.RESET} {msg}"


def fail(msg: str) -> str:
    return f"{Colors.RED}✗{Colors.RESET} {msg}"


def warn(msg: str) -> str:
    return f"{Colors.YELLOW}!{Colors.RESET} {msg}"


def validate_app(app_dir: Path) -> tuple[int, int, int]:
    """
    Validate an app directory.
    Returns: (passed, failed, warnings)
    """
    passed = 0
    failed = 0
    warnings = 0

    print(f"\n{Colors.BOLD}Validating:{Colors.RESET} {app_dir}\n")

    # 1. Check app.json exists and has required fields
    app_json_path = app_dir / "app.json"
    if not app_json_path.exists():
        print(fail("app.json: not found"))
        failed += 1
    else:
        try:
            with open(app_json_path) as f:
                app_config = json.load(f)

            required_fields = {
                "name": "App identifier",
                "version": "Semantic version",
            }

            required_nested = {
                ("sgos", "server"): "Target deployment server",
                ("sgos", "domain"): "Public domain",
                ("scripts", "backup"): "Backup script command",
                ("sgos", "backup", "output"): "Backup output directory",
            }

            app_json_errors = []

            # Check top-level required fields
            for field, desc in required_fields.items():
                if not app_config.get(field):
                    app_json_errors.append(f"  - missing: {field} ({desc})")

            # Check nested required fields
            for path, desc in required_nested.items():
                obj = app_config
                for key in path:
                    obj = obj.get(key, {}) if isinstance(obj, dict) else {}
                if not obj:
                    field_path = ".".join(path)
                    app_json_errors.append(f"  - missing: {field_path} ({desc})")

            if app_json_errors:
                print(fail("app.json: invalid"))
                for err in app_json_errors:
                    print(f"  {Colors.RED}{err}{Colors.RESET}")
                failed += 1
            else:
                app_name = app_config.get("name", "unknown")
                app_version = app_config.get("version", "?")
                print(ok(f"app.json: valid ({app_name} v{app_version})"))
                passed += 1

            # Check optional fields
            optional_fields = ["description", "repository"]
            for field in optional_fields:
                if not app_config.get(field):
                    print(warn(f"app.json: optional field '{field}' not set"))
                    warnings += 1

        except json.JSONDecodeError as e:
            print(fail(f"app.json: invalid JSON - {e}"))
            failed += 1

    # 2. Check backup.sh exists and is executable
    backup_script = app_dir / "backup.sh"
    if not backup_script.exists():
        print(fail("backup.sh: not found"))
        failed += 1
    elif not os.access(backup_script, os.X_OK):
        print(fail("backup.sh: exists but not executable"))
        failed += 1
    else:
        print(ok("backup.sh: exists, executable"))
        passed += 1

    # 3. Check docker-compose.yml exists
    compose_file = app_dir / "docker-compose.yml"
    if not compose_file.exists():
        print(fail("docker-compose.yml: not found"))
        failed += 1
    else:
        # Check if it contains sgos network
        compose_content = compose_file.read_text()
        if "sgos:" in compose_content and "external: true" in compose_content:
            print(ok("docker-compose.yml: valid, has sgos network"))
            passed += 1
        else:
            print(warn("docker-compose.yml: exists but missing sgos external network"))
            warnings += 1
            passed += 1  # Still counts as passed, just a warning

    # 4. Check Dockerfile exists (optional for some apps)
    dockerfile = app_dir / "Dockerfile"
    if dockerfile.exists():
        print(ok("Dockerfile: exists"))
        passed += 1
    else:
        print(warn("Dockerfile: not found (may use pre-built image)"))
        warnings += 1

    # 5. Check .env.sops exists (secrets)
    env_sops = app_dir / ".env.sops"
    if env_sops.exists():
        print(ok(".env.sops: exists (secrets configured)"))
        passed += 1
    else:
        print(warn(".env.sops: not found (no encrypted secrets)"))
        warnings += 1

    return passed, failed, warnings


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} /path/to/app")
        print(f"Example: {sys.argv[0]} /srv/apps/sgos-phone/src")
        sys.exit(2)

    app_dir = Path(sys.argv[1])

    if not app_dir.is_dir():
        print(f"Error: {app_dir} is not a directory")
        sys.exit(2)

    passed, failed, warnings = validate_app(app_dir)

    total = passed + failed
    print(f"\n{Colors.BOLD}Result:{Colors.RESET} ", end="")

    if failed == 0:
        print(f"{Colors.GREEN}PASSED{Colors.RESET} ({passed}/{total} checks", end="")
        if warnings > 0:
            print(f", {warnings} warnings", end="")
        print(")")
        sys.exit(0)
    else:
        print(f"{Colors.RED}FAILED{Colors.RESET} ({passed}/{total} checks, {failed} errors)")
        sys.exit(1)


if __name__ == "__main__":
    main()
