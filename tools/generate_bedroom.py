#!/usr/bin/env python3
"""Placeholders for the S0 bedroom opening: the dim bedroom, Mina's poses in bed, close-ups of her
hands and the pills, nightstand props, the narration box, night ambience, small foley and the
music-box intro that leads into the flower-path song.

Like the other generators it never overwrites a PNG or anything in data/. Existing SVG/WAV files are
kept unless --refresh is passed. mus_dream_intro is always rebuilt because it is derived from song.json
(the first two lines of the melody, an octave up), so the intro always matches the song that follows it.
Original drawings and synthesis; no third-party assets."""
from pathlib import Path
import argparse, json, math, random, struct, wave

ROOT = Path(__file__).resolve().parents[1]
B = json.loads((ROOT / 'data/balance.json').read_text())
SONG = json.loads((ROOT / 'data/song.json').read_text())
ap = argparse.ArgumentParser()
ap.add_argument('--refresh', action='store_true')
ARGS = ap.parse_args()
SR = B['audio']['sample_rate']
BAR = B['bar_s']

# Night palette: the same Mina as in the dream, under moonlight.
INK = '#111a20'
HAIR = '#1d2b2f'
SHINE = '#3d5154'
SKIN = '#d9c7b9'
PALM = '#e3d2c5'
CREASE = '#a8968a'
PJ = '#6e8e9a'
PJ_DARK = '#56717c'
COLLAR = '#c3cfd3'
TIE = '#b5764f'
BLANKET = '#4c6a6f'
BLANKET_DARK = '#3a5357'
FOLD = '#8e9cab'
STAR = '#9dbcb1'
SHEET = '#7d8b99'
PILLOW = '#9eabb8'
WOOD = '#3a3037'
WOOD_LIGHT = '#4b4047'

# Every pose shares this canvas so poses can be swapped without moving anything.
POSE_X, POSE_Y, POSE_W, POSE_H = B['intro']['bed_rect']


def svg(key, w, h, body, defs=''):
    dest = ROOT / 'art' / (key + '.svg')
    if (ROOT / 'art' / (key + '.png')).exists() or (dest.exists() and not ARGS.refresh):
        return
    dest.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{defs}</defs>{body}</svg>\n')


def pose(key, body, defs=''):
    svg(key, POSE_W, POSE_H, f'<g transform="translate({-POSE_X} {-POSE_Y})">{body}</g>', defs)


def limb(points, width, color):
    d = 'M' + ' L'.join(f'{x} {y}' for x, y in points)
    return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{width + 10}" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')


def hand(x, y, rx=16, ry=12, rot=0):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" transform="rotate({rot} {x} {y})" fill="{SKIN}" stroke="{INK}" stroke-width="4"/>'


def head(x, y, rot=0, eyes='open', flip=False, s=1.1, mouth='flat', ponytail=True):
    """Mina's head as in the dream art: ponytail and orange tie at the back, facing right."""
    sx = -s if flip else s
    eye = {
        'open': '<path d="M21 3L24 15" stroke-width="4.5"/>',
        'wide': f'<ellipse cx="23" cy="9" rx="3.8" ry="6.4" fill="{INK}" stroke="none"/>',
        'half': '<path d="M14 9H31" stroke-width="4"/><path d="M18 12Q23 16 28 12" fill="none" stroke-width="3"/>',
        'closed': '<path d="M13 8Q22 17 31 8" fill="none" stroke-width="4"/>',
    }[eyes]
    tired = '<path d="M13 24Q21 28 30 23" fill="none" stroke-width="2" opacity=".45"/>' if eyes in ('open', 'wide', 'half') else ''
    mouths = {'flat': '<path d="M9 35Q17 36 25 34" fill="none" stroke-width="3.5"/>', 'none': '', 'tight': '<path d="M11 35H23" stroke-width="3.5"/>'}
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({sx} {s})" stroke="{INK}" stroke-linecap="round" stroke-linejoin="round">'
            + (f'<path d="M-36 -6Q-74 2 -74 58Q-50 56 -34 38Z" fill="{HAIR}" stroke-width="5"/>' if ponytail else '')
            + f'<ellipse cx="0" cy="0" rx="45" ry="50" fill="{SKIN}" stroke-width="5"/>'
            f'<path d="M-45 -7Q-57 -51 -10 -56Q36 -63 50 -3L32 -9L15 -36Q-5 -1 -45 -7Z" fill="{HAIR}" stroke-width="5"/>'
            f'<path d="M-28 -43Q-4 -53 15 -46" fill="none" stroke="{SHINE}" stroke-width="4"/>'
            f'{eye}{tired}{mouths[mouth]}'
            + (f'<circle cx="-47" cy="-2" r="10" fill="{TIE}" stroke-width="3"/>' if ponytail else '') + '</g>')


