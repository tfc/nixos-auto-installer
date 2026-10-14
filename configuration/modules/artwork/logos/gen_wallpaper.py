#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
"""Generate tiling-wallpaper.svg: a -35deg checkerboard of the applicative.systems
and NixCademy logos covering a 4K page. Run it from anywhere:

    ./gen_wallpaper.py

It reads the cleaned logo SVGs sitting next to this script and (re)writes
tiling-wallpaper.svg in the same folder. Colours stay parametrised via the
two-line <style> block at the top of the output (.bg and .logo)."""

import os
import xml.etree.ElementTree as ET

# operate relative to this script's directory, regardless of cwd
os.chdir(os.path.dirname(os.path.abspath(__file__)))

SVG = '{http://www.w3.org/2000/svg}'

def all_paths(path_file):
    """All <path> elements in document order: (d, fill-rule)."""
    root = ET.parse(path_file).getroot()
    return [(p.get('d'), p.get('fill-rule')) for p in root.iter(SVG + 'path')]

# Full logos (every group kept, not just the alignment-reference groups)
A_paths = all_paths('applicative_systems_Logo.svg')      # icon + APPLICATIVE + systems
B_paths = all_paths('NixCademy_vertical_white.svg')       # snowflake + NIXCADEMY + EXPERT EDUCATION

# Full-logo bounding boxes and alignment-reference groups (from Inkscape --query-all)
A_VB   = (35, 37.8, 667, 434.6)     # full applicative logo  (x y w h)
A_REF_H = 332.4                     # height of g13 (icon) within that box; its top == logo top
B_VB   = (0, 0, 127.55, 101.32424)  # full NixCademy vertical logo
B_REF_H = 72.0                     # top (snowflake, y=0) -> bottom of NIXCADEMY wordmark,
                                    # excluding the EXPERT EDUCATION subtitle below it

# --- page & layout parameters
PAGE_W, PAGE_H = 3840, 2160
CX, CY = PAGE_W / 2, PAGE_H / 2
ANGLE = -35
HREF = 150.0                        # rendered height of g13 and of g8+g34 (equal => "same height")
GAP_X, GAP_Y = 50.0, 50.0 #130.0, 120.0
HALF = 2600                         # half-extent of grid coverage around the page centre

# scale each full logo so its reference group renders to HREF tall
scaleA = HREF / A_REF_H
scaleB = HREF / B_REF_H
UwA, UhA = A_VB[2] * scaleA, A_VB[3] * scaleA   # full applicative rendered size
UwB, UhB = B_VB[2] * scaleB, B_VB[3] * scaleB   # full NixCademy rendered size

CW = max(UwA, UwB) + GAP_X
RH = max(UhA, UhB) + GAP_Y
top_margin = (RH - max(UhA, UhB)) / 2           # logos placed top-aligned (refs touch logo tops)

def r(v):
    return round(v, 2)

def symbol(sid, vb, paths):
    out = ['  <symbol id="%s" viewBox="%s %s %s %s">' % ((sid,) + vb)]
    for d, fr in paths:
        out.append('    <path%s d="%s"/>' % (' fill-rule="%s"' % fr if fr else '', d))
    out.append('  </symbol>')
    return out

uses = []
start = -HALF
ncol = int((2 * HALF) // CW) + 1
nrow = int((2 * HALF) // RH) + 1
for j in range(nrow + 1):
    cy = CY + start + j * RH
    for i in range(ncol + 1):
        cx = CX + start + i * CW
        if (i + j) % 2 == 0:
            ref, w, h = '#markA', UwA, UhA
        else:
            ref, w, h = '#markB', UwB, UhB
        x = cx + (CW - w) / 2          # centre in column
        y = cy + top_margin            # same top for every cell => reference tops aligned
        uses.append('    <use href="%s" x="%s" y="%s" width="%s" height="%s"/>'
                    % (ref, r(x), r(y), r(w), r(h)))

svg = []
svg.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
           % (PAGE_W, PAGE_H, PAGE_W, PAGE_H))
svg.append('  <style>')
svg.append('    .bg   { fill:#ffffff }')
svg.append('    .logo { fill:#000000 }')
svg.append('  </style>')
svg.append('  <defs>')
svg += symbol('markA', A_VB, A_paths)
svg += symbol('markB', B_VB, B_paths)
svg.append('  </defs>')
svg.append('  <rect class="bg" x="0" y="0" width="%d" height="%d"/>' % (PAGE_W, PAGE_H))
svg.append('  <g class="logo" transform="rotate(%d %g %g)">' % (ANGLE, CX, CY))
svg += uses
svg.append('  </g>')
svg.append('</svg>')

open('tiling-wallpaper.svg', 'w').write('\n'.join(svg) + '\n')
print('cells:', (ncol + 1) * (nrow + 1),
      '| applicative %.0fx%.0f  nixcademy %.0fx%.0f' % (UwA, UhA, UwB, UhB),
      '| cell %.0fx%.0f' % (CW, RH))
