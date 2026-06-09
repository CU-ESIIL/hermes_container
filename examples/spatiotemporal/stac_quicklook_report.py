#!/usr/bin/env python3
"""Run the example STAC preview task and rebuild the output index."""

from __future__ import annotations

import subprocess
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    task = repo_root / "examples/spatiotemporal/tasks/example_stac_preview.yaml"
    worker = repo_root / "workers/spatiotemporal-worker/run_task.py"
    result = subprocess.run(
        ["python3", str(worker), "--task", str(task), "--output-dir", str(repo_root / "data/outputs/jobs/example-stac-preview-direct")],
        check=False,
    )
    if result.returncode != 0:
        return result.returncode
    indexer = repo_root / "scripts/build_output_index.py"
    return subprocess.run(["python3", str(indexer), "--data-root", str(repo_root / "data")], check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