def star_print(rng, x0, x1, y0, y1, count, size=5.0):
    out = ''
    for _ in range(count):
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        k = size * rng.uniform(.7, 1.2)
        out += f'<path d="M{x - k:.1f} {y:.1f}H{x + k:.1f}M{x:.1f} {y - k:.1f}V{y + k:.1f}" stroke="{STAR}" stroke-width="{k * .45:.1f}" stroke-linecap="round" opacity=".55"/>'
        out += f'<circle cx="{x + k * 2.2:.1f}" cy="{y + k * 1.6:.1f}" r="{k * .3:.1f}" fill="{STAR}" opacity=".4"/>'
    return out


def blanket(d, seed, folds, band=None):
    """A blanket shape with the star print clipped inside it, fold lines and an optional turned-down band."""
    rng = random.Random(seed)
    clip = f'bl{seed}'
    body = f'<path d="{d}" fill="{BLANKET}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
    body += f'<g clip-path="url(#{clip})">{star_print(rng, 500, 1320, 500, 800, 70)}'
    if band:
        body += f'<path d="{band}" fill="{FOLD}" stroke="{INK}" stroke-width="4"/>'
    body += ''.join(f'<path d="{f}" fill="none" stroke="{BLANKET_DARK}" stroke-width="5" stroke-linecap="round" opacity=".8"/>' for f in folds)
    body += f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/></g>'
    return body, f'<clipPath id="{clip}"><path d="{d}"/></clipPath>'


# ---------------- Bedroom ----------------
rng = random.Random(1717)
defs = '''<linearGradient id="wall" x2="0" y2="1"><stop stop-color="#192131"/><stop offset="1" stop-color="#242d3d"/></linearGradient>
<linearGradient id="floor" x2="0" y2="1"><stop stop-color="#231e24"/><stop offset="1" stop-color="#141117"/></linearGradient>
<linearGradient id="sky" x2="0" y2="1"><stop stop-color="#0c1630"/><stop offset="1" stop-color="#22355a"/></linearGradient>
<radialGradient id="moonglow"><stop stop-color="#e3edf4" stop-opacity=".5"/><stop offset="1" stop-color="#e3edf4" stop-opacity="0"/></radialGradient>
<linearGradient id="beam" x2="0" y2="1"><stop stop-color="#cfe0ee" stop-opacity=".2"/><stop offset="1" stop-color="#cfe0ee" stop-opacity=".03"/></linearGradient>
<radialGradient id="doorglow" cx=".5" cy="0" r="1"><stop stop-color="#f0b768" stop-opacity=".35"/><stop offset="1" stop-color="#f0b768" stop-opacity="0"/></radialGradient>
<pattern id="paper" width="64" height="64" patternUnits="userSpaceOnUse"><path d="M32 8L38 32L32 56L26 32Z" fill="#2c3648" opacity=".55"/><circle cx="0" cy="0" r="3" fill="#2c3648" opacity=".5"/><circle cx="64" cy="64" r="3" fill="#2c3648" opacity=".5"/></pattern>'''
b = '<rect width="1920" height="818" fill="url(#wall)"/><rect width="1920" height="800" fill="url(#paper)" opacity=".7"/>'
b += '<rect y="800" width="1920" height="20" fill="#141a24"/><rect y="818" width="1920" height="262" fill="url(#floor)"/>'
for y, o in ((848, .5), (892, .45), (948, .4), (1016, .35)):
    b += f'<path d="M0 {y}H1920" stroke="#0d0b0f" stroke-width="3" opacity="{o}"/>'
for k in range(14):
    y0 = [818, 848, 892, 948, 1016][k % 4]
    y1 = [848, 892, 948, 1016, 1080][k % 4]
    x = (k * 263 + 90) % 1900
    b += f'<path d="M{x} {y0}V{y1}" stroke="#0d0b0f" stroke-width="3" opacity=".35"/>'
# Door on the left with the hallway light leaking underneath.
b += f'<rect x="30" y="240" width="210" height="580" fill="#273042" stroke="{INK}" stroke-width="6"/>'
b += f'<rect x="58" y="276" width="154" height="230" rx="6" fill="none" stroke="#1a2130" stroke-width="5"/><rect x="58" y="540" width="154" height="240" rx="6" fill="none" stroke="#1a2130" stroke-width="5"/>'
b += f'<circle cx="214" cy="540" r="9" fill="#55606f" stroke="{INK}" stroke-width="3"/>'
b += '<ellipse cx="135" cy="822" rx="210" ry="70" fill="url(#doorglow)"/><rect x="34" y="812" width="202" height="7" fill="#e9b66c" opacity=".85"/>'
# Window and moon above the bed; moonlight falls across the blanket.
b += '<polygon points="806,522 1162,522 1340,800 640,800" fill="url(#beam)"/>'
b += f'<rect x="790" y="150" width="390" height="370" fill="url(#sky)" stroke="{INK}" stroke-width="8"/>'
b += '<circle cx="1072" cy="240" r="120" fill="url(#moonglow)"/><circle cx="1072" cy="240" r="44" fill="#e8eef0"/><circle cx="1089" cy="228" r="40" fill="#22355a" opacity=".12"/>'
for _ in range(14):
    x, y = rng.uniform(810, 1160), rng.uniform(170, 500)
    if math.hypot(x - 1072, y - 240) > 70:
        b += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rng.uniform(1.2, 2.6):.1f}" fill="#dfe8f0" opacity="{rng.uniform(.4, .9):.2f}"/>'
