#!/usr/bin/env python3
"""Placeholders for the R2.5 rework: two-song S1 track, chase drums/heartbeat, face slam,
face walls and planks. Like generate_resources.py it never overwrites a PNG or anything in data/.
Existing files are kept unless --refresh is passed (mus_song is always rebuilt from song.json)."""
from pathlib import Path
import argparse, json, math, random, wave, struct
ROOT = Path(__file__).resolve().parents[1]
B = json.loads((ROOT/'data/balance.json').read_text())
SONG = json.loads((ROOT/'data/song.json').read_text())
ap = argparse.ArgumentParser(); ap.add_argument('--refresh', action='store_true'); ARGS = ap.parse_args()
SR = B['audio']['sample_rate']; BAR = B['bar_s']

def svg(key, w, h, body):
    dest = ROOT/'art'/(key+'.svg')
    if (ROOT/'art'/(key+'.png')).exists() or (dest.exists() and not ARGS.refresh): return
    defs = '<defs><pattern id="hatch" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M-3 10L10-3M2 13L13 2" stroke="#0e120e" opacity=".35" stroke-width="1.2"/></pattern></defs>'
    dest.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{defs}{body}</svg>\n')

def wav(key, samples, force=False):
    dest = ROOT/'audio'/(key+'.wav')
    if dest.exists() and not (ARGS.refresh or force): return
    peak = max(1e-6, max(abs(v) for v in samples))
    scale = min(1.0, .92/peak)
    with wave.open(str(dest), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(SR)
        out.writeframes(b''.join(struct.pack('<h', int(v*scale*32767)) for v in samples))

def face(cx, cy, rx, ry, turn=0, mouth=1.0, skin='#cfd0b2'):
    # A stretched face: eyes too wide, mouth opened too far. Original drawing.
    return (f'<g transform="rotate({turn} {cx} {cy})" stroke="#0f130f" stroke-width="{max(2,rx/22):.1f}">'
      f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{skin}"/>'
      f'<ellipse cx="{cx-rx*.38}" cy="{cy-ry*.25}" rx="{rx*.24}" ry="{ry*.2}" fill="#f2f0dc"/>'
      f'<ellipse cx="{cx+rx*.38}" cy="{cy-ry*.25}" rx="{rx*.24}" ry="{ry*.2}" fill="#f2f0dc"/>'
      f'<circle cx="{cx-rx*.38}" cy="{cy-ry*.25}" r="{rx*.05}" fill="#060806"/>'
      f'<circle cx="{cx+rx*.38}" cy="{cy-ry*.25}" r="{rx*.05}" fill="#060806"/>'
      f'<path d="M{cx-rx*.62} {cy-ry*.5}Q{cx-rx*.38} {cy-ry*.62} {cx-rx*.14} {cy-ry*.48}M{cx+rx*.14} {cy-ry*.48}Q{cx+rx*.38} {cy-ry*.62} {cx+rx*.62} {cy-ry*.5}" fill="none"/>'
      f'<ellipse cx="{cx}" cy="{cy+ry*.38}" rx="{rx*.22}" ry="{ry*.36*mouth}" fill="#080a08"/>'
      f'<path d="M{cx-rx*.18} {cy+ry*.2}L{cx-rx*.1} {cy+ry*.3}L{cx-rx*.02} {cy+ry*.2}L{cx+rx*.06} {cy+ry*.3}L{cx+rx*.14} {cy+ry*.2}" fill="none" stroke="#d9d6c0" stroke-width="{max(1.5,rx/40):.1f}"/>'
      f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#hatch)" stroke="none"/></g>')

rng = random.Random(4417)
# Face slam close-up.
body = '<rect width="1920" height="1080" fill="#050605"/>'
for i in range(26):
    body += face(rng.uniform(0,1920), rng.uniform(0,1080), rng.uniform(60,130), rng.uniform(90,190), rng.choice([0,180,-20,25,90]), 1.2, '#59604c')
body += '<rect width="1920" height="1080" fill="#050605" opacity=".55"/>'
body += face(960, 560, 560, 760, -4, 1.45, '#d8d8bc')
body += '<path d="M600 300L760 360M1320 300L1160 360M520 760Q960 1010 1400 760" fill="none" stroke="#5a1212" stroke-width="7" opacity=".7"/>'
svg('m1_face_closeup', 1920, 1080, body)
# Face wall obstacle: a column of packed faces.
body = '<path d="M30 760L18 520L42 300L20 90L60 0H300L338 120L318 360L346 560L328 760Z" fill="#4c5240" stroke="#0e120e" stroke-width="8"/>'
for row in range(6):
    for col in range(2):
        body += face(105+col*150+rng.uniform(-18,18), 70+row*120+rng.uniform(-14,14), rng.uniform(58,76), rng.uniform(70,92), rng.choice([0,0,180,-15,15]), 1.1)
svg('face_wall', 360, 760, body)
# Plank over a pit.
for real in (False, True):
    wood, ink, pit = (('#c9a978', '#4c3a26', '#2c3a33') if not real else ('#7a7660', '#121510', '#050705'))
    body = f'<rect y="30" width="800" height="110" fill="{pit}"/><rect y="12" width="800" height="34" rx="6" fill="{wood}" stroke="{ink}" stroke-width="5"/>'
    body += ''.join(f'<path d="M{x} 18Q{x+30} 30 {x+60} 20" fill="none" stroke="{ink}" stroke-width="2" opacity=".5"/>' for x in range(20, 780, 90))
    body += f'<path d="M0 46V140M800 46V140" stroke="{ink}" stroke-width="10"/>'
    if real: body += ''.join(f'<path d="M{x} 140Q{x+8} 100 {x+2} 70" stroke="#c9c8ad" stroke-width="5" fill="none" opacity=".6"/>' for x in range(40, 800, 70))
    svg('plank_' + ('real' if real else 'cute'), 800, 140, body)

# ---------- Audio ----------
NOTES = {'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11}
def freq(n): return 440*2**(((int(n[-1])+1)*12+NOTES[n[0]]-69)/12)
def tine(buf, start, dur, hz, gain, detune=0.0):
    for delay, level in ((0,1),(.16,.18),(.32,.07)):
        s0 = int((start+delay)*SR)
        for i in range(int(dur*SR)):
            j = s0+i
            if j >= len(buf): break
            t = i/SR
            env = min(1, t/.008)*math.exp(-t*4.4)*min(1, max(0, (dur-t)/.035))
            v = math.sin(math.tau*hz*t)+.32*math.sin(math.tau*hz*2.01*t)+.09*math.sin(math.tau*hz*3.97*t)
            if detune: v = .6*v + .6*math.sin(math.tau*hz*(1+detune)*t)
            buf[j] += gain*level*env*v
unit = SONG['unit_s']
total = sum(s[1] for l in SONG['lines'] for s in l['syllables'])
cut = None; cursor = 0
for l in SONG['lines']:
    for k, s in enumerate(l['syllables']):
        if l.get('cut_last') and k == len(l['syllables'])-1: cut = cursor*unit
        cursor += s[1]
length = (cut + SONG.get('cut_silence_s', 0)) if cut is not None else total*unit
song = [0.0]*round(length*SR); cursor = 0.0
for l in SONG['lines']:
    part = l.get('part', 'twinkle')
    for k, (text, units, note) in enumerate(l['syllables']):
        dur = units*unit
        if l.get('cut_last') and k == len(l['syllables'])-1: break
        if part == 'twinkle':
            tine(song, cursor, min(dur, 1.2), freq(note), .37)
        else:
            tine(song, cursor, min(dur, 1.2), freq(note), .3, .012 if part == 'dark' else .025)
            tine(song, cursor, min(dur, 1.0), freq(note)/2, .12)
        cursor += dur
# A low drone creeps in under the changed verse and the rosie.
dark_start = sum(s[1] for l in SONG['lines'] if l.get('part') == 'twinkle' for s in l['syllables'])*unit
for i in range(int(dark_start*SR), len(song)):
    t = i/SR - dark_start
    if cut is not None and i/SR >= cut: break
    song[i] += min(1, t/6)*.05*(math.sin(math.tau*55*t)+.5*math.sin(math.tau*58.3*t))
wav('mus_song', song, force=True)

loop = BAR*4; n = round(loop*SR); arng = random.Random(9)
def kick(buf, start, gain):
    for i in range(int(.35*SR)):
        j = int(start*SR)+i
        if j >= len(buf): break
        t = i/SR; buf[j] += gain*math.exp(-t*9)*math.sin(math.tau*(48+90*math.exp(-t*30))*t)
def noise(buf, start, dur, gain, smooth=.5):
    low = 0
    for i in range(int(dur*SR)):
        j = int(start*SR)+i
        if j >= len(buf): break
        t = i/SR; low = low*smooth+arng.uniform(-1,1)*(1-smooth)
        buf[j] += gain*low*math.exp(-t*(12/dur))
drums = [0.0]*n; beat = BAR/4
for bar in range(4):
    b0 = bar*BAR
    if bar % 2 == 0:   # shout bar: driving
        for k in range(4): kick(drums, b0+k*beat, .8)
        for k in (1, 3): noise(drums, b0+k*beat, .22, .5, .2)
        for k in range(8): noise(drums, b0+k*beat/2, .05, .12, .0)
    else:              # breathe bar: sparse
        kick(drums, b0, .6); noise(drums, b0+2*beat, .3, .18, .7)
wav('mus_drums', drums)
heart = [0.0]*round(BAR*SR)
for k in range(4):
    kick(heart, k*beat, .9); kick(heart, k*beat+.17, .55)
wav('mus_heart', heart)

def sweep(dur, f0, f1, gain, vib=0):
    out = []; ph = 0
    for i in range(int(dur*SR)):
        t = i/SR; f = f0+(f1-f0)*t/dur + vib*math.sin(t*40)
        ph += math.tau*f/SR; out.append(gain*math.sin(ph))
    return out
slam = [0.0]*round(1.6*SR)
kick(slam, 0, 1.0); noise(slam, 0, 1.2, .9, .3)
for i, v in enumerate(sweep(1.4, 900, 2600, .45, 120)): slam[i] += v*min(1, i/400)*(1-i/(1.4*SR))
for i, v in enumerate(sweep(1.4, 1350, 3100, .25, 160)): slam[i] += v*min(1, i/400)*(1-i/(1.4*SR))
wav('sfx_face_slam', slam)
growl = [0.0]*round(.7*SR); low = 0
for i in range(len(growl)):
    t = i/SR; low = low*.95+arng.uniform(-1,1)*.05
    growl[i] = (low*3+.3*math.sin(math.tau*(62+6*math.sin(t*30))*t))*math.sin(math.pi*t/.7)
wav('sfx_m1_growl', growl)
crack = [0.0]*round(.8*SR); noise(crack, 0, .8, 1.0, .1); kick(crack, 0, .8); noise(crack, .12, .4, .6, .4)
wav('sfx_wall_break', crack)
print('R2.5 placeholders ready.')
