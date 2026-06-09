#!/usr/bin/env python3
"""Create tiny demo files for the Hermes workspace file manager."""

from __future__ import annotations

import argparse
import base64
from pathlib import Path


PNG_1X1_GREEN = (
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGNg"
    "+M8AAwMBAYEPpKcAAAAASUVORK5CYII="
)


def seed(workspace: Path) -> None:
    outputs = workspace / "outputs" / "demo"
    projects = workspace / "projects" / "example"
    reports = workspace / "reports"

    for path in [outputs, projects, reports]:
        path.mkdir(parents=True, exist_ok=True)

    (outputs / "demo_preview.png").write_bytes(base64.b64decode(PNG_1X1_GREEN))
    (outputs / "demo_table.csv").write_text(
        "site,temperature_c,ndvi\n"
        "alpha,18.4,0.62\n"
        "beta,20.1,0.54\n"
        "gamma,17.7,0.69\n",
        encoding="utf-8",
    )
    (reports / "demo_report.md").write_text(
        "# Demo Workspace Report\n\n"
        "This Markdown file exists so the file manager can preview headings, tables, code, and images.\n\n"
        "| Output | Purpose |\n"
        "| --- | --- |\n"
        "| `demo_preview.png` | Image preview smoke test |\n"
        "| `demo_table.csv` | CSV preview smoke test |\n\n"
        "![Demo preview](../outputs/demo/demo_preview.png)\n\n"
        "```python\n"
        "print('Hermes file manager demo')\n"
        "```\n",
        encoding="utf-8",
    )
    (projects / "analysis.py").write_text(
        "# Editable demo script for the Hermes file manager.\n"
        "from pathlib import Path\n\n"
        "workspace = Path('/workspace')\n"
        "print(f'Workspace exists: {workspace.exists()}')\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace", default="/workspace", help="Workspace directory to seed.")
    args = parser.parse_args()
    seed(Path(args.workspace))
    print(f"Seeded file-manager demo workspace at {Path(args.workspace).resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