b += f'<path d="M985 150V520M790 335H1180" stroke="#2b3447" stroke-width="12"/><path d="M985 150V520M790 335H1180" stroke="{INK}" stroke-width="3" opacity=".6"/>'
b += f'<rect x="770" y="518" width="430" height="20" rx="4" fill="#2d3546" stroke="{INK}" stroke-width="4"/>'
b += f'<path d="M700 122H1270" stroke="#4a4f5c" stroke-width="10" stroke-linecap="round"/>'
for side, (x0, x1) in (('l', (712, 820)), ('r', (1150, 1258))):
    edge = x1 if side == 'l' else x0
    wave_ = ''.join(f' Q{edge + (14 if (i % 2) else -14)} {130 + i * 60 + 30} {edge} {130 + (i + 1) * 60}' for i in range(8))
    outer = x0 if side == 'l' else x1
    b += f'<path d="M{outer} 124L{edge} 124{wave_}L{outer} 610Z" fill="#2e3950" stroke="{INK}" stroke-width="5"/>'
    for f in range(3):
        fx = outer + (1 if side == 'l' else -1) * (24 + f * 26)
        b += f'<path d="M{fx} 140Q{fx + 6} 380 {fx - 4} 600" fill="none" stroke="#202a3e" stroke-width="5"/>'
# Wall clock (it is ten past three) and a calendar where every day is crossed out.
b += f'<circle cx="1330" cy="250" r="58" fill="#7f8894" stroke="{INK}" stroke-width="7"/><circle cx="1330" cy="250" r="47" fill="#9aa3ad"/>'
for k in range(12):
    a = k * math.tau / 12
    b += f'<path d="M{1330 + 40 * math.sin(a):.1f} {250 - 40 * math.cos(a):.1f}L{1330 + 46 * math.sin(a):.1f} {250 - 46 * math.cos(a):.1f}" stroke="{INK}" stroke-width="3"/>'
for ang, length, width in ((95, 26, 6), (60, 38, 4)):
    a = math.radians(ang)
    b += f'<path d="M1330 250L{1330 + length * math.sin(a):.1f} {250 - length * math.cos(a):.1f}" stroke="{INK}" stroke-width="{width}" stroke-linecap="round"/>'
b += f'<circle cx="1330" cy="250" r="5" fill="{INK}"/>'
b += f'<rect x="1440" y="200" width="180" height="230" rx="6" fill="#8d939b" stroke="{INK}" stroke-width="5"/><rect x="1440" y="200" width="180" height="46" rx="6" fill="#6a3c3e" stroke="{INK}" stroke-width="5"/>'
b += ''.join(f'<circle cx="{1470 + k * 40}" cy="200" r="6" fill="#3c4250" stroke="{INK}" stroke-width="2"/>' for k in range(4))
for row in range(5):
    for col in range(7):
        cx, cy = 1456 + col * 22 + 8, 262 + row * 32 + 10
        b += f'<rect x="{cx - 9}" y="{cy - 11}" width="18" height="22" fill="#a2a8b0" opacity=".6"/>'
        if row * 7 + col < 32:
            b += f'<path d="M{cx - 6} {cy - 7}L{cx + 6} {cy + 7}M{cx + 6} {cy - 7}L{cx - 6} {cy + 7}" stroke="#7d2f32" stroke-width="3" stroke-linecap="round" opacity=".85"/>'
# Desk, chair and a school bag that has not been opened in weeks.
b += f'<rect x="1648" y="636" width="300" height="24" fill="{WOOD_LIGHT}" stroke="{INK}" stroke-width="5"/><rect x="1660" y="660" width="20" height="160" fill="{WOOD}" stroke="{INK}" stroke-width="4"/>'
b += f'<rect x="1810" y="660" width="120" height="160" fill="{WOOD}" stroke="{INK}" stroke-width="5"/><path d="M1810 712H1930M1810 766H1930" stroke="{INK}" stroke-width="4"/><circle cx="1840" cy="686" r="5" fill="#6b5f66"/><circle cx="1840" cy="740" r="5" fill="#6b5f66"/>'
for k, (w, c) in enumerate(((150, '#5a4f63'), (130, '#4d5d63'), (140, '#6a5148'))):
    b += f'<rect x="{1690 + k * 8}" y="{614 - k * 20}" width="{w}" height="20" rx="3" fill="{c}" stroke="{INK}" stroke-width="4"/>'
