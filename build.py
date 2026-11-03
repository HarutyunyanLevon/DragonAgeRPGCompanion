#!/usr/bin/env python3
"""One command for the whole build. Run it from anywhere:

    python build.py                prepare: pub get + build_runner + gen-l10n
    python build.py -g             prepare, but only gen-l10n (after editing .arb files)
    python build.py -b             prepare, but only build_runner (after editing models)
    python build.py -t             prepare, then run the tests
    python build.py -win           prepare, then run the app on Windows
    python build.py -t -win        prepare, run the tests, then run the app
    python build.py -a             prepare, then run the app on an Android device

The steps always run in this order, and the script stops at the first one
that fails (so a failing test keeps the app from starting). When the tests
fail, `flutter analyze` runs too, because it shows compile errors clearly.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent


def run(*command, analyze_on_fail=False):
    """Runs one command in the project folder; exits the script if it fails.
    With analyze_on_fail, `flutter analyze` runs first to explain the failure."""
    # which() finds flutter.bat / dart.bat on Windows, where plain "flutter" fails.
    executable = shutil.which(command[0])
    if executable is None:
        sys.exit(f"'{command[0]}' not found. Is Flutter on your PATH?")
    print(f"\n> {' '.join(command)}", flush=True)
    result = subprocess.run([executable, *command[1:]], cwd=PROJECT)
    if result.returncode != 0:
        if analyze_on_fail:
            print('\nThe tests failed. Analyzing the code for errors...', flush=True)
            subprocess.run([executable, 'analyze'], cwd=PROJECT)
        sys.exit(result.returncode)


def main():
    parser = argparse.ArgumentParser(description='Build, test and run the app.')
    parser.add_argument('-g', '--l10n', action='store_true', help='prepare: gen-l10n only')
    parser.add_argument('-b', '--codegen', action='store_true', help='prepare: build_runner only')
    parser.add_argument('-t', '--test', action='store_true', help='run the tests')
    parser.add_argument('-win', '--windows', action='store_true', help='run the app on Windows')
    parser.add_argument('-a', '--android', action='store_true', help='run the app on Android')
    args = parser.parse_args()

    if args.windows and args.android:
        sys.exit('Pick one of -win and -a: the app keeps running until you close it.')

    # Prepare: -g and/or -b pick single steps; with neither, everything runs.
    everything = not (args.l10n or args.codegen)
    if everything:
        run('flutter', 'pub', 'get')
    if everything or args.codegen:
        run('dart', 'run', 'build_runner', 'build')
    if everything or args.l10n:
        run('flutter', 'gen-l10n')

    if args.test:
        run('flutter', 'test', analyze_on_fail=True)
    if args.windows:
        run('flutter', 'run', '-d', 'windows')
    if args.android:
        run('flutter', 'run', '-d', 'android')


if __name__ == '__main__':
    main()
