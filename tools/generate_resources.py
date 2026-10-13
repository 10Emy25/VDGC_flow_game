#!/usr/bin/env python3
"""Generate only R1 SVG/WAV placeholders. Never modify data or existing PNGs.
Existing SVG/WAV files are preserved unless --refresh-placeholders is passed.
"""
from pathlib import Path
import argparse, json, math, random, wave, struct
ROOT = Path(__file__).resolve().parents[1]
BALANCE = json.loads((ROOT / 'data/balance.json').read_text())
SONG = json.loads((ROOT / 'data/song.json').read_text())
REFRESH = argparse.ArgumentParser()
REFRESH.add_argument('--refresh-placeholders', action='store_true')
ARGS = REFRESH.parse_args()


def svg(key, width, height, body):
    dest = ROOT / 'art' / (key + '.svg')
    if (ROOT / 'art' / (key + '.png')).exists() or (dest.exists() and not ARGS.refresh_placeholders):
        return
    defs = '''<defs>
      <linearGradient id="sand" x2="0.2" y2="1"><stop stop-color="#e8d8ae"/><stop offset="1" stop-color="#baa57b"/></linearGradient>
      <linearGradient id="wood" x2="0.8" y2="1"><stop stop-color="#a98561"/><stop offset="1" stop-color="#665343"/></linearGradient>
      <linearGradient id="sky" x2="0" y2="1"><stop stop-color="#c2dddf"/><stop offset="1" stop-color="#fff2db"/></linearGradient>
      <pattern id="hatch" width="12" height="12" patternUnits="userSpaceOnUse"><path d="M-3 12L12-3M3 15L15 3" stroke="#172322" opacity=".2" stroke-width="1"/></pattern>
      <pattern id="grain" width="17" height="19" patternUnits="userSpaceOnUse"><circle cx="3" cy="5" r="1" fill="#51472e" opacity=".16"/><circle cx="12" cy="14" r=".8" fill="#fff5d7" opacity=".65"/></pattern>
    </defs>'''
    dest.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{defs}{body}</svg>\n')


def person(frame=0, running=False, real=False):
    ink = '#263b3d' if not real else '#171c19'
    dress = '#85b7ac' if not real else '#c1c7a4'
    skin = '#f4dcc3' if not real else '#e6e3ca'
    swing = math.sin(frame * math.tau) * (34 if running else 12)
    return f'''<g stroke="{ink}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">
      <ellipse cx="154" cy="342" rx="76" ry="11" fill="{ink}" opacity=".12" stroke="none"/>
      <path d="M135 251L{115-swing:.1f} 297L{98-swing:.1f} 333M169 251L{187+swing:.1f} 297L{213+swing:.1f} 331" fill="none" stroke="{skin}" stroke-width="22"/>
      <path d="M{80-swing:.1f} 334L{112-swing:.1f} 334M{200+swing:.1f} 334L{231+swing:.1f} 334" stroke-width="17"/>
      <path d="M133 149Q104 188 91 251Q149 277 205 251L172 151Z" fill="{dress}"/>
      <path d="M111 203Q140 220 184 206L204 252Q141 278 91 252Z" fill="{ink}" opacity=".13" stroke="none"/>
      <path d="M119 167L{88-swing*.6:.1f} 207L{69-swing:.1f} 189M175 167L{207+swing*.6:.1f} 194L{228+swing:.1f} 161" fill="none" stroke="{skin}" stroke-width="17"/>
      <path d="M111 97Q76 105 75 164Q99 161 113 142" fill="{ink}"/>
      <ellipse cx="147" cy="103" rx="45" ry="50" fill="{skin}"/>
      <path d="M102 96Q90 52 137 47Q183 40 197 100L179 94L162 67Q142 102 102 96" fill="{ink}"/>
      <path d="M168 107L172 118M153 136Q164 142 174 135" fill="none" stroke-width="4"/>
      <path d="M128 162L147 187L172 161" fill="#fff1da" stroke-width="4"/>
      <circle cx="100" cy="101" r="11" fill="#d29265" stroke-width="3"/>
      <path d="M119 60Q143 50 162 57" fill="none" stroke="#596d6b" stroke-width="4"/>
    </g>''' + ('<path d="M108 181L186 224M106 195L188 238M103 213L165 254" stroke="#232923" opacity=".4" stroke-width="2"/>' if real else '')


