#!/usr/bin/env python3
"""Generate shipped R1/R2 SVG/WAV placeholders. Never modify data or existing PNGs.
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
# R2 silhouettes; all existing R1 files remain untouched by default.
for real in (False,True):
    suffix='_real' if real else '_cute'
    ink='#20251e' if real else '#3c6154'
    wood='#777960' if real else '#bcad8d'
    for state in ('mina_crouch','mina_caught'):
        count=BALANCE['art_frames'][state]
        body=''
        for i in range(count):
            transform='translate(48,137) scale(.7,.65)' if state=='mina_crouch' else f'translate(0,18) rotate({math.sin(i/count*math.tau)*12:.1f} 150 300)'
            body+=f'<g transform="translate({i*300},0)"><g transform="{transform}">{person(i/count,False,real)}</g></g>'
        svg(state+suffix,count*300,360,body)
    svg('cover_flower_big'+suffix,420,520,f'<g transform="translate(2,0) scale(2.6)">{flower(real)}</g>')
    svg('cover_desk'+suffix,420,520,f'''<g stroke="{ink}" stroke-width="9" stroke-linejoin="round"><path d="M54 201L75 504H106L124 217M288 207L303 504H342L357 207" fill="{wood}"/><path d="M26 167L346 107L403 184L72 263Z" fill="{wood}"/><path d="M72 263L403 184V217L76 296Z" fill="{'#575d47' if real else '#8e8e6c'}"/><path d="M58 172L327 129L375 178L85 239Z" fill="{'#a2a488' if real else '#e1cfa5'}" stroke-width="4"/><path d="M149 158L227 149M95 215L271 178M128 216L307 177" fill="none" stroke-width="2" opacity=".45"/></g><path d="M60 188L350 136M84 263L354 204" stroke="#f5edcf" stroke-width="3" opacity=".35"/>''')
    svg('cover_locker'+suffix,420,520,f'''<g stroke="{ink}" stroke-width="8"><path d="M57 18L337 9L372 41V506H50Z" fill="{wood}"/><path d="M57 18L337 9V477L50 506Z" fill="{'#a5aa8d' if real else '#adc9b3'}"/><path d="M80 44L307 32V456L76 475Z" fill="none" stroke-width="4"/><path d="M108 83L266 75M108 101L266 93M108 119L266 111M112 393L270 381M112 411L270 399" fill="none" stroke-width="7"/><rect x="277" y="240" width="14" height="50" rx="4" fill="#d9dabd" stroke-width="3"/><path d="M98 191L224 68M98 218L240 77M182 345L275 252" fill="none" stroke-width="2" opacity=".25"/></g>''')
    svg('cover_bag'+suffix,420,520,f'''<g stroke="{ink}" stroke-width="8"><path d="M145 122Q148 34 223 35Q285 41 284 124" fill="none" stroke-width="22"/><path d="M94 103Q42 225 70 465Q220 520 366 462L354 161Q304 94 94 103Z" fill="{wood}"/><path d="M116 166Q236 123 322 180L316 287Q219 335 111 286Z" fill="{'#b8b99a' if real else '#d9b9ac'}"/><path d="M118 333L310 326L304 443L111 444Z" fill="none" stroke-width="5"/><path d="M87 164L85 417M337 196L345 417" stroke-width="4" opacity=".45"/></g>''')
    svg('gap_crack'+suffix,200,220,f'<path d="M0 4L73 0L85 32L123 6L200 3V220H0Z" fill="{ink}"/><path d="M5 36L45 71L16 146L51 211M195 30L154 104L188 138L151 211" fill="none" stroke="{wood}" stroke-width="6"/><path d="M60 50L80 101M129 99L151 174" stroke="#929981" stroke-width="3"/>')
    svg('prop_school_item'+suffix,200,200,f'''<g stroke="{ink}" stroke-width="5" stroke-linejoin="round"><path d="M25 33L156 18L178 161L39 181Z" fill="{wood}"/><path d="M45 48L143 36L162 145L53 164Z" fill="{'#ced0b2' if real else '#eee2c3'}"/><path d="M59 73L130 66M62 95L136 87M68 117L137 110" opacity=".35"/><path d="M152 39L169 30L193 166L177 169Z" fill="{'#8c2023' if real else '#ad806b'}"/></g>''')


def face(cx,cy,rx,ry,turn=0,blink=0):
    pupil=(4+blink)*math.cos(math.radians(turn))
    pupil_y=-(4+blink)*math.sin(math.radians(turn))
    return f'''<g transform="rotate({turn} {cx} {cy})" stroke="#181c16" stroke-width="4">
      <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#d2d3b6"/>
      <path d="M{cx-rx*.85} {cy}Q{cx-rx*.7} {cy+ry*.8} {cx} {cy+ry*.9}" fill="none" stroke="#8d9377" stroke-width="8"/>
      <ellipse cx="{cx-rx*.4}" cy="{cy-ry*.2}" rx="{rx*.26}" ry="{ry*.18}" fill="#efefd8"/>
      <ellipse cx="{cx+rx*.4}" cy="{cy-ry*.2}" rx="{rx*.26}" ry="{ry*.18}" fill="#efefd8"/>
      <circle cx="{cx-rx*.4+pupil}" cy="{cy-ry*.2+pupil_y}" r="{rx*.1}" fill="#101713"/>
      <circle cx="{cx+rx*.4+pupil}" cy="{cy-ry*.2+pupil_y}" r="{rx*.1}" fill="#101713"/>
      <ellipse cx="{cx}" cy="{cy+ry*.4}" rx="{rx*.28}" ry="{ry*.42}" fill="#101713"/>
      <path d="M{cx-rx*.16} {cy+ry*.03}L{cx+rx*.16} {cy+ry*.03}M{cx-rx*.15} {cy+ry*.72}L{cx+rx*.15} {cy+ry*.72}" stroke="#e8e5d1" stroke-width="5"/>
      <path d="M{cx} {cy-ry*.25}L{cx-rx*.14} {cy+ry*.08}L{cx+rx*.1} {cy+ry*.11}" fill="none" stroke-width="2"/>
      <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#hatch)"/>
    </g>'''
wall_count=BALANCE['art_frames']['m1_wall']; wall_body=''
for frame in range(wall_count):
    monster_rng=random.Random(863)
    body='<path d="M0 0H770L834 74L813 144L864 250L826 364L877 489L836 604L890 754L863 907L900 1080H0Z" fill="#737b61" stroke="#171e16" stroke-width="8"/>'
    for row in range(7):
        for col in range(5):
            body+=face(65+col*156+monster_rng.uniform(-25,25),65+row*155+monster_rng.uniform(-25,25),monster_rng.uniform(52,88),monster_rng.uniform(75,123),monster_rng.choice([-24,17,0,180]),math.sin(frame/wall_count*math.tau))
    body+='<path d="M826 210L897 386L851 451M838 699L899 861L877 970" fill="none" stroke="#4b1819" stroke-width="5"/>'
    wall_body+=f'<g transform="translate({frame*900},0)">{body}</g>'
svg('m1_wall',900*wall_count,1080,wall_body)
svg('m1_face_peek',500,500,face(265,254,187,232,-12,1))
svg('m2_sky_crack',1920,440,'<path d="M0 0H1920V92L1690 118L1610 239L1455 163L1388 273L1171 196L960 377L761 202L550 281L423 156L277 229L202 102L0 121Z" fill="#1a2018"/><path d="M32 110L210 123L281 252L418 186L551 310L771 233L962 407L1180 220L1388 297L1450 190L1618 267L1701 144L1900 115" fill="none" stroke="#c1c7a6" stroke-width="5"/><path d="M112 90L820 158M1038 108L1840 62" stroke="#6e775a" stroke-width="3"/>')
for opened in (True,False):
    body='<path d="M10 148Q295-82 588 145Q304 391 10 148Z" fill="#d1d3b7" stroke="#161e16" stroke-width="10"/>'
    if opened:
        body+='<ellipse cx="302" cy="150" rx="99" ry="124" fill="#949f6d" stroke="#222b1b" stroke-width="7"/><ellipse cx="310" cy="151" rx="31" ry="93" fill="#101710"/><ellipse cx="338" cy="104" rx="12" ry="23" fill="#eee9ce"/><path d="M35 152L140 131L201 162M567 146L482 173L405 132" fill="none" stroke="#762e2d" stroke-width="3"/>'
    else:
        body='<path d="M10 146Q290 291 588 145Q304 211 10 146Z" fill="#9ca483" stroke="#192319" stroke-width="9"/><path d="M56 161Q298 266 555 160" fill="none" stroke="#d1d3b5" stroke-width="5"/>'
    body+='<path d="M65 91L135 123M86 79L161 118M413 116L500 83M439 130L527 106" stroke="#232b1e" stroke-width="2" opacity=".5"/>'
    svg('m2_eye_open' if opened else 'm2_eye_closed',600,300,body)
svg('m2_beam',300,900,'<defs><linearGradient id="beam" x2="0" y2="1"><stop stop-color="#d4d9a8" stop-opacity=".04"/><stop offset="1" stop-color="#d4d9a8" stop-opacity=".42"/></linearGradient></defs><path d="M136 0H164L297 900H3Z" fill="url(#beam)"/><ellipse cx="150" cy="885" rx="143" ry="13" fill="#e3e8bf" opacity=".48"/>')
svg('m2_hand',600,900,'''<g stroke="#1e251b" stroke-width="8" stroke-linejoin="round"><path d="M208 0H380L411 294Q470 403 465 517L542 599Q578 635 550 663L497 681L404 610L409 805Q407 874 370 875Q341 875 338 807L324 641L308 827Q307 899 269 889Q244 880 245 818L244 643L226 795Q216 867 184 854Q157 845 161 789L173 619L146 722Q127 788 92 764Q70 748 83 697L118 483Q131 421 179 380Z" fill="#c9ccb0"/><path d="M208 20L225 347L183 493L193 710M362 11L371 343L423 502" fill="none" stroke="#979e7c" stroke-width="26"/><path d="M205 399L351 490M194 426L368 527M185 462L378 561M213 533L320 572" stroke="#424c35" stroke-width="3"/><path d="M249 365L273 440L295 382" fill="none" stroke-width="4"/></g>''')
svg('safe_puddle',480,120,'<ellipse cx="240" cy="65" rx="238" ry="52" fill="#e5f0d9" opacity=".4"/><ellipse cx="240" cy="64" rx="209" ry="39" fill="#adbdb1" stroke="#6f8f83" stroke-width="4"/><ellipse cx="240" cy="64" rx="180" ry="29" fill="#dfe8da"/><path d="M154 42H323V86H154ZM239 42V86M154 65H323" fill="none" stroke="#8fa79a" stroke-width="6"/><path d="M43 78Q240 121 437 78" fill="none" stroke="#f4f4db" stroke-width="4"/>')
svg('light_door',500,800,'<path d="M250 2Q22 81 9 438V800H489V438Q479 74 250 2Z" fill="#e8eed7" opacity=".15"/><path d="M96 799V230Q251 32 407 230V799Z" fill="#f8f8e6" stroke="#c3cfaf" stroke-width="14"/><path d="M127 787V244Q250 101 375 244V787" fill="none" stroke="#fff" stroke-width="12"/><path d="M250 167V786" stroke="#e3ead1" stroke-width="4"/><circle cx="342" cy="518" r="10" fill="#cad6b8"/>')
svg('ui_beat_ring',500,500,'<circle cx="250" cy="250" r="233" fill="none" stroke="#eff3cb" stroke-width="8"/><circle cx="250" cy="250" r="212" fill="none" stroke="#b4c98d" stroke-width="3"/><path d="M250 3V45M250 455V497M3 250H45M455 250H497" stroke="#fff5da" stroke-width="8"/>')
# R2 threat/interaction audio; full layered music and scares stay in R3.
for key in ('amb_m1_breath','amb_m1_sand','amb_m2_light'):
    samples=[];noise=0;arng=random.Random(741)
    base=55 if key=='amb_m1_breath' else (82 if key=='amb_m1_sand' else 392)
    base=round(base*loop_s)/loop_s
    for i in range(round(loop_s*SR)):
        t=i/SR;noise=noise*.93+arng.uniform(-1,1)*.07
        envelope=math.sin(math.pi*t/loop_s)**2
        drone=.19*math.sin(math.tau*base*t)+.09*math.sin(math.tau*base*2*t)
        samples.append(drone*(.3+.7*envelope)+noise*envelope*.6)
    wav(key,samples)
for key,duration in (('sfx_m1_roar',1.2),('sfx_m2_crack',.8),('sfx_m2_slam',1),('sfx_m2_grab',1.2),('sfx_capture',1.2),('sfx_jump',.6),('sfx_stumble',1),('sfx_safe',1.2),('sfx_door',1),('sfx_beat_call',.6),('sfx_all_clear',1.2)):
    samples=[0.0]*round(duration*SR)
    if key in ('sfx_safe','sfx_door','sfx_beat_call','sfx_all_clear'):
        for start,hz in ((0,329.63),(.08,493.88),(.16,659.25)):
            tone(samples,start,duration-start,hz,.18)
    else:
        low=0;arng=random.Random(882)
        for i in range(len(samples)):
            t=i/SR;low=low*.85+arng.uniform(-1,1)*.15
            attack=min(1,t/.008);tail=(1-t/duration)**2
            base=45 if key in ('sfx_m2_slam','sfx_stumble') else 91
            samples[i]=(low*.6+.28*math.sin(math.tau*(base*t+8*math.sin(t*9))))*attack*tail
    wav(key,samples)
print('R2 threat and level resources ready.')
