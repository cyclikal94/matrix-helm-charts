#!/usr/bin/env python3

import argparse
import pathlib
import re
import shutil
import subprocess
import tempfile


LOCAL_DEP_REPO_RE = re.compile(r'^\s*repository:\s*file://\.\./([^"\n#\s]+)\s*$')
TOP_LEVEL_VERSION_RE = re.compile(r'^version:\s*"?([^"\n#]+)"?\s*$')
DEP_NAME_RE = re.compile(r'^\s*-\s*name:\s*"?([^"\n#]+)"?\s*$')
DEP_VERSION_RE = re.compile(r'^(\s*version:\s*).*$')


def run(*args: str) -> str:
    return subprocess.check_output(list(args), text=True).strip()


def chart_dependency_graph(charts_root: pathlib.Path) -> tuple[dict[str, pathlib.Path], dict[str, set[str]]]:
    chart_dirs: dict[str, pathlib.Path] = {}
    consumers_by_dep: dict[str, set[str]] = {}

    for chart_yaml in sorted(charts_root.glob("*/Chart.yaml")):
        chart_name = chart_yaml.parent.name
        chart_dirs[chart_name] = chart_yaml.parent

        deps: list[str] = []
        for line in chart_yaml.read_text().splitlines():
            match = LOCAL_DEP_REPO_RE.match(line)
            if match:
                deps.append(match.group(1))

        for dep in deps:
            consumers_by_dep.setdefault(dep, set()).add(chart_name)

    return chart_dirs, consumers_by_dep


def detect_changed_charts(charts_root: pathlib.Path, base_sha: str, head_sha: str) -> list[str]:
    chart_dirs, consumers_by_dep = chart_dependency_graph(charts_root)
    merge_base = run("git", "merge-base", base_sha, head_sha)
    diff_lines = run("git", "diff", "--name-only", merge_base, head_sha, "--", "charts").splitlines()

    changed: set[str] = set()
    for path in diff_lines:
        parts = pathlib.Path(path).parts
        if len(parts) < 2 or parts[0] != "charts":
            continue
        chart_name = parts[1]
        if chart_name in chart_dirs:
            changed.add(chart_name)

    affected = set(changed)
    queue = list(changed)
    while queue:
        dep = queue.pop(0)
        for consumer in consumers_by_dep.get(dep, set()):
            if consumer not in affected:
                affected.add(consumer)
                queue.append(consumer)

    return sorted(affected)


def write_github_output(output_path: pathlib.Path, charts: list[str]) -> None:
    with output_path.open("a") as handle:
        handle.write(f"has_charts={'true' if charts else 'false'}\n")
        handle.write("charts<<EOF\n")
        handle.write("\n".join(charts))
        handle.write("\nEOF\n")


def read_charts_file(charts_file: pathlib.Path) -> list[str]:
    if not charts_file.exists():
        return []
    return [line.strip() for line in charts_file.read_text().splitlines() if line.strip()]


def preview_versions(charts_root: pathlib.Path, charts: list[str], pr_number: str, head_sha: str, mode: str) -> dict[str, str]:
    suffix = f"pr.{pr_number}.{head_sha[:7]}" if mode == "commit" else f"pr.{pr_number}"
    versions: dict[str, str] = {}

    for chart_name in charts:
        chart_yaml = charts_root / chart_name / "Chart.yaml"
        match = TOP_LEVEL_VERSION_RE.search(chart_yaml.read_text())
        if not match:
            raise RuntimeError(f"Unable to find top-level version in {chart_yaml}")
        base_version = match.group(1).split("+", 1)[0].split("-", 1)[0]
        versions[chart_name] = f"{base_version}-{suffix}"

    return versions