def flower(real=False, bud=False, seed=0):
    ink = '#3c5b49' if not real else '#20241c'
    petals = '#eac2c0' if not real else '#aab191'
    blossom = '<ellipse cx="78" cy="75" rx="22" ry="32" fill="#aac88f"/>' if bud else ''.join(f'<ellipse cx="80" cy="44" rx="22" ry="36" transform="rotate({n*60} 80 80)" fill="{petals}"/>' for n in range(6))
    return f'''<g stroke="{ink}" stroke-width="4" stroke-linejoin="round"><path d="M80 96Q{96 if real else 68} 135 80 194" fill="none" stroke-width="6"/>
      <path d="M79 160Q28 129 30 157Q44 177 79 178M81 146Q123 113 131 136Q119 157 81 161" fill="#8cb28a"/>{blossom}
      <circle cx="80" cy="79" r="21" fill="#e9bd67"/>
      <path d="M69 76L69 80M91 76L91 80M69 89Q80 {99 if not real else 83} 91 89" fill="none" stroke-width="3"/>
      <path d="M44 156L68 163M95 144L118 134" opacity=".4" stroke-width="2"/>
      </g>'''

svg('fallback',256,256,'<circle cx="128" cy="128" r="105" fill="#edddbf" stroke="#334e48" stroke-width="6"/><path d="M43 160Q125 65 213 160L201 200H58Z" fill="#91b5a2"/><circle cx="165" cy="90" r="24" fill="#e7b665"/><circle cx="128" cy="128" r="102" fill="url(#grain)"/>')
svg('clinic_bg',1920,1080,'''<rect width="1920" height="1080" fill="#deded0"/>
 <path d="M0 0H1920V250H0Z" fill="#cbd0c3"/><path d="M0 265H1920" stroke="#9ba99c" stroke-width="3"/>
 <rect x="140" y="52" width="430" height="140" rx="14" fill="#a5b8b0" stroke="#7c948a" stroke-width="6"/>
 <path d="M352 52V192M140 121H570" stroke="#dbe5d9" stroke-width="12"/>
 <ellipse cx="1650" cy="177" rx="90" ry="30" fill="#959e83"/>
 <path d="M1648 181Q1510 24 1575 60Q1620 74 1648 167M1650 177Q1767 20 1740 66Q1748 102 1650 165" fill="#859f83" stroke="#6d886d" stroke-width="6"/>
 <rect x="150" y="207" width="1620" height="672" rx="100" fill="#647468" opacity=".16"/>
 <rect x="140" y="188" width="1640" height="668" rx="96" fill="#c4baa0" stroke="#aaa18c" stroke-width="6"/>
 <path d="M190 799H1740" stroke="#9d947c" stroke-width="4"/>
 <path d="M198 266Q273 247 346 265M1570 672Q1645 689 1708 670" stroke="#e4d9bf" stroke-width="6"/>
 <rect x="190" y="390" width="125" height="203" rx="22" fill="#eee6d2" stroke="#a89e89" stroke-width="5"/>
 <ellipse cx="253" cy="440" rx="42" ry="19" fill="#a89e89"/><ellipse cx="253" cy="437" rx="32" ry="11" fill="#d5c3a3"/>
 <path d="M1590 459L1685 631" stroke="#6c8c83" stroke-width="16" stroke-linecap="round"/>
 <path d="M1625 456L1690 620" stroke="#e3dbc6" stroke-width="7" stroke-linecap="round"/>
 <rect width="1920" height="1080" fill="url(#grain)" opacity=".25"/>''')
