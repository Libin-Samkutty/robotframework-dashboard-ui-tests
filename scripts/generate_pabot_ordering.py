"""Generate a pabot ordering file that runs the slowest tests first.

Reads per-test elapsed time from a previous run's output.xml (if one exists)
and writes a pabot ordering file listing every test, longest-elapsed-time
first. pabot schedules an ordering file's items top-to-bottom onto the next
free worker process, so putting the slowest tests first (longest-processing-
time-first scheduling) keeps short tests from queuing up behind one slow
test at the tail of the run, which minimizes total wall-clock time under
--testlevelsplit.

If no history file exists yet (first run, or a fresh CI cache), an empty
ordering file is written instead - pabot still runs every test, just without
elapsed-time-based reordering until a history file becomes available.

Usage:
    python scripts/generate_pabot_ordering.py <history-output.xml> <ordering-file-out>
"""

import sys
from pathlib import Path


def collect_durations(output_xml_path):
    from robot.api import ExecutionResult

    durations = {}

    class _Collector:
        def visit_suite(self, suite):
            for test in suite.tests:
                durations[test.longname] = test.elapsedtime
            for subsuite in suite.suites:
                self.visit_suite(subsuite)

    result = ExecutionResult(output_xml_path)
    _Collector().visit_suite(result.suite)
    return durations


def main(argv):
    if len(argv) != 3:
        print(f"usage: {argv[0]} <history-output.xml> <ordering-file-out>")
        return 1

    history_path = Path(argv[1])
    ordering_path = Path(argv[2])
    ordering_path.parent.mkdir(parents=True, exist_ok=True)

    if not history_path.is_file():
        print(f"No history file at {history_path} - skipping longest-first ordering.")
        ordering_path.write_text("")
        return 0

    try:
        durations = collect_durations(str(history_path))
    except Exception as exc:  # noqa: BLE001 - any parse failure just disables ordering
        print(f"Could not parse {history_path} ({exc}) - skipping longest-first ordering.")
        ordering_path.write_text("")
        return 0

    ordered = sorted(durations.items(), key=lambda kv: kv[1], reverse=True)
    lines = [f"--test {name}" for name, _ in ordered]
    ordering_path.write_text("\n".join(lines) + ("\n" if lines else ""))
    print(f"Wrote {len(lines)} test(s) to {ordering_path}, longest first:")
    for name, elapsed in ordered[:5]:
        print(f"  {elapsed:>6} ms  {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
