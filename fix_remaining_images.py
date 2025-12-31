#!/usr/bin/env python3
"""
Script to fix remaining image paths in bootcamp markdown files.
"""

import os
import re

# 手动修复特定文件
FIXES = [
    # (filepath, old_pattern, new_pattern)
    ("_bootcamp/05-Other-simulators/01-sst.md", "01-sst/", "/bootcamp/05-Other-simulators/01-sst/"),
]


def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))

    for filepath, old_pattern, new_pattern in FIXES:
        full_path = os.path.join(base_dir, filepath)
        if not os.path.exists(full_path):
            print(f"File not found: {full_path}")
            continue

        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()

        if old_pattern in content:
            new_content = content.replace(old_pattern, new_pattern)
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed: {filepath}")
        else:
            print(f"Pattern not found in: {filepath}")


if __name__ == "__main__":
    main()
