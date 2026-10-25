"""
pytest settings for the backend tests.

The Stage 4-7c test files are plain scripts: they run their checks when they are
started and stop with sys.exit(). pytest must not import them directly (the
sys.exit would stop pytest), so they are skipped here and test_check_scripts.py
runs each one on its own instead. New tests are normal pytest files.
"""

# The older check scripts, run by test_check_scripts.py.
CHECK_SCRIPTS = [
    "test_adaptive.py",
    "test_auth.py",
    "test_progress.py",
    "test_reflection.py",
    "test_scaffolding.py",
]

collect_ignore = CHECK_SCRIPTS