b += f'<path d="M1700 560V820M1790 560V820" stroke="{WOOD}" stroke-width="16"/><path d="M1694 570H1796" stroke="{WOOD_LIGHT}" stroke-width="18" stroke-linecap="round"/><rect x="1690" y="704" width="114" height="18" fill="{WOOD_LIGHT}" stroke="{INK}" stroke-width="4"/>'
b += f'<path d="M1708 820Q1690 760 1716 724Q1760 700 1806 726Q1826 770 1812 820Z" fill="#3f5a6a" stroke="{INK}" stroke-width="5"/>'
b += f'<path d="M1718 748Q1762 734 1806 750" fill="none" stroke="{INK}" stroke-width="4"/><path d="M1726 726Q1740 690 1762 692Q1784 694 1794 724" fill="none" stroke="{INK}" stroke-width="5"/>'
b += '<circle cx="1792" cy="770" r="8" fill="#c99a8f" stroke="#111a20" stroke-width="3"/><path d="M1786 762L1782 748M1798 762L1802 748" stroke="#111a20" stroke-width="3" stroke-linecap="round"/>'
b += ''.join(f'<circle cx="{rng.uniform(1716, 1806):.0f}" cy="{rng.uniform(736, 812):.0f}" r="1.6" fill="#9aa6ab" opacity=".5"/>' for _ in range(24))
# Nightstand (its pills, glass, phone and book are separate props).
b += f'<rect x="206" y="684" width="248" height="24" rx="4" fill="{WOOD_LIGHT}" stroke="{INK}" stroke-width="5"/><rect x="222" y="708" width="216" height="112" fill="{WOOD}" stroke="{INK}" stroke-width="5"/>'
b += f'<rect x="240" y="726" width="180" height="40" rx="4" fill="none" stroke="{INK}" stroke-width="4"/><path d="M314 746H346" stroke="#6b5f66" stroke-width="6" stroke-linecap="round"/>'
# Bed: headboard on the left, pillow, sheet, rail and footboard.
b += f'<path d="M466 820V500Q466 456 494 456Q522 456 522 500V820Z" fill="{WOOD}" stroke="{INK}" stroke-width="6"/><path d="M482 500V800" stroke="{WOOD_LIGHT}" stroke-width="6"/>'
b += f'<path d="M1296 820V640Q1296 606 1318 606Q1340 606 1340 640V820Z" fill="{WOOD}" stroke="{INK}" stroke-width="6"/>'
b += f'<rect x="500" y="728" width="822" height="62" fill="#34292f" stroke="{INK}" stroke-width="5"/><path d="M500 790V820M1300 790V820" stroke="{WOOD}" stroke-width="20"/>'
b += f'<rect x="506" y="674" width="796" height="64" rx="14" fill="{SHEET}" stroke="{INK}" stroke-width="5"/><path d="M520 700H1290" stroke="#6d7a88" stroke-width="3" opacity=".7"/>'
b += f'<ellipse cx="600" cy="655" rx="96" ry="30" fill="{PILLOW}" stroke="{INK}" stroke-width="5"/><path d="M540 650Q560 640 580 652M630 646Q650 640 664 650" fill="none" stroke="#7d8996" stroke-width="3"/>'
svg('bedroom_bg', 1920, 1080, b, defs)

# ---------------- Mina in bed ----------------
LYING = 'M664 566C700 552 760 556 800 566C860 582 900 594 950 592C1010 590 1050 570 1100 574C1160 578 1200 596 1240 590C1270 586 1292 600 1302 614L1308 770Q1150 784 980 774Q820 766 660 776L652 640Q650 600 664 566Z'
LYING_BAND = 'M664 566L706 558L712 772L660 776L652 640Q650 600 664 566Z'
LYING_FOLDS = ['M780 604Q806 690 786 764', 'M930 614Q956 700 934 766', 'M1094 598Q1120 690 1100 768', 'M1220 612Q1236 700 1228 772']
SITTING = 'M546 636C600 624 660 640 720 636C800 630 870 614 930 604C990 598 1030 626 1080 628C1150 630 1190 604 1240 606C1272 606 1294 618 1304 628L1308 770Q1150 784 980 774Q760 766 548 778Z'
SITTING_FOLDS = ['M700 660Q730 720 712 768', 'M890 640Q920 710 900 770', 'M1050 650Q1084 720 1064 772', 'M1196 640Q1220 710 1210 770']


def lying(eyes, arm, seed):
    body = f'<path d="M648 560Q700 556 712 600L700 620L648 616Z" fill="{PJ}" stroke="{INK}" stroke-width="4"/>'
    body += f'<path d="M646 572L664 588L646 604" fill="{COLLAR}" stroke="{INK}" stroke-width="3"/>'
    # Lying on her back the ponytail is under her head.
    body += head(595, 588, -90, eyes, ponytail=False)
    cover, d = blanket(LYING, seed, LYING_FOLDS, LYING_BAND)
    body += cover
    if arm:
        body += limb([(708, 578), (770, 566)], 24, PJ) + hand(790, 566, 17, 13, -10)
    return body, d


for key, eyes, arm in (('bed_mina_asleep', 'closed', False), ('bed_mina_awake', 'wide', True), ('bed_mina_drowsy', 'half', True)):
    body, d = lying(eyes, arm, 11)
    pose(key, body, d)

