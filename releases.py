from datetime import datetime
from itertools import count
import json
import os
from typing import Any
import logging

import requests

KEEP_RECENT_RELEASES: int = 30
KEEP_RECENT_NIGHTLY_RELEASES: int = 10

EXTRA_RELEASES: list[str] = [
    # nightly-2024-01-01
    "stable",
    # "beta",
    "nightly",
    # "lean-toolchain",
]
"""
Releases that should be skipped, use lean-toolchain format
"""

SKIPPED_RELEASES: list[str] = [
    # 4.0.0
    # nightly-2024-01-01
]
"""
Releases that should be skipped, use lean-toolchain format
"""


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def fetch_releases(repo: str, limit: int | None = None) -> list[str]:
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
        logger.info("Got %d releases from %r", len(releases), repo)
        all_releases.extend(releases)
        if not releases or (limit is not None and len(all_releases) >= limit):
            break
    all_releases.sort(
        key=lambda release: datetime.fromisoformat(release["published_at"]),
        reverse=True,
    )
    if limit is not None:
        all_releases = all_releases[:limit]
    return [release["tag_name"] for release in all_releases]


def main():
    prod_releases = [
        tag
        for tag in fetch_releases("leanprover/lean4", KEEP_RECENT_RELEASES)
        if tag.startswith("v")
    ]
    # print("Following toolchain releases will be used:")
    # print("\n".join(prod_releases))
    logger.info("Following toolchain releases will be used: %r", prod_releases)

    nightly_releases = [
        tag
        for tag in fetch_releases(
            "leanprover/lean4-nightly", KEEP_RECENT_NIGHTLY_RELEASES
        )
        if tag.startswith("nightly")
    ]
    logger.info(
        "Following nightly toolchain releases will be used: %r", nightly_releases
    )

    all_releases = [
        tag
        for tag in (
            set(prod_releases + nightly_releases)
            | set(EXTRA_RELEASES) - set(SKIPPED_RELEASES)
        )
    ]
    all_releases.sort(reverse=True)
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write("matrix=" + json.dumps({"toolchain": all_releases}) + "\n")
    return


if __name__ == "__main__":
    main()
