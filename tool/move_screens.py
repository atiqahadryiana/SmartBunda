#!/usr/bin/env python3
"""Move flat screen files into role folders and rewrite package: import paths.

Phase 2 of the reorg. Run from repo root. Uses git mv for the moves, then
rewrites every `package:smartbunda/screens/<name>.dart` reference to its new
`package:smartbunda/screens/<folder>/<name>.dart` path across lib/ and test/.
"""
import os
import subprocess

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
SCREENS = os.path.join(ROOT, "lib", "screens")

# folder -> list of screen basenames (without .dart) to move into it
MOVES = {
    "admin": [
        "admin_overview_screen", "admin_screen", "system_admin_screen",
        "activity_log_screen", "content_management_screen",
    ],
    "auth": [
        "login_screen", "register_screen", "splash_screen",
        "change_password_screen", "get_started_screen", "landing_screen",
    ],
    "patient": [
        "patient_dashboard_screen", "profile_screen", "edit_profile_screen",
        "health_record_screen", "pre_pregnancy_assessment_screen",
        "summary_screen", "nutrition_facts_screen",
        "perinatal_care_manual_screen", "module_overview_screen",
        "role_modules_screen",
    ],
    "staff": [
        "staff_module_screen", "nurse_overview_screen", "nurse_monitoring_screen",
        "nutritionist_screen", "nutritionist_client_screen",
        "patient_profiles_screen", "monitoring_screen",
        "professional_profile_screen", "professional_availability_screen",
        "nutrition_plan_management_screen",
    ],
    "food": [
        "food_scan_screen", "food_analysis_result_screen", "food_catalog_screen",
        "food_logging_hub_screen", "food_picker_confirm_screen",
        "food_picker_modal", "log_screen", "hydration_screen",
    ],
    "appointments": [
        "appointments_screen", "appointment_calendar_screen",
    ],
    "reports": [
        "reports_screen",
    ],
    "shared": [
        "settings_screen", "education_screen", "feedback_screen",
    ],
}
# home_screen stays at screens/ root (cross-role nav shell).


def git_mv(src, dst):
    subprocess.run(["git", "mv", src, dst], cwd=ROOT, check=True)


def main():
    rewrites = {}  # old package path -> new package path
    for folder, names in MOVES.items():
        dest_dir = os.path.join(SCREENS, folder)
        os.makedirs(dest_dir, exist_ok=True)
        for name in names:
            src = os.path.join(SCREENS, name + ".dart")
            dst = os.path.join(dest_dir, name + ".dart")
            if not os.path.exists(src):
                print(f"  SKIP (missing): {name}.dart")
                continue
            git_mv(src, dst)
            old = f"package:smartbunda/screens/{name}.dart"
            new = f"package:smartbunda/screens/{folder}/{name}.dart"
            rewrites[old] = new

    # Rewrite references across lib/ and test/
    targets = []
    for base in ("lib", "test"):
        for r, _dirs, files in os.walk(os.path.join(ROOT, base)):
            if "oracleJdk-26" in r:
                continue
            for fn in files:
                if fn.endswith(".dart"):
                    targets.append(os.path.join(r, fn))

    files_changed = 0
    for path in targets:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        new_content = content
        for old, new in rewrites.items():
            if old in new_content:
                new_content = new_content.replace(old, new)
        if new_content != content:
            files_changed += 1
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(new_content)

    print(f"Moved {len(rewrites)} screens; rewrote refs in {files_changed} files.")


if __name__ == "__main__":
    main()