# Turned away and curled up; the blanket is kicked down to the foot of the bed.
curl = ('M640 566Q660 528 700 524Q760 520 800 536Q850 510 900 516Q950 524 966 560Q990 610 1010 640Q1060 660 1120 662'
        'Q1150 636 1190 622Q1230 612 1250 630Q1280 612 1300 628L1308 770Q1150 784 980 774Q820 766 640 776L632 640Q630 600 640 566Z')
body = f'<ellipse cx="598" cy="596" rx="54" ry="50" transform="rotate(-80 598 596)" fill="{HAIR}" stroke="{INK}" stroke-width="5"/>'
body += f'<path d="M570 572Q600 556 630 572" fill="none" stroke="{SHINE}" stroke-width="4"/>'
body += f'<path d="M628 614Q676 616 706 646Q672 656 640 636Z" fill="{HAIR}" stroke="{INK}" stroke-width="5"/><circle cx="632" cy="616" r="10" fill="{TIE}" stroke="{INK}" stroke-width="3"/>'
cover, d = blanket(curl, 12, ['M760 560Q790 660 770 764', 'M900 560Q930 660 908 768', 'M1180 640Q1196 700 1188 770', 'M1240 636Q1256 704 1246 772'])
pose('bed_mina_turn', body + cover, d)


def sitting(upper, seed=13):
    torso = (f'<path d="M590 512Q560 560 556 676L698 676Q694 580 668 512Z" fill="{PJ}" stroke="{INK}" stroke-width="5"/>'
             f'<path d="M606 512L627 538L650 512" fill="{COLLAR}" stroke="{INK}" stroke-width="3.5"/>'
             + ''.join(f'<circle cx="{630 + k}" cy="{566 + k * 34}" r="4" fill="{COLLAR}" stroke="{INK}" stroke-width="2"/>' for k in range(3)))
    cover, d = blanket(SITTING, seed, SITTING_FOLDS)
    return torso + upper + cover, d


def sitting_after(upper_head, arms, seed=13):
    # Arms and anything held sit in front of the blanket.
    torso_cover, d = sitting(upper_head, seed)
    return torso_cover + arms, d


body, d = sitting_after(head(628, 446, 4, 'open'), hand(728, 626, 16, 12) + limb([(660, 524), (682, 592), (744, 624)], 22, PJ) + hand(756, 622, 17, 12, -15))
pose('bed_mina_sit', body, d)

phone = (f'<g transform="rotate(-12 752 506)"><rect x="744" y="474" width="17" height="66" rx="4" fill="#191e24" stroke="{INK}" stroke-width="3"/>'
         f'<path d="M758 480V534" stroke="#7a8d9a" stroke-width="2"/></g>')
body, d = sitting_after(head(628, 448, 10, 'wide'), hand(736, 540, 15, 12) + phone + limb([(660, 524), (674, 600), (742, 548)], 22, PJ) + hand(750, 540, 16, 12, -40))
pose('bed_mina_phone', body, d)

book = (f'<path d="M716 600Q752 576 790 586Q828 572 866 594L866 606Q828 586 790 598Q752 590 716 612Z" fill="#c0c4c8" stroke="{INK}" stroke-width="3"/>'
        f'<path d="M716 612Q752 590 790 598Q828 586 866 606L866 614Q828 594 790 606Q752 598 716 620Z" fill="#5a474e" stroke="{INK}" stroke-width="3"/>'
        f'<path d="M790 588V604" stroke="{INK}" stroke-width="2"/>'
        + ''.join(f'<path d="M{728 + k * 12} {603 - k * 2.4:.1f}Q{740 + k * 12} {598 - k * 2.4:.1f} {750 + k * 12} {600 - k * 2.4:.1f}" fill="none" stroke="#8f959b" stroke-width="1.6"/>' for k in range(4)))
body, d = sitting_after(head(630, 450, 18, 'half'), book + limb([(660, 524), (680, 596), (728, 612)], 22, PJ) + hand(730, 612, 16, 12, 20) + hand(856, 610, 14, 11, -20))
pose('bed_mina_book', body, d)

# Reaching over to the nightstand: she turns towards it.
reach_torso = (f'<path d="M574 516Q548 570 552 676L694 676Q684 580 640 512Z" fill="{PJ}" stroke="{INK}" stroke-width="5"/>'
               f'<path d="M584 514L604 538L628 512" fill="{COLLAR}" stroke="{INK}" stroke-width="3.5"/>')
cover, d = blanket(SITTING, 13, SITTING_FOLDS)
body = reach_torso + head(588, 454, 14, 'open', flip=True) + cover + limb([(590, 528), (512, 586), (440, 640)], 22, PJ) + hand(426, 648, 18, 13, 30)
pose('bed_mina_reach', body, d)

glass = (f'<g transform="rotate(-128 668 470)"><path d="M652 470L684 470L680 532L656 532Z" fill="#a9c4d2" fill-opacity=".45" stroke="{INK}" stroke-width="3"/>'
         f'<path d="M654 486L682 486L680 532L656 532Z" fill="#8fb1c4" opacity=".55"/></g>')
