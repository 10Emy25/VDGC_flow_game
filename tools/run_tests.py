#!/usr/bin/env python3
"""Import and run the R1/R2 headless suites with timeouts and error-log checking."""
from pathlib import Path
import os, struct, subprocess, zlib, sys
ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', '/Applications/Godot.app/Contents/MacOS/Godot')

def chunk(kind, data):
    return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)

def run(args):
    try:
        proc = subprocess.run([GODOT, '--headless', '--path', str(ROOT), *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ''
        print(output.decode(errors='replace') if isinstance(output, bytes) else output)
        raise
    print(proc.stdout)
    if proc.returncode or 'SCRIPT ERROR:' in proc.stdout or 'ERROR:' in proc.stdout:
        raise RuntimeError(f'Godot failed: {args} (exit {proc.returncode})')

fixture = ROOT/'art/r1_override_probe_cute'
paths=[fixture.with_suffix(ext) for ext in ('.png','.svg','.png.import','.svg.import')]
if any(path.exists() for path in paths):
    sys.exit('Refusing to overwrite an existing test fixture.')
try:
    fixture.with_suffix('.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><circle cx="128" cy="128" r="100" fill="#ffdd88"/></svg>')
    raw=b''.join(b'\0'+bytes([86,167,130,255])*94 for _ in range(37))
    png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',94,37,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b'')
    fixture.with_suffix('.png').write_bytes(png)
    run(['--editor','--import'])
    for suite in ('voice_test','run_model_test','r1_scene_test','intro_test','art_registry_test','monster_director_test','level_model_test','playthrough','r2_scene_test','tester_mode_test'):
        run(['--scene',f'res://tests/{suite}.tscn'])
    run(['--quit-after','20'])
    print('All R1/R2 suites and main-scene smoke check passed.')
finally:
    for path in paths:
        path.unlink(missing_ok=True)
