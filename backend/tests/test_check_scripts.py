"""
Runs each older check script (see conftest.py) as its own small program.

Each script runs in a fresh Python, so the fakes one script puts into db.py
(for example a fake Supabase client) can never leak into another script.
A script passes when it ends with exit code 0 ("All checks passed.").
If one fails, pytest shows the script's output with the failing check names.
"""

import os
import subprocess
import sys
from pathlib import Path

import pytest

from conftest import CHECK_SCRIPTS

TESTS_DIR = Path(__file__).resolve().parent


@pytest.mark.parametrize("script", CHECK_SCRIPTS)
def test_check_script_passes(script):
    result = subprocess.run(
        [sys.executable, str(TESTS_DIR / script)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=300,
        # The scripts send many messages quickly; the speed limit is tested in test_online.py.
        env={**os.environ, "CHAT_LIMIT_PER_MINUTE": "10000", "REQUIRE_LOGIN": "false"},
    )
    assert result.returncode == 0, result.stdout + result.stderr
