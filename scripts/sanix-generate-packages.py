#!/usr/bin/env python3
"""Generate apt Packages / Release metadata for the Sanix (io.sanix) repository.

Usage: sanix-generate-packages.py <repo_root> <pool_dir> <dists_dir>

Creates:
  <dists_dir>/stable/main/binary-aarch64/Packages
  <dists_dir>/stable/main/binary-aarch64/Packages.gz
  <dists_dir>/stable/Release
Signing (InRelease / Release.gpg) is done by the caller.
"""
import gzip
import hashlib
import os
import subprocess
import sys
from email.utils import formatdate


def control_fields(deb_path):
    out = subprocess.check_output(["dpkg-deb", "-f", deb_path]).decode("utf-8")
    return out


def repo_checksums(path):
    sha1 = hashlib.sha1()
    sha256 = hashlib.sha256()
    md5 = hashlib.md5()
    size = 0
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            sha1.update(chunk)
            sha256.update(chunk)
            md5.update(chunk)
            size += len(chunk)
    return size, md5.hexdigest(), sha1.hexdigest(), sha256.hexdigest()


def main():
    repo_root = os.path.abspath(sys.argv[1])
    pool_dir = os.path.abspath(sys.argv[2])
    dists_dir = os.path.abspath(sys.argv[3])
    suite = "stable"
    component = "main"
    arch = "aarch64"

    packages_dir = os.path.join(dists_dir, suite, component, f"binary-{arch}")
    os.makedirs(packages_dir, exist_ok=True)

    debs = []
    for root, _dirs, files in os.walk(pool_dir):
        for fn in sorted(files):
            if fn.endswith(".deb"):
                debs.append(os.path.join(root, fn))
    debs.sort()

    package_blocks = []
    for deb in debs:
        rel = os.path.relpath(deb, repo_root)
        size, md5, sha1, sha256 = repo_checksums(deb)
        ctrl = control_fields(deb)
        extra = (
            f"Filename: {rel}\n"
            f"Size: {size}\n"
            f"MD5sum: {md5}\n"
            f"SHA1: {sha1}\n"
            f"SHA256: {sha256}\n"
        )
        package_blocks.append(ctrl.rstrip("\n") + "\n" + extra)

    packages_path = os.path.join(packages_dir, "Packages")
    with open(packages_path, "w") as fh:
        fh.write("\n".join(package_blocks))
        if package_blocks:
            fh.write("\n")

    with gzip.open(packages_path + ".gz", "wb") as fh:
        with open(packages_path, "rb") as raw:
            fh.write(raw.read())

    p_size, p_md5, p_sha1, p_sha256 = repo_checksums(packages_path)
    g_size, g_md5, g_sha1, g_sha256 = repo_checksums(packages_path + ".gz")
    p_rel = f"{component}/binary-{arch}/Packages"
    g_rel = f"{component}/binary-{arch}/Packages.gz"

    release = "\n".join(
        [
            "Origin: Sanix Termux fork (io.sanix)",
            "Label: Sanix",
            f"Suite: {suite}",
            f"Codename: {suite}",
            f"Date: {formatdate(usegmt=True)}",
            f"Architectures: {arch}",
            f"Components: {component}",
            "Description: Sanix (io.sanix) package repository",
            "MD5Sum:",
            f" {p_md5} {p_size} {p_rel}",
            f" {g_md5} {g_size} {g_rel}",
            "SHA1:",
            f" {p_sha1} {p_size} {p_rel}",
            f" {g_sha1} {g_size} {g_rel}",
            "SHA256:",
            f" {p_sha256} {p_size} {p_rel}",
            f" {g_sha256} {g_size} {g_rel}",
            "",
        ]
    )
    release_path = os.path.join(dists_dir, suite, "Release")
    with open(release_path, "w") as fh:
        fh.write(release)

    print(f"Wrote {len(debs)} package(s):")
    for deb in debs:
        print(f"  {os.path.relpath(deb, repo_root)}")


if __name__ == "__main__":
    main()