body, d = sitting_after(head(632, 440, -24, 'closed', mouth='none'), limb([(660, 524), (704, 572), (712, 500)], 22, PJ) + glass + hand(708, 496, 16, 13, -60))
pose('bed_mina_drink', body, d)

# ---------------- Nightstand props ----------------
svg('prop_book', 92, 22, f'<rect x="2" y="2" width="88" height="18" rx="3" fill="#5a474e" stroke="{INK}" stroke-width="3"/><path d="M8 8H84M8 13H84" stroke="#a3a7ac" stroke-width="2"/>')
svg('prop_phone', 60, 10, f'<rect x="2" y="1.5" width="56" height="7" rx="2" fill="#191e24" stroke="{INK}" stroke-width="2"/><path d="M8 3.5H52" stroke="#5f7180" stroke-width="1.4"/>')
svg('prop_pill_bottle', 32, 68, f'<rect x="3" y="16" width="26" height="50" rx="4" fill="#7c6142" stroke="{INK}" stroke-width="3"/><rect x="2" y="3" width="28" height="14" rx="3" fill="#c9cfd2" stroke="{INK}" stroke-width="3"/>'
    f'<rect x="6" y="30" width="20" height="22" fill="#c4c0b4"/><path d="M9 36H23M9 42H20" stroke="#7d786c" stroke-width="2"/>')
svg('prop_water_glass', 32, 62, f'<path d="M3 3L29 3L25 59L7 59Z" fill="#a9c4d2" fill-opacity=".35" stroke="{INK}" stroke-width="3"/><path d="M5 26L27 26L25 59L7 59Z" fill="#8fb1c4" opacity=".5"/><path d="M8 8L10 52" stroke="#e6eef2" stroke-width="2" opacity=".5"/>')

# ---------------- Close-ups ----------------
rng = random.Random(77)
d = '''<radialGradient id="moon" cx=".3" cy=".1" r="1.1"><stop stop-color="#6b8b8c"/><stop offset=".55" stop-color="#4c6a6f"/><stop offset="1" stop-color="#2a3d42"/></radialGradient>
<radialGradient id="vig" r=".75"><stop offset=".55" stop-color="#05080c" stop-opacity="0"/><stop offset="1" stop-color="#05080c" stop-opacity=".85"/></radialGradient>'''
b = '<rect width="1920" height="1080" fill="url(#moon)"/>'
for k in range(7):
    x = 120 + k * 280 + rng.uniform(-40, 40)
    b += f'<path d="M{x:.0f} -20Q{x + rng.uniform(-160, 160):.0f} 540 {x + rng.uniform(-90, 90):.0f} 1100" fill="none" stroke="{BLANKET_DARK}" stroke-width="{rng.uniform(26, 60):.0f}" stroke-linecap="round" opacity=".55"/>'
b += star_print(rng, 0, 1920, 0, 1080, 90, 14)
b += '<rect width="1920" height="1080" fill="url(#vig)"/>'
svg('insert_blanket', 1920, 1080, b, d)


def back_of_hand():
    out = f'<path d="M150 760L192 560Q262 540 332 560L382 760Z" fill="{PJ}" stroke="{INK}" stroke-width="6"/><path d="M188 566Q262 546 336 566L340 600Q262 580 186 600Z" fill="{PJ_DARK}" stroke="{INK}" stroke-width="4"/>'
    out += limb([(214, 448), (140, 356)], 40, SKIN)
    for (x0, y0), (x1, y1) in (((232, 360), (214, 178)), ((266, 352), (266, 148)), ((300, 356), (312, 174)), ((330, 372), (352, 224))):
        out += limb([(x0, y0), (x1, y1)], 36, SKIN)
        out += f'<ellipse cx="{x1}" cy="{y1 + 4}" rx="10" ry="12" fill="#e9dcd1" opacity=".8"/>'
    out += f'<path d="M206 560Q190 440 212 340Q262 318 336 340Q356 440 322 560Z" fill="{SKIN}" stroke="{INK}" stroke-width="6"/>'
    out += ''.join(f'<path d="M{x - 10} {y}Q{x} {y - 8} {x + 10} {y}" fill="none" stroke="{CREASE}" stroke-width="3"/>' for x, y in ((234, 360), (268, 352), (302, 358), (330, 374)))
    out += f'<path d="M232 470Q262 486 300 470" fill="none" stroke="{CREASE}" stroke-width="3" opacity=".7"/>'
    return out


svg('insert_hand_right', 520, 760, back_of_hand())
svg('insert_hand_left', 520, 760, f'<g transform="translate(520 0) scale(-1 1)">{back_of_hand()}</g>')