svg('sandtray',1100,600,'''<rect x="8" y="14" width="1084" height="580" rx="45" fill="#433d32" opacity=".3"/>
 <rect x="3" y="2" width="1094" height="583" rx="38" fill="url(#wood)" stroke="#685542" stroke-width="5"/>
 <rect x="22" y="20" width="1056" height="532" rx="20" fill="#dccc9d" stroke="#4d4537" stroke-width="8"/>
 <path d="M45 566H1050M42 578H1015" stroke="#ba9874" stroke-width="3" opacity=".6"/>''')
svg('sand_layer',1070,530,'''<rect width="1070" height="530" rx="18" fill="url(#sand)"/>
 <path d="M65 130Q322 160 516 129T960 128M125 387Q363 365 539 398T1000 372" stroke="#f1e4c0" stroke-width="3" fill="none"/>
 <ellipse cx="540" cy="267" rx="98" ry="89" fill="#d4c294" opacity=".7"/>
 <path d="M452 266Q515 190 618 245" stroke="#f6e8c8" stroke-width="4" fill="none" opacity=".75"/>
 <rect width="1070" height="530" fill="url(#grain)"/>''')
svg('clinic_figure',160,220,'<g transform="translate(-5,-5) scale(.57)">'+person()+'</g>')
svg('buried_runner_doll',300,300,'<g transform="translate(20,0) rotate(-12 150 150) scale(.81)">'+person(.18,True)+'</g>')
for state in ('mina_idle','mina_walk','mina_jog','mina_run'):
    count = BALANCE['art_frames'][state]
    for real in (False,True):
        body=''.join(f'<g transform="translate({i*300},18)">{person(i/count,state!="mina_idle",real)}</g>' for i in range(count))
        svg(state+('_real' if real else '_cute'),300*count,360,body)
for real in (False,True):
    suffix = '_real' if real else '_cute'
    sky = '#b7bea1' if real else 'url(#sky)'
    hills = '#848b72' if real else '#bdd4b6'
    svg('run_bg_far'+suffix,1920,1080,f'''<rect width="1920" height="1080" fill="{sky}"/>
      <circle cx="1280" cy="320" r="98" fill="{'#e1dfbc' if real else '#fff3ca'}"/>
      <path d="M0 640Q280 470 520 640Q820 370 1130 626Q1550 455 1920 640V1080H0Z" fill="{hills}"/>
      <path d="M0 650Q300 490 520 650Q850 410 1130 650Q1550 480 1920 650" fill="none" stroke="{'#525b44' if real else '#a9c6a4'}" stroke-width="5"/>
      <rect width="1920" height="1080" fill="url(#hatch)" opacity="{.35 if real else .04}"/>''')
    svg('run_bg_mid'+suffix,1920,1080,f'''<path d="M0 770Q180 650 400 766Q755 553 1055 742Q1320 660 1560 752Q1740 690 1920 770V1080H0Z" fill="{'#626f57' if real else '#a7c8b1'}"/>
      <path d="M0 820Q500 771 940 822T1920 820V1080H0Z" fill="{'#7c8463' if real else '#c8d9ad'}"/>
      <path d="M0 806Q500 757 940 808T1920 806" fill="none" stroke="{'#313b2c' if real else '#f1e5b8'}" stroke-width="7"/>
      <path d="M330 625Q358 543 395 592Q369 651 330 625M1400 590Q1424 546 1460 571Q1449 607 1400 590" fill="{'#565942' if real else '#e9c4b4'}" opacity=".8"/>
      <path d="M340 612L379 603M1413 579L1448 576" stroke="#5f7869" stroke-width="3"/>''')
    butterflies=''.join(f'<g transform="translate({x},{y})" stroke="{("#363d2c" if real else "#729580")}" stroke-width="3"><path d="M0 0Q-47-49-36-6Q-16 20 0 0M0 0Q38-42 40-8Q24 22 0 0" fill="{("#b3b799" if real else "#eac8b5")}"/><path d="M-28-14L-8 0M26-12L8 0" stroke="#f6e5cb"/><path d="M0-8V9M0-7L-6-16M0-7L6-16"/></g>' for x,y in ((410,510),(1530,540)))
    near=''.join(f'<g transform="translate({i*240-35},682) scale(.48)">{flower(real,False,i)}</g>' for i in range(9))
    svg('run_bg_near'+suffix,1920,1080,near+butterflies)
    svg('run_ground'+suffix,512,220,f'''<path d="M0 8Q120 0 256 8T512 8V220H0Z" fill="{'#808569' if real else '#e5d3a1'}"/>
      <path d="M0 16Q120 8 256 16T512 16" stroke="{'#252e23' if real else '#6c947c'}" stroke-width="14" fill="none"/>
      <path d="M0 60Q150 50 256 63T512 60M0 130Q150 118 256 132T512 130" stroke="{'#4c563e' if real else '#c8b689'}" stroke-width="3" fill="none"/>
      <rect y="16" width="512" height="204" fill="url(#grain)"/>{'<rect width="512" height="220" fill="url(#hatch)"/>' if real else ''}''')
    for bud in (False,True):
        svg(('flower_bud' if bud else 'flower_open')+suffix,160,200,flower(real,bud))
    svg('flower_bridge'+suffix,960,240,f'''<path d="M0 108Q240 61 480 103T960 108L960 150Q720 165 480 143T0 150Z" fill="{'#747d57' if real else '#b5cb93'}" stroke="{'#252d22' if real else '#567e60'}" stroke-width="8"/>
      <path d="M15 124Q240 89 480 124T945 124" fill="none" stroke="{'#bfc29b' if real else '#eaf0bd'}" stroke-width="6"/>
      {''.join(f'<g transform="translate({x},23) scale(.4)">{flower(real)}</g>' for x in range(15,930,100))}''')
