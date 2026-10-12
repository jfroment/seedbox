#!/usr/bin/env python3
"""Generate config.schema.json, the schema of config.yaml.

This schema is used by run-seedbox.sh, which refuses any parameter of config.yaml which is not in it, and by
editors (completion and validation, thanks to the first line of config.sample.yaml).

Run it after adding a parameter or a service:

    tools/generate_schema.py            # write config.schema.json
    tools/generate_schema.py --check    # only check that config.schema.json is up to date (exit code 1 if not)

Parameters come from two sources:
  - the ones described below (TOP_LEVEL, SERVICE and RULE): type and description
  - the ones found in config.sample.yaml and in the service.yaml file of each service (default rules). A parameter
    found there but not described below is added anyway, with a type guessed from its value: the script tells you
    so, and you should then describe it below.

The names of the bundled services (directories of services/) are added too, for completion in editors.

Only "yq" is needed (already required by the seedbox), no Python package.
"""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_FILE = ROOT / "config.schema.json"

# Parameters of a Traefik rule ("rules" of a service and "defaults")
RULE = {
    "host": {
        "description": "Host to match requests, example: sonarr.${TRAEFIK_DOMAIN}",
        "type": "string",
    },
    "internalPort": {
        "description": "Port of the service, inside its container.",
        "type": ["integer", "string"],
    },
    "internalScheme": {
        "description": "Scheme used to reach the service (default: http).",
        "enum": ["http", "https"],
    },
    "httpAuth": {
        "description": "Enable http authentication, with the user and password of your .env file (default: false).",
        "type": "boolean",
    },
    "internalOnly": {
        "description": "Only reachable from your private networks (default: false).",
        "type": "boolean",
    },
    "mtls": {
        "description": "Only reachable with a client certificate, see doc/apps/vaultls.md (default: false).",
        "type": "boolean",
    },
    "httpOnly": {
        "description": "Plain http only, without certificate nor redirection to https (default: false).",
        "type": "boolean",
    },
    "service": {
        "description": "Traefik service to use instead of creating one for the container, example: api@internal",
        "type": "string",
    },
}

# Parameters of a service
SERVICE = {
    "enabled": {
        "description": "Set to false to keep the service in the file without running it (default: true).",
        "type": "boolean",
    },
    "vpn": {
        "description": "Route the service through the VPN client, gluetun (default: false).",
        "type": "boolean",
    },
    "customFile": {
        "description": "docker-compose file to use, relative to the directory of the service (default: compose.yaml).",
        "type": "string",
    },
    "traefik": {
        "description": "Set to false to disable Traefik routing for this service (default: true if it has rules).",
        "type": "boolean",
    },
    "rules": {
        "description": "Traefik rules. The first one overrides the first default rule of the service and so on, "
        "only for the parameters you write.",
        "type": "array",
        "items": {"$ref": "#/$defs/rule"},
    },
}

# Top-level parameters
TOP_LEVEL = {
    "defaults": {
        "description": "Parameters applied to the Traefik rules of all services (still overridable for each service).",
        "$ref": "#/$defs/rule",
    },
    "services": {
        "description": "Services to run. The name of a service is the name of its directory in services/.",
        "type": "object",
    },
}


def load_yaml(path):
    """Read a YAML file with yq (None if the file is empty)."""
    out = subprocess.run(["yq", "-o", "json", ".", str(path)], check=True, capture_output=True, text=True).stdout
    return json.loads(out) if out.strip() else None


def guess(value):
    """Schema of a parameter which is not described in this script, from one of its values."""
    if isinstance(value, bool):
        return {"type": "boolean"}
    if isinstance(value, int):
        return {"type": ["integer", "string"]}
    if isinstance(value, list):
        return {"type": "array"}
    if isinstance(value, dict):
        return {"type": "object"}
    return {"type": "string"}


def discover(known, found, kind, source, undescribed):
    """Add to "known" the parameters of "found" which are not described."""
    for key, value in (found or {}).items():
        if key not in known:
            known[key] = guess(value)
            undescribed.append(f'{kind} parameter "{key}" (found in {source})')


def build():
    rule, service, top = dict(RULE), dict(SERVICE), dict(TOP_LEVEL)
    undescribed = []

    # Bundled services: a directory with a compose.yaml file
    bundled = sorted(d.name for d in (ROOT / "services").iterdir() if (d / "compose.yaml").is_file())

    # Default rules of services
    for name in bundled:
        meta_file = ROOT / "services" / name / "service.yaml"
        if meta_file.is_file():
            for r in (load_yaml(meta_file) or {}).get("rules") or []:
                discover(rule, r, "rule", meta_file.relative_to(ROOT), undescribed)

    # Sample configuration
    sample = load_yaml(ROOT / "config.sample.yaml") or {}
    discover(top, sample, "top-level", "config.sample.yaml", undescribed)
    discover(rule, sample.get("defaults"), "rule", "config.sample.yaml", undescribed)
    for name, value in (sample.get("services") or {}).items():
        discover(service, value, "service", "config.sample.yaml", undescribed)
        for r in (value or {}).get("rules") or []:
            discover(rule, r, "rule", "config.sample.yaml", undescribed)

    service_or_empty = {"anyOf": [{"type": "null"}, {"$ref": "#/$defs/service"}]}
    top["services"] = {
        **top["services"],
        # Bundled services are listed for completion; any other name is a service of yours
        "properties": {name: service_or_empty for name in bundled},
        "additionalProperties": service_or_empty,
    }

    schema = {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "Seedbox configuration (config.yaml)",
        "description": "Generated by tools/generate_schema.py: do not edit. See doc/configuration.md. "
        "run-seedbox.sh refuses any parameter which is not described here.",
        "type": "object",
        "additionalProperties": False,
        "properties": top,
        "$defs": {
            "service": {"type": "object", "additionalProperties": False, "properties": service},
            "rule": {"type": "object", "additionalProperties": False, "properties": rule},
        },
    }
    return json.dumps(schema, indent=2) + "\n", undescribed


def main():
    content, undescribed = build()
    for item in undescribed:
        print(f"⚠️  {item} is not described in {Path(__file__).name}: added with a guessed type, please describe it.")

    if "--check" in sys.argv[1:]:
        if not SCHEMA_FILE.is_file() or SCHEMA_FILE.read_text() != content:
            print(f"❌ {SCHEMA_FILE.name} is not up to date: run tools/generate_schema.py")
            sys.exit(1)
        print(f"{SCHEMA_FILE.name} is up to date.")
        return

    SCHEMA_FILE.write_text(content)
    print(f"{SCHEMA_FILE.name} generated.")


if __name__ == "__main__":
    main()