# Left hand holding the open pill bottle on its side, mouth towards the palm (Godot tips it further).
bottle = (f'<rect x="-60" y="-118" width="120" height="236" rx="16" fill="#7c6142" fill-opacity=".93" stroke="{INK}" stroke-width="6"/>'
          + ''.join(f'<ellipse cx="{-30 + k * 20}" cy="{-92 + (k % 2) * 10}" rx="12" ry="7" fill="#e7eaeb" opacity=".35"/>' for k in range(4))
          + f'<rect x="-54" y="-50" width="108" height="110" fill="#c4c0b4" stroke="{INK}" stroke-width="3"/><path d="M-40 -20H40M-40 2H32M-40 24H12" stroke="#7d786c" stroke-width="5" stroke-linecap="round"/>'
          + f'<rect x="-42" y="-146" width="84" height="34" rx="6" fill="#6b5338" stroke="{INK}" stroke-width="5"/><ellipse cx="0" cy="-146" rx="40" ry="9" fill="#21190f" stroke="{INK}" stroke-width="4"/>')
b = f'<path d="M30 640L120 440Q190 404 262 430L300 640Z" fill="{PJ}" stroke="{INK}" stroke-width="6"/><path d="M116 446Q190 404 266 436L272 470Q196 440 108 482Z" fill="{PJ_DARK}" stroke="{INK}" stroke-width="4"/>'
b += f'<g transform="translate(400 300) rotate(105)">{bottle}</g>'
b += f'<path d="M150 420Q150 330 250 300Q330 290 342 350Q340 410 270 436Q200 452 150 420Z" fill="{SKIN}" stroke="{INK}" stroke-width="6"/>'
b += ''.join(f'<path d="M{x} 252Q{x + 16} 230 {x + 34} 250L{x + 30} 286L{x + 4} 288Z" fill="{SKIN}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>' for x in (262, 296, 330))
b += limb([(236, 380), (360, 352)], 36, SKIN)
svg('insert_hand_bottle', 760, 640, b)

# Right palm, open and waiting.
b = limb([(410, 420), (530, 560)], 84, SKIN)
b += f'<path d="M640 700L580 500Q506 470 448 508L500 700Z" fill="{PJ}" stroke="{INK}" stroke-width="6"/><path d="M450 506Q510 466 584 498L592 530Q516 500 456 540Z" fill="{PJ_DARK}" stroke="{INK}" stroke-width="4"/>'
for (x0, y0), (x1, y1) in (((196, 334), (148, 248)), ((246, 304), (218, 200)), ((298, 296), (288, 190)), ((350, 306), (362, 216))):
    b += limb([(x0, y0), (x1, y1)], 36, SKIN)
b += limb([(430, 400), (486, 296)], 40, SKIN)
b += f'<path d="M180 330Q170 470 300 500Q470 500 480 380Q470 300 360 296Q250 290 180 330Z" fill="{PALM}" stroke="{INK}" stroke-width="6"/>'
b += f'<path d="M210 360Q300 330 420 360M220 420Q300 400 400 430M330 470Q360 400 440 380" fill="none" stroke="{CREASE}" stroke-width="3.5" stroke-linecap="round"/>'
svg('insert_hand_palm', 700, 700, b)
svg('prop_pill', 60, 36, f'<ellipse cx="30" cy="18" rx="25" ry="14" fill="#e7eaeb" stroke="{INK}" stroke-width="3"/><path d="M12 18H48" stroke="#aeb4b6" stroke-width="2"/>')

# Narration box.
svg('ui_narration', 1400, 150, '<rect x="3" y="3" width="1394" height="144" rx="18" fill="#0b1018" fill-opacity=".86" stroke="#c9d6df" stroke-opacity=".35" stroke-width="3"/>'
    '<rect x="14" y="14" width="1372" height="122" rx="12" fill="none" stroke="#c9d6df" stroke-opacity=".12" stroke-width="2"/>')

# ---------------- Audio ----------------
def write_wav(key, samples, force=False, peak_to=.9):
    dest = ROOT / 'audio' / (key + '.wav')
    if dest.exists() and not (ARGS.refresh or force):
        return
    peak = max(1e-6, max(abs(v) for v in samples))
    scale = min(1.0, peak_to / peak)
    with wave.open(str(dest), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SR)
        out.writeframes(b''.join(struct.pack('<h', max(-32767, min(32767, int(v * scale * 32767)))) for v in samples))


NOTES = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def freq(n, octave_shift=0):
    return 440 * 2 ** (((int(n[-1]) + 1 + octave_shift) * 12 + NOTES[n[0]] - 69) / 12)


def music_box(buf, start, dur, hz, gain, wow=0.0):
    # A bright tine with slightly inharmonic overtones and a long ring.
    s0 = int(start * SR)
    for i in range(int(dur * SR)):
        j = s0 + i
        if j >= len(buf):
            break
        t = i / SR
        f = hz * (1 + wow * math.sin(math.tau * .7 * (start + t)))
        env = min(1, t / .004) * math.exp(-t * 2.6)
        v = math.sin(math.tau * f * t) + .28 * math.sin(math.tau * f * 2.98 * t) * math.exp(-t * 6) + .1 * math.sin(math.tau * f * 5.4 * t) * math.exp(-t * 11)
        buf[j] += gain * env * v


def lowpass(samples, a):
    out, y = [], 0.0
    for x in samples:
        y += a * (x - y)
        out.append(y)
    return out


