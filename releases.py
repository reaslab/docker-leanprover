from datetime import datetime
from itertools import count
import json
import os
from typing import Any

import requests

KEEP_RECENT_RELEASES: int = 20
KEEP_RECENT_NIGHTLY_RELEASES: int = 10

EXTRA_RELEASES: list[str] = [
    # leanprover/lean4:nightly-2024-01-01
]
"""
Releases that should be skipped, use lean-toolchain format
"""

SKIPPED_RELEASES: list[str] = [
    # leanprover/lean4:4.0.0
]
"""
Releases that should be skipped, use lean-toolchain format
"""


def fetch_releases(repo: str) -> list[str]:
    all_releases: list[dict[str, Any]] = []
    for page in count(1):
        response = requests.get(
            f"https://api.github.com/repos/{repo}/releases",
            headers={
                "Accept": "application/vnd.github.v3+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "Authorization": "Bearer {GITHUB_TOKEN}".format_map(os.environ),
            },
            params={"page": page},
        )
        response.raise_for_status()
        releases: list[dict[str, Any]] = response.json()
        all_releases.extend(releases)
    all_releases.sort(
        key=lambda release: datetime.fromisoformat(release["published_at"]),
        reverse=True,
    )
    return [release["tag_name"] for release in all_releases]


def main():
    prod_releases = [
        tag for tag in fetch_releases("leanprover/lean4") if tag.startswith("v")
    ][:KEEP_RECENT_RELEASES]
    print("Following toolchain releases will be used:")
    print("\n".join(prod_releases))

    nightly_releases = [
        tag
        for tag in fetch_releases("leanprover/lean4-nightly")
        if tag.startswith("nightly")
    ][:KEEP_RECENT_NIGHTLY_RELEASES]
    print("Following nightly toolchain releases will be used:")
    print("\n".join(nightly_releases))

    all_releases = {
        f"leanprover/lean4:{tag}" for tag in prod_releases + nightly_releases
    }
    all_releases.update(EXTRA_RELEASES)
    all_releases.difference_update(SKIPPED_RELEASES)
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write("matrix=" + json.dumps({"toolchain": [*all_releases]}) + "\n")
    return


if __name__ == "__main__":
    main()