# Transparent middle leaves the code-drawn meter visible.
svg('ui_voice_meter',520,70,'<rect x="2" y="2" width="516" height="66" rx="22" fill="#fff7e5" fill-opacity=".45" stroke="#425e53" stroke-width="3"/><path d="M13 57Q260 66 507 57" fill="none" stroke="#d4c6a4" stroke-width="2"/>')
svg('ui_voice_marker',36,70,'<path d="M18 3L29 17H7Z" fill="#e9ad46" stroke="#425e53" stroke-width="2"/><path d="M18 18V64" stroke="#425e53" stroke-width="3"/>')
svg('ui_lyrics_bar',1400,130,'<rect x="2" y="2" width="1396" height="126" rx="30" fill="#fff7e5" fill-opacity=".88" stroke="#759986" stroke-width="3"/><path d="M25 111Q700 128 1375 111" fill="none" stroke="#d9c79e" stroke-width="2"/>')
svg('ui_subtitle',1400,100,'<rect x="3" y="3" width="1394" height="94" rx="30" fill="#243c38" fill-opacity=".94" stroke="#90a996" stroke-width="2"/><path d="M26 86Q700 98 1374 86" fill="none" stroke="#476257" stroke-width="2"/>')
svg('ui_panel',970,790,'<rect x="9" y="14" width="952" height="768" rx="40" fill="#112c29" fill-opacity=".25"/><rect x="3" y="3" width="952" height="768" rx="36" fill="#fff7e5" stroke="#759986" stroke-width="4"/><rect x="18" y="18" width="922" height="736" rx="25" fill="none" stroke="#d9c7a5" stroke-width="2"/>')
svg('ui_panel_wide',1200,570,'<rect x="9" y="14" width="1180" height="550" rx="40" fill="#112c29" fill-opacity=".25"/><rect x="3" y="3" width="1180" height="550" rx="36" fill="#fff7e5" stroke="#759986" stroke-width="4"/><rect x="18" y="18" width="1150" height="520" rx="25" fill="none" stroke="#d9c7a5" stroke-width="2"/>')
rng=random.Random(127)
for key in ('tex_grain','tex_paper','tex_hatch'):
    if key=='tex_hatch':
        body='<rect width="512" height="512" fill="#eee9d0"/><rect width="512" height="512" fill="url(#hatch)"/>'
    else:
        body='<rect width="512" height="512" fill="#c7c5b6"/>'
        body+=''.join(f'<circle cx="{rng.randrange(512)}" cy="{rng.randrange(512)}" r="{rng.uniform(.3,1.8):.2f}" fill="{rng.choice(["#888c7e","#f8f1de"])}" opacity=".5"/>' for _ in range(2200))
    svg(key,512,512,body)