def reverb(dry, mix=.35):
    out = dry[:]
    for delay_s, fb in ((.0297, .74), (.0371, .72), (.0411, .7), (.0437, .69)):
        d = int(delay_s * SR)
        line = [0.0] * len(dry)
        for i in range(len(dry)):
            line[i] = dry[i] + (line[i - d] * fb if i >= d else 0.0)
        for i in range(len(dry)):
            out[i] += mix * .25 * line[i]
    return lowpass(out, .55)


# The intro is the first two lines of the song (Twinkle, twinkle... / How I wonder...) an octave up,
# at the song's own tempo, so the flower-path song starts on the next downbeat.
unit = SONG['unit_s']
twinkle = [s for line in SONG['lines'][:2] for s in line['syllables']]
intro_len = sum(s[1] for s in twinkle) * unit
music = [0.0] * int((intro_len + 2.4) * SR)
cursor = 0.0
for text, units, note in twinkle:
    music_box(music, cursor, units * unit + 1.6, freq(note, 1), .34, .0025)
    music_box(music, cursor + .012, units * unit + 1.0, freq(note, 2), .05, .0025)
    cursor += units * unit
for k, n in enumerate(('C6', 'E6', 'G6', 'C7')):
    music_box(music, k * .07, 1.4, freq(n), .06)
# A soft major pad swells under the second line, as the dream opens.
pad_start = intro_len * .45
for n in ('C4', 'E4', 'G4', 'C5'):
    hz = freq(n)
    for i in range(int(pad_start * SR), len(music)):
        t = i / SR - pad_start
        env = min(1, t / 2.6) * (1 - min(1, max(0, (i / SR - intro_len) / 2.0)))
        music[i] += .028 * env * (math.sin(math.tau * hz * t) + .3 * math.sin(math.tau * hz * 2 * t + 1.1))
write_wav('mus_dream_intro', reverb(music), force=True, peak_to=.8)

arng = random.Random(31)


def noise(n):
    return [arng.uniform(-1, 1) for _ in range(n)]


# Quiet room at night: a low hum of air and a faint wind outside. Crossfaded so it loops seamlessly.
length = 8.0
raw = lowpass(lowpass(noise(int((length + 1) * SR)), .02), .05)
wind = [v * (.6 + .4 * math.sin(math.tau * i / SR / 4.0)) for i, v in enumerate(lowpass(noise(int((length + 1) * SR)), .01))]
mix = [raw[i] * 1.6 + wind[i] * .9 for i in range(len(raw))]
n, fade = int(length * SR), SR
night = [mix[i] if i >= fade else mix[i] * (i / fade) + mix[n + i] * (1 - i / fade) for i in range(n)]
write_wav('amb_night', night, peak_to=.5)


def burst(dur, a_low, a_high, bumps):
    n = int(dur * SR)
    src = noise(n)
    band = [h - l for h, l in zip(lowpass(src, a_high), lowpass(src, a_low))]
    out = []
    for i, v in enumerate(band):
        t = i / SR
        env = sum(g * math.exp(-((t - c) / w) ** 2) for c, w, g in bumps)
        out.append(v * env)
    return out


write_wav('sfx_rustle', burst(1.0, .02, .35, [(.18, .12, 1.0), (.5, .16, .7), (.8, .1, .35)]), peak_to=.7)
write_wav('sfx_page', burst(.35, .1, .6, [(.08, .05, 1.0), (.18, .04, .6)]), peak_to=.6)
pills = [0.0] * int(.7 * SR)
for k in range(9):
    s0 = int((.04 + k * .065 + arng.uniform(-.02, .02)) * SR)
    click = burst(.03, .3, .9, [(.004, .006, 1.0)])
    for i, v in enumerate(click):
        if s0 + i < len(pills):
            pills[s0 + i] += v * (1 - k / 12)
write_wav('sfx_pills', pills, peak_to=.7)
swallow = [0.0] * int(.8 * SR)
for start, f0, f1, g in ((.05, 150, 70, 1.0), (.42, 140, 64, .8)):
    ph = 0.0
    for i in range(int(.16 * SR)):
        t = i / SR
        f = f0 + (f1 - f0) * t / .16
        ph += math.tau * f / SR
        swallow[int(start * SR) + i] += g * math.sin(ph) * math.sin(math.pi * t / .16)
for start in (.2, .28):
    for i in range(int(.07 * SR)):
        t = i / SR
        swallow[int(start * SR) + i] += .35 * math.sin(math.tau * (380 + 900 * t) * t) * math.exp(-t * 50)
write_wav('sfx_swallow', swallow, peak_to=.6)
blip = [0.0] * int(.4 * SR)
for start, n_ in ((0, 'E6'), (.09, 'B5')):
    for i in range(int(.25 * SR)):
        t = i / SR
        blip[int(start * SR) + i] += math.sin(math.tau * freq(n_) * t) * math.exp(-t * 18) * min(1, t / .003)
write_wav('sfx_phone', blip, peak_to=.4)
print('Bedroom opening placeholders ready.')
