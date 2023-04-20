#!/usr/bin/env python3

import argparse
import os
import logging
import subprocess
from functools import partial
from itertools import product


logging.basicConfig(level=logging.INFO)

UBUNTU_VERSIONS = ["jammy", "focal"]
PYTHON_VERSIONS = ["3.7", "3.8", "3.9", "3.10", "3.11"]
NODE_VERSIONS = ["14", "16", "18"]

UBUNTU_PYTHON_METADATA = {
    "jammy": {
        "supported_versions": ["3.10", "3.11"],
        "unsupported_repository": "ppa:deadsnakes/ppa",
    },
    "focal": {
        "supported_versions": ["3.8", "3.9"],
        "unsupported_repository": "ppa:deadsnakes/ppa",
    },
}


def main(args):
    cmd = partial(_cmd, dry_run=args.dry_run)

    versions = product(args.python_versions, args.node_versions, args.ubuntu_versions)

    # Enable docker build cache
    os.environ["DOCKER_BUILDKIT"] = "1"
    os.environ["BUILDKIT_INLINE_CACHE"] = "1"

    for parts in versions:
        python, node, ubuntu = parts

        img = f"{args.tag_prefix}:{python}-{node}-{ubuntu}"

        apt_repo = ""

        # Check if our ubuntu/python combo requires an extra apt repository
        if python not in UBUNTU_PYTHON_METADATA[ubuntu]["supported_versions"]:
            apt_repo = UBUNTU_PYTHON_METADATA[ubuntu]["unsupported_repository"]

        if apt_repo:
            logging.info("Building %s using the %s apt repository", img, apt_repo)
        else:
            logging.info("Building %s", img)

        logging.info(f"{'=' * 28} {img} {'=' * 28}")

        docker_tag = partial(cmd, "docker", "tag", img)
        docker_build = partial(
            cmd,
            "docker",
            "build",
            "--build-arg",
            f"UBUNTU_VERSION={ubuntu}",
            "--build-arg",
            f"APT_REPOSITORY={apt_repo}",
            "--build-arg",
            f"PYTHON_VERSION={python}",
            "--build-arg",
            f"NODE_VERSION={node}",
            "-t",
            img,
            "-f",
            "Dockerfile",
            ".",
        )

        # Build the image
        # docker build
        docker_tag()

        if ubuntu == UBUNTU_VERSIONS[-1]:
            docker_tag(f"{args.tag_prefix}:{python}-{node}")
        if node == NODE_VERSIONS[-1]:
            docker_tag(f"{args.tag_prefix}:{python}-{ubuntu}")
        if ubuntu == UBUNTU_VERSIONS[-1] and node == NODE_VERSIONS[-1]:
            docker_tag(f"{args.tag_prefix}:{python}")
        if (
            ubuntu == UBUNTU_VERSIONS[-1]
            and node == NODE_VERSIONS[-1]
            and python == PYTHON_VERSIONS[-1]
        ):
            docker_tag(f"{args.tag_prefix}:latest")


def _cmd(*args, dry_run=False):
    logging.info("%s", " ".join(args))

    if not dry_run:
        return subprocess.run(args, capture_output=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag_prefix", default="py-node")
    parser.add_argument("--tag_suffix", default="")
    parser.add_argument("--ubuntu-versions", nargs="+", default=UBUNTU_VERSIONS)
    parser.add_argument("--python-versions", nargs="+", default=PYTHON_VERSIONS)
    parser.add_argument("--node-versions", nargs="+", default=NODE_VERSIONS)
    parser.add_argument("--dry-run", action="store_false")

    args = parser.parse_args()

    main(args)
