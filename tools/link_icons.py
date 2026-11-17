#!/usr/bin/env python3
"""Pasang assets/icons/<nama>.png ke data/items/<nama>.tres (field `icon`). Aman dijalankan ulang."""
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..")
for fn in sorted(os.listdir(os.path.join(ROOT, "data", "items"))):
    if not fn.endswith(".tres"):
        continue
    name = fn[:-5]
    if not os.path.exists(os.path.join(ROOT, "assets", "icons", name + ".png")):
        continue
    p = os.path.join(ROOT, "data", "items", fn)
    s = open(p).read()
    if 'id="icon"' in s:
        continue
    s = s.replace('[ext_resource type="Script"', '[ext_resource type="Texture2D" path="res://assets/icons/%s.png" id="icon"]\n[ext_resource type="Script"' % name, 1)
    s = re.sub(r"load_steps=(\d+)", lambda m: "load_steps=%d" % (int(m.group(1)) + 1), s, 1)
    s = s.rstrip("\n") + '\nicon = ExtResource("icon")\n'
    open(p, "w").write(s)
    print("ikon terpasang:", name)