def rewrite_chart_versions(charts_root: pathlib.Path, charts: list[str], versions: dict[str, str]) -> None:
    for chart_name in charts:
        chart_yaml = charts_root / chart_name / "Chart.yaml"
        lines = chart_yaml.read_text().splitlines()
        rewritten: list[str] = []
        in_dependencies = False
        current_dependency = None

        for line in lines:
            if TOP_LEVEL_VERSION_RE.match(line):
                line = f"version: {versions[chart_name]}"

            if re.match(r"^dependencies:\s*$", line):
                in_dependencies = True
                current_dependency = None
            elif in_dependencies and re.match(r"^[A-Za-z0-9_-]+:", line):
                in_dependencies = False
                current_dependency = None

            if in_dependencies:
                dep_name_match = DEP_NAME_RE.match(line)
                if dep_name_match:
                    current_dependency = dep_name_match.group(1)
                else:
                    dep_version_match = DEP_VERSION_RE.match(line)
                    if dep_version_match and current_dependency in versions:
                        line = f"{dep_version_match.group(1)}{versions[current_dependency]}"
                        current_dependency = None

            rewritten.append(line)

        chart_yaml.write_text("\n".join(rewritten) + "\n")


def package_and_push(charts_root: pathlib.Path, charts: list[str], versions: dict[str, str], oci_registry: str) -> None:
    with tempfile.TemporaryDirectory() as package_dir:
        package_dir_path = pathlib.Path(package_dir)
        for chart_name in charts:
            chart_dir = charts_root / chart_name
            chart_yaml = chart_dir / "Chart.yaml"
            if "dependencies:" in chart_yaml.read_text():
                subprocess.run(["helm", "dependency", "update", str(chart_dir)], check=True)

            subprocess.run(["helm", "package", str(chart_dir), "--destination", package_dir], check=True)
            package_file = package_dir_path / f"{chart_name}-{versions[chart_name]}.tgz"
            if not package_file.exists():
                raise RuntimeError(f"Failed to locate packaged artifact for {chart_name}")

            subprocess.run(["helm", "push", str(package_file), oci_registry], check=True)


def command_detect(args: argparse.Namespace) -> int:
    charts = detect_changed_charts(pathlib.Path(args.charts_root), args.base_sha, args.head_sha)
    if args.github_output:
        write_github_output(pathlib.Path(args.github_output), charts)
    else:
        print("\n".join(charts))
    return 0


def command_publish(args: argparse.Namespace) -> int:
    charts = read_charts_file(pathlib.Path(args.charts_file))
    versions_output = pathlib.Path(args.versions_output)
    versions_output.write_text("")
    if not charts:
        return 0

    charts_root = pathlib.Path(args.charts_root)
    with tempfile.TemporaryDirectory() as work_dir:
        work_charts_root = pathlib.Path(work_dir) / "charts"
        shutil.copytree(charts_root, work_charts_root)

        versions = preview_versions(work_charts_root, charts, args.pr_number, args.head_sha, args.mode)
        rewrite_chart_versions(work_charts_root, charts, versions)
        package_and_push(work_charts_root, charts, versions, args.oci_registry)
        versions_output.write_text("".join(f"{chart}={versions[chart]}\n" for chart in charts))

    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    detect_parser = subparsers.add_parser("detect")
    detect_parser.add_argument("--charts-root", default="charts")
    detect_parser.add_argument("--base-sha", required=True)
    detect_parser.add_argument("--head-sha", required=True)
    detect_parser.add_argument("--github-output")
    detect_parser.set_defaults(func=command_detect)

    publish_parser = subparsers.add_parser("publish")
    publish_parser.add_argument("--charts-root", default="charts")
    publish_parser.add_argument("--charts-file", required=True)
    publish_parser.add_argument("--pr-number", required=True)
    publish_parser.add_argument("--head-sha", required=True)
    publish_parser.add_argument("--mode", choices=("rolling", "commit"), required=True)
    publish_parser.add_argument("--oci-registry", required=True)
    publish_parser.add_argument("--versions-output", required=True)
    publish_parser.set_defaults(func=command_publish)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