# Original synthesis only. Music is derived from song.json; duration is exactly its units.
SR=BALANCE['audio']['sample_rate']
def wav(key, samples):
    dest=ROOT/'audio'/(key+'.wav')
    if dest.exists() and not ARGS.refresh_placeholders:
        return
    with wave.open(str(dest),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(SR)
        out.writeframes(b''.join(struct.pack('<h',int(max(-.95,min(.95,v))*32767)) for v in samples))


def tone(samples, start, duration, hz, gain):
    # A struck music-box tine, with quiet delayed copies for a small room.
    for delay,level in ((0,1),(.16,.18),(.32,.07)):
        for i in range(int(duration*SR)):
            j=int((start+delay)*SR)+i
            if j>=len(samples):break
            t=i/SR
            env=min(1,t/.008)*math.exp(-t*4.4)*min(1,max(0,(duration-t)/.035))
            samples[j]+=gain*level*env*(math.sin(math.tau*hz*t)+.32*math.sin(math.tau*hz*2.01*t)+.09*math.sin(math.tau*hz*3.97*t))
notes={'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11}
def frequency(note):
    midi=(int(note[-1])+1)*12+notes[note[0]]
    return 440*2**((midi-69)/12)
duration=sum(s[1] for line in SONG['lines'] for s in line['syllables'])*SONG['unit_s']
melody=[0.0]*round(duration*SR);cursor=0
for line in SONG['lines']:
    for text,length,note in line['syllables']:
        length*=SONG['unit_s'];tone(melody,cursor,min(length,1.2),frequency(note),.37);cursor+=length
wav('mus_song',melody)
loop_s=BALANCE['bar_s']*4
for key in ('mus_pad','amb_clinic'):
    frequencies=(130.833333333,196.25,261.666666667) if key=='mus_pad' else (54.583333333,109.166666667,163.75)
    # Frequencies rounded to whole cycles per loop; endpoint and modulation are continuous.
    frequencies=[round(f*loop_s)/loop_s for f in frequencies]
    samples=[]
    for i in range(round(loop_s*SR)):
        t=i/SR
        samples.append(sum(math.sin(math.tau*f*t+index*.6)*(.11/(index+1)) for index,f in enumerate(frequencies))*(.85+.15*math.sin(math.tau*t/loop_s)))
    wav(key,samples)
clock=[0.0]*round(BALANCE['bar_s']*SR)
for start in (0,.6,1.2,1.8):tone(clock,start,.15,890,.22)
wav('amb_clock',clock)
for key in ('sfx_bloom','sfx_bridge'):
    samples=[0.0]*round((1.5 if key=='sfx_bloom' else 2.4)*SR)
    for start,hz in ((0,523.25),(.1,659.25),(.2,783.99)):
        tone(samples,start,1.1,hz,.15)
    wav(key,samples)
for key,duration in (('sfx_sand',.35),('sfx_blur_in',BALANCE['sand']['transition_s'])):
    samples=[];low=0
    for i in range(round(duration*SR)):
        t=i/SR;low=low*.88+rng.uniform(-1,1)*.12
        env=math.sin(math.pi*t/duration)**2
        if key=='sfx_blur_in':low+=.18*math.sin(math.tau*(150*t+55*t*t))
        samples.append(low*env*.55)
    wav(key,samples)
print('R1 placeholder resources ready (data and PNGs untouched).')
