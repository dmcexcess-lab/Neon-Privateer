#!/usr/bin/env python3
"""Generate an original neon geometric Android launcher icon. stdlib only."""
import math
import os
import struct
import zlib

SIZE = 432
OUTPUT = os.path.join(os.path.dirname(__file__), "..", "assets", "android", "icon.png")

def dist_segment(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px-ax)*dx + (py-ay)*dy) / max(1.0, dx*dx + dy*dy)))
    return math.hypot(px-(ax+t*dx), py-(ay+t*dy))

def inside(px, py, poly):
    yes = False
    j = len(poly)-1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > py) != (yj > py)) and px < (xj-xi)*(py-yi)/(yj-yi+1e-9)+xi:
            yes = not yes
        j = i
    return yes

ship = [(216,82),(254,175),(325,278),(247,252),(216,307),(185,252),(107,278),(178,175)]
rows = []
for y in range(SIZE):
    row = bytearray([0])
    for x in range(SIZE):
        dx, dy = x-216.0, y-216.0
        r = math.hypot(dx,dy)
        b = 7 + int(7 * max(0, 1-r/340))
        rgb = [b, b+5, b+16]
        # Concentric reactor glow.
        ring = abs(r-157)
        glow = max(0.0, 1.0-ring/8.0)
        rgb[0] += int(glow*9)
        rgb[1] += int(glow*82)
        rgb[2] += int(glow*95)
        if inside(x,y,ship):
            rgb = [17,53,85]
        edge = min(dist_segment(x,y,*ship[i],*ship[(i+1)%len(ship)]) for i in range(len(ship)))
        gl = max(0.0,1.0-edge/13)
        rgb[1] += int(gl*43)
        rgb[2] += int(gl*72)
        if edge < 2.5:
            rgb = [135,245,255]
        # Pink central engine and tail.
        core = math.hypot((x-216)*0.65, (y-268)*1.3)
        if core < 14:
            rgb = [248,92,243]
        elif core < 27:
            k = (27-core)/13
            rgb[0] += int(88*k)
            rgb[2] += int(110*k)
        row.extend(max(0,min(255,c)) for c in rgb)
        row.append(255)
    rows.append(bytes(row))

def chunk(code, body):
    return struct.pack(">I",len(body))+code+body+struct.pack(">I",zlib.crc32(code+body)&0xffffffff)

os.makedirs(os.path.dirname(OUTPUT),exist_ok=True)
with open(OUTPUT,"wb") as f:
    f.write(b"\x89PNG\r\n\x1a\n")
    f.write(chunk(b"IHDR",struct.pack(">2I5B",SIZE,SIZE,8,6,0,0,0)))
    f.write(chunk(b"IDAT",zlib.compress(b"".join(rows),8)))
    f.write(chunk(b"IEND",b""))
print("Generated launcher icon:",OUTPUT)
