"""
Delete test accounts before real students use CogniGuide (study preparation).

SAFE BY DEFAULT: without --yes it only LISTS what would be deleted. Deleting a student also
deletes all their sessions, messages, indicators and decision-log rows (on delete cascade).
This cannot be undone.

Run from the backend/ folder (it uses the Supabase keys in your .env; it never prints them):

    python scripts/delete_test_students.py TEST AGENTDEMO          # list codes starting with TEST or AGENTDEMO
    python scripts/delete_test_students.py --exact P001 P002       # list exactly these codes
    python scripts/delete_test_students.py TEST AGENTDEMO --yes    # really delete them
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the backend folder

from app import db  # noqa: E402


def find(prefixes, exact):
    """The students to delete: [{"id", "anon_code"}], matched by code prefix or exact code."""
    rows = db._get_client().table("students").select("id, anon_code").order("anon_code").execute().data or []
    chosen = []
    for row in rows:
        code = row["anon_code"]
        if code in exact or any(code.upper().startswith(p.upper()) for p in prefixes):
            chosen.append(row)
    return chosen


def main():
    parser = argparse.ArgumentParser(description="Delete CogniGuide test accounts (lists only, unless --yes).")
    parser.add_argument("prefixes", nargs="*", help="delete codes that START with these (for example TEST)")
    parser.add_argument("--exact", nargs="*", default=[], help="delete exactly these codes")
    parser.add_argument("--yes", action="store_true", help="really delete (without it: only list)")
    args = parser.parse_args()

    if not args.prefixes and not args.exact:
        parser.error("say which codes: a prefix like TEST, or --exact P001 P002")
    if any(len(p) < 3 for p in args.prefixes):
        parser.error("prefixes must be at least 3 characters, so a typo cannot match everyone")
    if not db.is_configured():
        sys.exit("Supabase is not set up in .env.")

    students = find(args.prefixes, set(args.exact))
    if not students:
        print("No matching students.")
        return
    print(f"{len(students)} student(s):")
    for row in students:
        print("  ", row["anon_code"])

    if not args.yes:
        print("\nNothing deleted. Add --yes to delete these students and ALL their data.")
        return
    client = db._get_client()
    for row in students:
        client.table("students").delete().eq("id", row["id"]).execute()
    print(f"\nDeleted {len(students)} student(s) and their data.")


if __name__ == "__main__":
    main()
