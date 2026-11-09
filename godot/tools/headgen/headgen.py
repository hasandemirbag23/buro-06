#!/usr/bin/env python3
"""BÜRO prosedürel kafa üreteci.
SDF ile yüz heykeli -> marching cubes -> GLB (vertex color). Şablon: data/character_templates.json
Kullanım: /tmp/dl/v/bin/python tools/headgen/headgen.py [id ...] [--res 0.002]
Çıktı: assets/heads/<id>_skin.glb, <id>_hair.glb, <id>_head.json (göz/kulak/ağız konumları)
Eksenler: x sağ, y yukarı, z yüz yönü. Orijin: kafatası merkezi (metre).
"""
import json
import sys
from pathlib import Path

import numpy as np
import trimesh
from skimage.measure import marching_cubes

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "data" / "character_templates.json"
OUT = ROOT / "assets" / "heads"

F = np.float32
SEED = 0
TRIS_SKIN = 60000
TRIS_HAIR = 40000


# ---------------------------------------------------------------- yardımcılar
def hex_lin(h):
    h = h.lstrip("#")
    c = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def ell(x, y, z, c, r):
    px, py, pz = (x - c[0]) / r[0], (y - c[1]) / r[1], (z - c[2]) / r[2]
    k0 = np.sqrt(px * px + py * py + pz * pz)
    k1 = np.sqrt((px / r[0]) ** 2 + (py / r[1]) ** 2 + (pz / r[2]) ** 2) + 1e-9
    return (k0 * (k0 - 1.0) / k1).astype(F)


def sph(x, y, z, c, r):
    return (np.sqrt((x - c[0]) ** 2 + (y - c[1]) ** 2 + (z - c[2]) ** 2) - r).astype(F)


def cap(x, y, z, a, b, r):
    pax, pay, paz = x - a[0], y - a[1], z - a[2]
    bax, bay, baz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    h = np.clip((pax * bax + pay * bay + paz * baz) / (bax * bax + bay * bay + baz * baz), 0.0, 1.0)
    return (np.sqrt((pax - bax * h) ** 2 + (pay - bay * h) ** 2 + (paz - baz * h) ** 2) - r).astype(F)


def seg2t(x, y, a, b, ra, rb):
    """seg2'nin uçları farklı kalınlıkta olanı: kaşın dış ucu inceltilir."""
    pax, pay = x - a[0], y - a[1]
    bax, bay = b[0] - a[0], b[1] - a[1]
    h = np.clip((pax * bax + pay * bay) / (bax * bax + bay * bay), 0.0, 1.0)
    d = np.sqrt((pax - bax * h) ** 2 + (pay - bay * h) ** 2)
    return (d - (ra + (rb - ra) * h)).astype(F)


def seg2(x, y, a, b, r):
    """x-y düzleminde a-b doğru parçasına uzaklık (kalınlık r). Yüzeye oturan
    kıl bölgelerinin (kaş, bıyık) sınırını z'den bağımsız tanımlamak için."""
    pax, pay = x - a[0], y - a[1]
    bax, bay = b[0] - a[0], b[1] - a[1]
    h = np.clip((pax * bax + pay * bay) / (bax * bax + bay * bay), 0.0, 1.0)
    return (np.sqrt((pax - bax * h) ** 2 + (pay - bay * h) ** 2) - r).astype(F)


def hash3(ix, iy, iz, seed):
    n = (ix * 374761393 + iy * 668265263 + iz * 2147483647 + (seed + SEED * 131) * 1274126177) & 0x7FFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0x7FFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF).astype(F) / 65535.0


def noise3(x, y, z, freq, seed=0):
    """Değer gürültüsü [0,1]."""
    px, py, pz = x * freq, y * freq, z * freq
    ix, iy, iz = np.floor(px).astype(np.int64), np.floor(py).astype(np.int64), np.floor(pz).astype(np.int64)
    fx, fy, fz = (px - ix).astype(F), (py - iy).astype(F), (pz - iz).astype(F)
    fx, fy, fz = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy), fz * fz * (3 - 2 * fz)
    out = 0.0
    for dx in (0, 1):
        wx = fx if dx else 1 - fx
        for dy in (0, 1):
            wy = fy if dy else 1 - fy
            for dz in (0, 1):
                wz = fz if dz else 1 - fz
                out = out + wx * wy * wz * hash3(ix + dx, iy + dy, iz + dz, seed)
    return out.astype(F)


def ss(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def gauss(x, y, z, c, s):
    return np.exp(-(((x - c[0]) / s[0]) ** 2 + ((y - c[1]) / s[1]) ** 2 + ((z - c[2]) / s[2]) ** 2))


# ---------------------------------------------------------------- şablon
def load_params(cid):
    data = json.loads(TEMPLATE.read_text())
    p = json.loads(json.dumps(data["default"]))
    over = data["characters"][cid]
    for k, v in over.items():
        if k.startswith("_"):
            continue
        if isinstance(v, dict) and isinstance(p.get(k), dict):
            p[k].update(v)
        else:
            p[k] = v
    return p


# ---------------------------------------------------------------- kafa SDF
class Head:
    def __init__(self, p):
        self.p = p
        self.age = float(np.clip((p["age"] - 20) / 45.0, 0.0, 1.0))
        self.w = p["head_w"]
        self.fem = p["female"]
        self._eye = None

    # yüz yarı genişlikleri vs. tek yerde dursun
    def skull(self, x, y, z, grow=0.0, vol=1.0):
        p = self.p
        r = (0.074 * p["head_w"] + grow, 0.096 * p["head_h"] + grow, 0.088 * p["head_d"] + grow)
        return ell(x, y, z, (0, 0.016, -0.012), r)

    ## Göz küresi: (x çarpanı · head_w, y, yarıçap çarpanı · eye_size).
    ## z BURADA YOK — heykelden ölçülür. Elle yazıldığında küre Player'da yüzeyin
    ## 27 mm önüne, İdris'te 4 mm arkasına düşüyordu; biri patlak göz, öbürü
    ## görünmeyen yarık demekti.
    EYES = {
        "behzat": (0.03, 0.01, 0.0105),
        "hayalet": (0.026, 0.012, 0.0104),
        "akbaba": (0.028, 0.011, 0.0106),
        "player": (0.03, 0.014, 0.0108),
        "savci": (0.026, 0.012, 0.0102),
        "arsiv": (0.028, 0.01, 0.0102),
        "tarik": (0.03, 0.012, 0.0102),
        "zafer": (0.03, 0.01, 0.0098),
        "mert": (0.027, 0.013, 0.0098),
        "haldun": (0.026, 0.012, 0.0096),
        "idris": (0.03, 0.01, 0.0098),
        "nevzat": (0.028, 0.012, 0.0094),
    }
    ## Kornea, çevresindeki deriden bu kadar dışarı taşar.
    EYE_BULGE = 0.0015
    ## Heykeldeki `yy = y - k * asym * sgn(x)` sapma katsayısı.
    ASYM_K = {
        "behzat": 0.0018, "hayalet": 0.0012, "akbaba": 0.0014, "player": 0.001,
        "savci": 0.0011, "arsiv": 0.0012, "tarik": 0.0014, "zafer": 0.0016,
        "mert": 0.0012, "haldun": 0.0014, "idris": 0.0022, "nevzat": 0.001,
    }

    def surface_z(self, px, py):
        """(px, py) dikeyinde heykelin ön yüzeyinin z'si. Göz kapağı eklenmeden
        önceki biçimi ölçer (`_sculpt`), yoksa kendini çağırmış olurdu."""
        sx = F(px + self.p["asym"] * 0.0025 * (py * 10.0))
        zs = np.linspace(0.16, -0.02, 901).astype(F)
        d = np.asarray(self._sculpt(np.full_like(zs, sx), np.full_like(zs, F(py)), zs))
        hit = np.nonzero(d <= 0.0)[0]
        return float(zs[hit[0]]) if hit.size else 0.06

    def eye(self):
        """(ex, ey, ez, r, asym_k) — göz küresinin kafa yerel koordinatları.
        z, göz kapağı hizasındaki deri yüzeyinden ölçülür; sonuç her karakterde
        aynı miktarda (EYE_BULGE) dışarı taşan bir kornea olur. Ölçüm pahalı
        değil ama her SDF değerlendirmesinde çağrıldığı için önbelleklenir."""
        if self._eye is not None:
            return self._eye
        p = self.p
        sculpt = p.get("sculpt", "")
        xm, ey, rm = self.EYES.get(sculpt, (0.029, 0.014, 0.0104))
        ex = xm * p["head_w"]
        r = rm * p["eye_size"]
        rim = max(self.surface_z(ex, ey + 0.009), self.surface_z(ex, ey - 0.008))
        self._eye = (ex, ey, rim - r + self.EYE_BULGE, r, self.ASYM_K.get(sculpt, 0.0012))
        return self._eye

    def eyelids(self, d, x, y, z):
        """Göz küresini saran ince kapak kabuğu; ortada badem biçimi açıklık bırakır.

        Heykelin göz yuvası kürenin tamamı kadar açık olduğu için küre hiç
        örtülmüyor, sklera bütünüyle görünüyor ve göz 'oyuncak bebek gözü'ne
        dönüşüyordu. Kapak kürenin 1.7 mm dışından geçer, içeri 0.4 mm gömülür
        ki küreyle arasında boşluk kalmasın."""
        p = self.p
        ex, ey, ez, r, k = self.eye()
        ax = np.abs(x)
        yy = y - k * p["asym"] * np.sign(x)
        shell = smax(sph(ax, yy, z, (ex, ey, ez), r + 0.0017),
                     -sph(ax, yy, z, (ex, ey, ez), r - 0.0004), 0.0006)
        dy = yy - ey
        up = 0.0052 * p["eye_size"] - 0.0022 * p["eye_bag"]
        dn = 0.0046 * p["eye_size"]
        # açıklık badem biçimi olmalı: iç ve dış köşeye doğru kapanır. Yalnız y ile
        # tanımlanınca dikdörtgen bir yarık çıkıyor ve göz cam gibi duruyordu.
        hw = r * 0.98
        k = np.sqrt(np.clip(1.0 - ((ax - ex) / hw) ** 2, 0.0, 1.0))
        aperture = np.where(dy >= 0.0, up * k - dy, dn * k + dy).astype(F)
        lid = smax(shell, aperture, 0.0011)
        lid = smax(lid, (ez - 0.002) - z, 0.0024)
        return smin(d, lid, 0.0016)

    def skin(self, x, y, z):
        return self.eyelids(self._sculpt(x, y, z), x, y, z)

    def _sculpt(self, x, y, z):
        if self.p.get("sculpt") == "behzat":
            return self.skin_behzat(x, y, z)
        if self.p.get("sculpt") == "hayalet":
            return self.skin_hayalet(x, y, z)
        if self.p.get("sculpt") == "akbaba":
            return self.skin_akbaba(x, y, z)
        if self.p.get("sculpt") == "player":
            return self.skin_player(x, y, z)
        if self.p.get("sculpt") == "savci":
            return self.skin_savci(x, y, z)
        if self.p.get("sculpt") == "arsiv":
            return self.skin_arsiv(x, y, z)
        if self.p.get("sculpt") == "tarik":
            return self.skin_tarik(x, y, z)
        if self.p.get("sculpt") == "zafer":
            return self.skin_zafer(x, y, z)
        if self.p.get("sculpt") == "mert":
            return self.skin_mert(x, y, z)
        if self.p.get("sculpt") == "haldun":
            return self.skin_haldun(x, y, z)
        if self.p.get("sculpt") == "idris":
            return self.skin_idris(x, y, z)
        if self.p.get("sculpt") == "nevzat":
            return self.skin_nevzat(x, y, z)
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        d = self.skull(x, y, z)
        # çene kemiği
        jaw_r = 0.018 if self.fem else 0.02
        jaw_a = ((0.05 if self.fem else 0.052) * jw * w, -0.04 if self.fem else -0.038, -0.012)
        jaw_b = ((0.014 if self.fem else 0.016) * jw, -0.104 - 0.006 * p["jaw_drop"], 0.02 if self.fem else 0.024)
        jawc = cap(ax, y, z, jaw_a, jaw_b, jaw_r)
        d = smin(d, jawc, 0.016)
        cs = 0.9 + 0.08 * p["chin"]
        d = smin(d, ell(x, y, z, (0, -0.086, 0.042), (0.016 * jw, 0.02 * cs, 0.012 * cs)), 0.018)
        d = smin(d, sph(ax, y, z, (0.05 * jw * w, -0.088, 0.036), 0.017 * p["jowl"] + 0.0001), 0.02) if p["jowl"] > 0.01 else d
        # elmacık kemiği
        d = smin(d, sph(ax, y, z, (0.048 * w, -0.012, 0.05), 0.014 * p["cheek"]), 0.02)
        # yanak çöküklüğü
        if p["cheek_hollow"] > 0:
            hol = ell(ax, y, z, (0.058 * w, -0.05, 0.05), (0.018, 0.032, 0.03))
            d = d + (1.0 - np.clip(hol / 0.03, 0, 1)) * 0.004 * p["cheek_hollow"]
        # kaş sırtı
        bt = p["brow_tilt"]
        brow_r = (0.0036 + 0.0016 * p["brow"]) if self.fem else (0.0058 + 0.0028 * p["brow"])
        brow = cap(ax, y, z, (0.006, 0.034, 0.066), (0.048 * w, 0.036 + 0.004 * (bt + 0.6 * p["asym"] * sgn), 0.058), brow_r)
        d = smin(d, brow, 0.012)
        # göz çukuru
        sock_c = (0.03 * w, 0.014, 0.072 - 0.004 * p["eye_depth"])
        sock_r = (0.0185 * p["eye_size"], 0.0125 * p["eye_size"], 0.016)
        # asimetri: sol/sağ göz yüksekliği farkı
        yy = y - 0.0012 * p["asym"] * sgn
        sock = ell(ax, yy, z, sock_c, sock_r)
        d = smax(d, -sock, 0.008)
        # göz kapakları (üst/alt)
        lid_up = ell(ax, yy, z, (sock_c[0], 0.022, 0.066), (0.016 * p["eye_size"], 0.0055, 0.01))
        lid_lo = ell(ax, yy, z, (sock_c[0], 0.006, 0.066), (0.015 * p["eye_size"], 0.0045, 0.01))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.004)
        # göz altı torbası
        if p["eye_bag"] > 0.01:
            bag = ell(ax, y, z, (0.034 * w, -0.0085, 0.078), (0.017, 0.0065 * (0.5 + p["eye_bag"] * 0.8), 0.014))
            d = smin(d, bag, 0.008)
            crease = ell(ax, y, z, (0.034 * w, -0.0185, 0.082), (0.017, 0.0014 + 0.001 * p["eye_bag"], 0.012))
            d = d + (1 - np.clip(crease / 0.006, 0, 1)) * 0.0011 * p["eye_bag"]
        # burun
        tip_y = -0.034 - 0.006 * p["nose_hook"] + 0.006 * p["nose_up"]
        tip_z = 0.078 + 0.01 * (p["nose_len"] - 1.0) - 0.004 * p["nose_hook"]
        bridge = cap(ax, y, z, (0, 0.016, 0.07), (0, tip_y + 0.008, tip_z - 0.006), 0.0062 * p["nose_bridge"] + 0.001)
        d = smin(d, bridge, 0.012)
        d = smin(d, ell(x - 0.0022 * p["asym"], y, z, (0, tip_y, tip_z), (0.0082 * p["nose_w"], 0.0072, 0.0076)), 0.008)
        d = smin(d, sph(ax, y, z, (0.0125 * p["nose_w"] + 0.0035, tip_y + 0.0035, tip_z - 0.011), 0.0075), 0.007)
        nostril = ell(ax, y, z, (0.0072 * p["nose_w"], tip_y - 0.0042, tip_z - 0.003), (0.0036, 0.0028, 0.0065))
        d = smax(d, -nostril, 0.003)
        # dudak
        mw = p["mouth_w"]
        lf = p["lip_full"] * (0.85 if not self.fem else 1.0)
        upper = ell(ax, y, z, (0, -0.06, 0.058), (0.014 * mw, 0.0028 * lf, 0.0032))
        lower = ell(ax, y, z, (0, -0.066, 0.056), (0.013 * mw, 0.003 * lf, 0.0032))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.01)
        md = p["mouth_down"]
        mline = cap(ax, y, z, (0.0, -0.0615, 0.074), (0.014 * mw, -0.0615 - 0.002 * md, 0.07), 0.0005)
        d = smax(d, -mline, 0.001)
        # çene çukuru / dudak altı çizgisi
        d = smax(d, -ell(ax, y, z, (0, -0.078, 0.06), (0.01, 0.0016, 0.004)), 0.002)
        # nazolabial kıvrım
        nl = cap(ax, y, z, (0.0215, -0.036, 0.097), (0.031 * mw, -0.066 - 0.003 * md, 0.083), 0.0035)
        nl_mask = 0.0013 + 0.0030 * (0.3 + 0.7 * self.age) * p["wrinkle"]
        d = d + (1 - np.clip(nl / 0.012, 0, 1)) * nl_mask
        # kulaklar
        er = p["ear"]
        ear = ell(ax, y - 0.0035 * p["asym"] * sgn, z, (0.076 * w + 0.002 + 0.002 * p["asym"] * sgn, -0.012, -0.014), (0.009 * er, 0.031 * er, 0.019 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.0725 * w, -0.012, -0.007), (0.006, 0.014, 0.009)), 0.005)
        # boyun
        nw = p["neck_w"] * (0.9 if self.fem else 1.0)
        neck = cap(x, y, z, (0.0, -0.1, -0.04), (0.0, -0.25, -0.05), 0.0485 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.045), (0.0, -0.31, -0.05), 0.06 * nw))
        d = smin(d, neck, 0.016)
        if not self.fem:
            d = smin(d, sph(x, y, z, (0, -0.145, 0.0), 0.0075), 0.012)
        # kas (trapez) yumuşak çıkıntı
        # kırışıklıklar: alın çizgileri, kaz ayağı
        wr = p["wrinkle"] * (0.25 + 0.75 * self.age)
        if wr > 0.02:
            fore = ss(0.036, 0.05, y) * (1 - ss(0.085, 0.1, y)) * ss(0.02, 0.07, z) * (1 - ss(0.055, 0.075, ax))
            lines = np.maximum(0, np.sin(y * 2 * np.pi / 0.0115 + noise3(x, y, z, 55, 3) * 2.5))
            d = d + fore * lines * 0.0017 * wr
            glabella = cap(ax, y, z, (0.006, 0.026, 0.092), (0.007, 0.046, 0.088), 0.0025)
            d = d + (1 - np.clip(glabella / 0.01, 0, 1)) * 0.0016 * wr
            feet = ss(0.046, 0.058, ax) * (1 - ss(0.074, 0.084, ax)) * (1 - ss(0.026, 0.04, np.abs(y - 0.006))) * ss(0.01, 0.06, z)
            fl = np.maximum(0, np.sin((np.arctan2(y - 0.006, ax - 0.05) + 3.14159) * 7.0))
            d = d + feet * fl * 0.0009 * wr
        # gözenek / deri dokusu (geometrik mikro kabarıklık)
        micro = (noise3(x, y, z, 110, 9) - 0.5) * 0.0005 * (0.3 + wr)
        return d + micro

    def skin_behzat(self, x, y, z):
        """47 yaş, geniş ve ağır erkek yüzü. Eski çene/dudak heykeli kullanılmaz."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0018 * asym * sgn
        xz = x - 0.0016 * asym
        d = ell(x, y, z, (0, 0.02, -0.016), (0.076 * w, 0.102 * p["head_h"], 0.084 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.05, 0.014), (0.056 * w, 0.03, 0.042)), 0.028)
        d = smin(d, sph(ax, yy, z, (0.045 * w, -0.004, 0.038), 0.0155 * p["cheek"]), 0.026)
        if p["cheek_hollow"] > 0:
            hol = ell(ax, y, z, (0.054 * w, -0.04, 0.034), (0.015, 0.02, 0.02))
            d = d + (1.0 - np.clip(hol / 0.026, 0, 1)) * 0.003 * p["cheek_hollow"]
        d = smin(d, cap(ax, y, z, (0.056 * jw * w, -0.026, -0.006), (0.02 * jw, -0.096, 0.02), 0.015), 0.02)
        d = smin(d, sph(ax, y, z, (0.054 * jw * w, -0.06, -0.002), 0.013), 0.014)
        d = smin(d, ell(xz, y, z, (0, -0.088, 0.046), (0.026 * jw, 0.018, 0.016)), 0.026)
        d = smin(d, ell(x, y, z, (0, -0.108, 0.006), (0.02 * jw, 0.006, 0.012)), 0.014)
        if p["jowl"] > 0.01:
            d = smin(d, sph(ax, y, z, (0.042 * jw * w, -0.072, 0.02), 0.008 + 0.006 * p["jowl"]), 0.016)
        outer_y = 0.034 + 0.006 * p["brow_tilt"]
        brow_r = 0.0054 + 0.002 * p["brow"]
        brow = cap(ax, yy, z, (0.008, 0.033, 0.052), (0.05 * w, outer_y, 0.044), brow_r)
        d = smin(d, brow, 0.012)
        sock_c = (0.03 * w, 0.01, 0.054 - 0.008 * (p["eye_depth"] - 1.0))
        sock = ell(ax, yy, z, sock_c, (0.0165 * p["eye_size"], 0.0105 * p["eye_size"], 0.013))
        d = smax(d, -sock, 0.009)
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.008, sock_c[2] + 0.004), (0.015 * p["eye_size"], 0.0038, 0.006))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.007, sock_c[2] + 0.004), (0.0145 * p["eye_size"], 0.0036, 0.007))
        d = smin(d, lid_up, 0.005)
        d = smin(d, lid_lo, 0.004)
        if p["eye_bag"] > 0.01:
            bag = ell(ax, yy, z, (0.031 * w, -0.004, sock_c[2] + 0.01), (0.015, 0.0065 * p["eye_bag"], 0.01))
            d = smin(d, bag, 0.007)
            crease = ell(ax, y, z, (0.032 * w, -0.012, sock_c[2] + 0.012), (0.015, 0.0016, 0.008))
            d = d + (1 - np.clip(crease / 0.006, 0, 1)) * 0.0012 * p["eye_bag"]
        tip_y = -0.04 - 0.01 * p["nose_hook"]
        tip_z = 0.078 + 0.01 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.026, 0.058), (0, tip_y + 0.012, tip_z - 0.006), 0.0064 * p["nose_bridge"])
        d = smin(d, bridge, 0.014)
        d = smin(d, sph(x, y, z, (0, 0.004, tip_z - 0.012), 0.0052 * p["nose_bridge"]), 0.008)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.0084 * p["nose_w"], 0.0064, 0.007)), 0.01)
        d = smin(d, sph(ax, y, z, (0.010 * p["nose_w"], tip_y + 0.002, tip_z - 0.01), 0.0072 * p["nose_w"]), 0.008)
        nostril = ell(ax, y, z, (0.0058 * p["nose_w"], tip_y - 0.001, tip_z - 0.002), (0.0026, 0.0022, 0.0042))
        d = smax(d, -nostril, 0.002)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.004, tip_z - 0.004), (0, tip_y - 0.006, tip_z - 0.008), 0.0018), 0.003)
        mw = p["mouth_w"]
        upper = ell(ax, y, z, (0, -0.056, 0.064), (0.018 * mw, 0.0032, 0.0042))
        lower = ell(ax, y, z, (0, -0.066, 0.06), (0.017 * mw, 0.007, 0.005))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.016)
        md = p["mouth_down"]
        mline = cap(ax, y, z, (0.0, -0.059, 0.07), (0.017 * mw, -0.062 - 0.002 * md, 0.064), 0.00045)
        d = smax(d, -mline, 0.0008)
        phil = cap(xz, y, z, (0, tip_y - 0.004, tip_z - 0.01), (0, -0.054, 0.064), 0.0016)
        d = smax(d, -phil, 0.0014)
        d = smax(d, -ell(x, y, z, (0, -0.078, 0.05), (0.01, 0.0014, 0.004)), 0.002)
        nl = cap(ax, y, z, (0.014, -0.032, 0.07), (0.026 * mw, -0.07, 0.052), 0.0036)
        d = d + (1 - np.clip(nl / 0.01, 0, 1)) * (0.0016 + 0.0014 * p["wrinkle"])
        er = p["ear"]
        ear = ell(ax, y - 0.004 * asym * sgn, z, (0.074 * w, -0.01, -0.012), (0.009 * er, 0.03 * er, 0.018 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.07 * w, -0.01, -0.006), (0.0055, 0.013, 0.008)), 0.005)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.03), (0.0, -0.25, -0.04), 0.05 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.038), (0.0, -0.31, -0.042), 0.062 * nw))
        d = smin(d, neck, 0.016)
        d = smin(d, sph(x, y, z, (0, -0.142, 0.002), 0.008), 0.01)
        wr = p["wrinkle"] * (0.35 + 0.65 * self.age)
        if wr > 0.02:
            fore = ss(0.04, 0.055, y) * (1 - ss(0.09, 0.105, y)) * ss(0.01, 0.06, z) * (1 - ss(0.05, 0.07, ax))
            lines = np.maximum(0, np.sin(y * 2 * np.pi / 0.0105 + noise3(x, y, z, 48, 3) * 2.2))
            d = d + fore * lines * 0.0015 * wr
            glabella = cap(ax, y, z, (0.004, 0.022, 0.07), (0.008, 0.04, 0.062), 0.0022)
            d = d + (1 - np.clip(glabella / 0.009, 0, 1)) * 0.0014 * wr
            feet = ss(0.04, 0.052, ax) * (1 - ss(0.07, 0.082, ax)) * (1 - ss(0.02, 0.034, np.abs(yy - 0.008))) * ss(0.02, 0.06, z)
            fl = np.maximum(0, np.sin((np.arctan2(yy - 0.008, ax - 0.046) + 3.14159) * 6.0))
            d = d + feet * fl * 0.0008 * wr
        micro = (noise3(x, y, z, 140, 9) - 0.5) * 0.00045 * (0.35 + p["pores"])
        return d + micro

    def skin_hayalet(self, x, y, z):
        """34 yaş, ince uzun kemikli yüz. Behzat heykeli kullanılmaz."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0012 * asym * sgn
        xz = x + 0.0011 * asym
        d = ell(x, y, z, (0, 0.02, -0.02), (0.064 * w, 0.112 * p["head_h"], 0.078 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.058, 0.006), (0.042 * w, 0.024, 0.03)), 0.022)
        temple = ell(ax, y, z, (0.05 * w, 0.028, 0.0), (0.012, 0.02, 0.016))
        d = d + (1.0 - np.clip(temple / 0.02, 0, 1)) * 0.004
        d = smin(d, sph(ax, yy, z, (0.038 * w, 0.002, 0.032), 0.011 * p["cheek"]), 0.02)
        hol = ell(ax, y, z, (0.04 * w, -0.032, 0.028), (0.012, 0.02, 0.016))
        d = d + (1.0 - np.clip(hol / 0.02, 0, 1)) * 0.005 * max(p["cheek_hollow"], 0.4)
        d = smin(d, cap(ax, y, z, (0.036 * jw * w, -0.02, -0.008), (0.01 * jw, -0.102, 0.016), 0.009), 0.016)
        d = smin(d, ell(xz, y, z, (0, -0.092, 0.042), (0.013 * jw, 0.018, 0.012)), 0.022)
        brow = cap(ax, yy, z, (0.006, 0.034, 0.05), (0.042 * w, 0.032, 0.042), 0.0042 + 0.0012 * p["brow"])
        d = smin(d, brow, 0.01)
        sock_c = (0.026 * w, 0.012, 0.042)
        sock = ell(ax, yy, z, sock_c, (0.015 * p["eye_size"], 0.011 * p["eye_size"], 0.012))
        d = smax(d, -sock, 0.008)
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.009, sock_c[2] + 0.003), (0.014 * p["eye_size"], 0.0022, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.006, sock_c[2] + 0.003), (0.012 * p["eye_size"], 0.0026, 0.004))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        if p["eye_bag"] > 0.01:
            bag = ell(ax, yy, z, (0.026 * w, 0.002, sock_c[2] + 0.008), (0.012, 0.0035 * p["eye_bag"], 0.007))
            d = smin(d, bag, 0.005)
        tip_y = -0.046 - 0.008 * p["nose_hook"]
        tip_z = 0.074 + 0.01 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.03, 0.055), (0, tip_y + 0.012, tip_z - 0.008), 0.0048 * p["nose_bridge"])
        d = smin(d, bridge, 0.01)
        d = smin(d, sph(x, y, z, (0, 0.006, tip_z - 0.016), 0.0036 * p["nose_bridge"]), 0.006)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.0062 * p["nose_w"], 0.0054, 0.0062)), 0.008)
        d = smin(d, sph(ax, y, z, (0.007 * p["nose_w"], tip_y + 0.001, tip_z - 0.008), 0.0048 * p["nose_w"]), 0.006)
        nostril = ell(ax, y, z, (0.0042 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.002, 0.0018, 0.0036))
        d = smax(d, -nostril, 0.0018)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.004, tip_z - 0.003), (0, tip_y - 0.005, tip_z - 0.006), 0.0014), 0.002)
        mw = p["mouth_w"]
        upper = ell(ax, y, z, (0, -0.062, 0.056), (0.016 * mw, 0.0018, 0.0032))
        lower = ell(ax, y, z, (0, -0.07, 0.052), (0.015 * mw, 0.005, 0.004))
        d = smin(d, upper, 0.008)
        d = smin(d, lower, 0.012)
        mline = cap(ax, y, z, (0.0, -0.064, 0.06), (0.015 * mw, -0.066, 0.055), 0.0004)
        d = smax(d, -mline, 0.0007)
        phil = cap(xz, y, z, (0, tip_y - 0.004, tip_z - 0.008), (0, -0.06, 0.058), 0.0014)
        d = smax(d, -phil, 0.0012)
        d = smax(d, -ell(x, y, z, (0, -0.082, 0.046), (0.008, 0.0012, 0.003)), 0.0016)
        nl = cap(ax, y, z, (0.012, -0.04, 0.06), (0.02 * mw, -0.072, 0.046), 0.0028)
        d = d + (1 - np.clip(nl / 0.01, 0, 1)) * 0.0011 * p["wrinkle"]
        er = p["ear"] * 0.92
        ear = ell(ax, y - 0.002 * asym * sgn, z, (0.062 * w, 0.0, -0.016), (0.008 * er, 0.028 * er, 0.016 * er))
        d = smin(d, ear, 0.007)
        d = smax(d, -ell(ax, y, z, (0.058 * w, 0.0, -0.01), (0.0045, 0.012, 0.007)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.028), (0.0, -0.26, -0.034), 0.04 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.26, -0.032), (0.0, -0.32, -0.036), 0.05 * nw))
        d = smin(d, neck, 0.014)
        wr = p["wrinkle"] * (0.2 + 0.4 * self.age)
        if wr > 0.02:
            fore = ss(0.05, 0.065, y) * (1 - ss(0.09, 0.1, y)) * ss(0.0, 0.05, z) * (1 - ss(0.04, 0.055, ax))
            lines = np.maximum(0, np.sin(y * 2 * np.pi / 0.012))
            d = d + fore * lines * 0.0007 * wr
        micro = (noise3(x, y, z, 150, 9) - 0.5) * 0.00035 * (0.3 + p["pores"])
        return d + micro

    def skin_akbaba(self, x, y, z):
        """42 yaş, kemikli ve keskin erkek yüzü. Behzat ve Hayalet heykeli kullanılmaz."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0014 * asym * sgn
        xz = x - 0.0012 * asym
        d = ell(x, y, z, (0, 0.016, -0.018), (0.068 * w, 0.104 * p["head_h"], 0.08 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.052, 0.008), (0.046 * w, 0.024, 0.032)), 0.02)
        temple = ell(ax, y, z, (0.052 * w, 0.024, 0.0), (0.012, 0.018, 0.014))
        d = d + (1.0 - np.clip(temple / 0.02, 0, 1)) * 0.0035
        d = smin(d, sph(ax, yy, z, (0.042 * w, 0.0, 0.044), 0.011 * p["cheek"]), 0.012)
        hol = ell(ax, y, z, (0.046 * w, -0.034, 0.03), (0.012, 0.018, 0.014))
        d = d + (1.0 - np.clip(hol / 0.02, 0, 1)) * 0.004 * p["cheek_hollow"]
        d = smin(d, cap(ax, y, z, (0.048 * jw * w, -0.02, -0.004), (0.016 * jw, -0.096, 0.022), 0.011), 0.014)
        d = smin(d, sph(ax, y, z, (0.046 * jw * w, -0.055, 0.0), 0.01), 0.01)
        d = smin(d, ell(xz, y, z, (0, -0.09, 0.046), (0.018 * jw, 0.016, 0.013)), 0.02)
        outer_y = 0.03 + 0.008 * p["brow_tilt"]
        brow = cap(ax, yy, z, (0.006, 0.034, 0.055), (0.046 * w, outer_y, 0.046), 0.0052 + 0.0016 * p["brow"])
        d = smin(d, brow, 0.01)
        sock_c = (0.028 * w, 0.011, 0.048)
        sock = ell(ax, yy, z, sock_c, (0.016 * p["eye_size"], 0.0115 * p["eye_size"], 0.012))
        d = smax(d, -sock, 0.008)
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.01, sock_c[2] + 0.003), (0.014 * p["eye_size"], 0.002, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.007, sock_c[2] + 0.003), (0.013 * p["eye_size"], 0.0028, 0.004))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.028 * w, 0.0, sock_c[2] + 0.008), (0.013, 0.004 * max(p["eye_bag"], 0.3), 0.008))
        d = smin(d, bag, 0.005)
        tip_y = -0.042 - 0.008 * p["nose_hook"]
        tip_z = 0.076 + 0.008 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.028, 0.056), (0, tip_y + 0.012, tip_z - 0.006), 0.0056 * p["nose_bridge"])
        d = smin(d, bridge, 0.011)
        d = smin(d, sph(x, y, z, (0, 0.004, tip_z - 0.014), 0.0044 * p["nose_bridge"]), 0.006)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.0074 * p["nose_w"], 0.0058, 0.0064)), 0.008)
        d = smin(d, sph(ax, y, z, (0.0085 * p["nose_w"], tip_y + 0.001, tip_z - 0.009), 0.0058 * p["nose_w"]), 0.006)
        nostril = ell(ax, y, z, (0.005 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.0022, 0.002, 0.0038))
        d = smax(d, -nostril, 0.0018)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.004, tip_z - 0.003), (0, tip_y - 0.005, tip_z - 0.006), 0.0015), 0.002)
        mw = p["mouth_w"]
        md = p["mouth_down"]
        upper = ell(ax, y, z, (0, -0.058, 0.058), (0.017 * mw, 0.002, 0.0034))
        lower = ell(ax, y, z, (0, -0.066, 0.054), (0.016 * mw, 0.0034, 0.004))
        d = smin(d, upper, 0.008)
        d = smin(d, lower, 0.012)
        mline = cap(ax, y, z, (0.0, -0.061, 0.062), (0.016 * mw, -0.064 - 0.002 * md, 0.056), 0.0004)
        d = smax(d, -mline, 0.0007)
        phil = cap(xz, y, z, (0, tip_y - 0.004, tip_z - 0.008), (0, -0.056, 0.06), 0.0015)
        d = smax(d, -phil, 0.0012)
        d = smax(d, -ell(x, y, z, (0, -0.078, 0.048), (0.01, 0.0012, 0.0035)), 0.0016)
        nl = cap(ax, y, z, (0.014, -0.036, 0.064), (0.022 * mw, -0.068, 0.05), 0.003)
        d = d + (1 - np.clip(nl / 0.01, 0, 1)) * (0.0008 + 0.001 * p["wrinkle"])
        er = p["ear"]
        ear = ell(ax, y - 0.002 * asym * sgn, z, (0.066 * w, -0.004, -0.014), (0.008 * er, 0.028 * er, 0.016 * er))
        d = smin(d, ear, 0.007)
        d = smax(d, -ell(ax, y, z, (0.062 * w, -0.004, -0.008), (0.0048, 0.012, 0.007)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.028), (0.0, -0.25, -0.036), 0.046 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.034), (0.0, -0.31, -0.038), 0.056 * nw))
        d = smin(d, neck, 0.014)
        wr = p["wrinkle"] * 0.7
        if wr > 0.02:
            fore = ss(0.045, 0.06, y) * (1 - ss(0.085, 0.1, y)) * ss(0.0, 0.05, z) * (1 - ss(0.04, 0.06, ax))
            lines = np.maximum(0, np.sin(y * 2 * np.pi / 0.012))
            d = d + fore * lines * 0.0008 * wr
        micro = (noise3(x, y, z, 150, 11) - 0.5) * 0.0004 * (0.35 + p["pores"])
        return d + micro

    def skin_player(self, x, y, z):
        """31 yaş, geniş çeneli genç erkek. Diğer heykeller kullanılmaz."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.001 * asym * sgn
        xz = x + 0.001 * asym
        d = ell(x, y, z, (0, 0.016, -0.014), (0.066 * w, 0.098 * p["head_h"], 0.082 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.05, 0.006), (0.048 * w, 0.022, 0.032)), 0.022)
        temple = ell(ax, y, z, (0.048 * w, 0.028, 0.0), (0.01, 0.016, 0.012))
        d = d + (1.0 - np.clip(temple / 0.02, 0, 1)) * 0.0016
        d = smin(d, sph(ax, yy, z, (0.042 * w, -0.006, 0.042), 0.01 * p["cheek"]), 0.016)
        d = smin(d, sph(ax, y, z, (0.046 * jw * w, -0.05, 0.002), 0.016), 0.016)
        d = smin(d, cap(ax, y, z, (0.04 * jw, -0.05, 0.008), (0.016, -0.078, 0.032), 0.01), 0.018)
        d = smin(d, sph(xz, y, z, (0, -0.082, 0.042), 0.02), 0.022)
        outer_y = 0.032 + 0.004 * p["brow_tilt"]
        brow = cap(ax, yy, z, (0.008, 0.034, 0.052), (0.044 * w, outer_y, 0.044), 0.004)
        d = smin(d, brow, 0.012)
        sock_c = (0.03 * w, 0.014, 0.058)
        sock = ell(ax, yy, z, sock_c, (0.015 * p["eye_size"], 0.011 * p["eye_size"], 0.016))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.012, sock_c[2] - 0.002), (0.014 * p["eye_size"], 0.0016, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.008, sock_c[2] + 0.002), (0.013 * p["eye_size"], 0.0022, 0.004))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.03 * w, 0.002, sock_c[2] + 0.006), (0.012, 0.0022 * max(p["eye_bag"], 0.1), 0.006))
        d = smin(d, bag, 0.004)
        tip_y = -0.036 - 0.004 * p["nose_hook"]
        tip_z = 0.07 + 0.006 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.03, 0.052), (0, tip_y + 0.01, tip_z - 0.004), 0.005 * p["nose_bridge"])
        d = smin(d, bridge, 0.012)
        d = smin(d, sph(x, y, z, (0, 0.008, tip_z - 0.012), 0.004 * p["nose_bridge"]), 0.006)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.008 * p["nose_w"], 0.0064, 0.007)), 0.01)
        d = smin(d, sph(ax, y, z, (0.008 * p["nose_w"], tip_y + 0.001, tip_z - 0.008), 0.0056 * p["nose_w"]), 0.006)
        nostril = ell(ax, y, z, (0.0046 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.002, 0.0018, 0.0034))
        d = smax(d, -nostril, 0.0016)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.004, tip_z - 0.002), (0, tip_y - 0.004, tip_z - 0.005), 0.0014), 0.002)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.006), (0, -0.05, 0.062), 0.0042), 0.008)
        mw = p["mouth_w"]
        lf = 0.85 + 0.3 * p["lip_full"]
        upper = ell(ax, y, z, (0, -0.052, 0.06), (0.016 * mw, 0.0034 * lf, 0.004))
        lower = ell(ax, y, z, (0, -0.061, 0.056), (0.015 * mw, 0.0038 * lf, 0.0042))
        d = smin(d, upper, 0.012)
        d = smin(d, lower, 0.016)
        mline = cap(ax, y, z, (0.0, -0.057, 0.06), (0.015 * mw, -0.058, 0.054), 0.00035)
        d = smax(d, -mline, 0.0006)
        phil = cap(xz, y, z, (0, tip_y - 0.002, tip_z - 0.01), (0, -0.05, 0.06), 0.0008)
        d = smax(d, -phil, 0.0006)
        nl = cap(ax, y, z, (0.012, -0.03, 0.06), (0.02 * mw, -0.06, 0.048), 0.0026)
        d = d + (1 - np.clip(nl / 0.01, 0, 1)) * 0.0005
        er = p["ear"]
        ear = ell(ax, y - 0.0015 * asym * sgn, z, (0.068 * w, -0.002, -0.012), (0.008 * er, 0.026 * er, 0.015 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.064 * w, -0.002, -0.006), (0.0046, 0.011, 0.006)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.098, -0.026), (0.0, -0.25, -0.034), 0.048 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.032), (0.0, -0.31, -0.036), 0.058 * nw))
        d = smin(d, neck, 0.016)
        wr = p["wrinkle"]
        if wr > 0.02:
            fore = ss(0.05, 0.065, y) * (1 - ss(0.09, 0.105, y)) * ss(0.0, 0.05, z) * (1 - ss(0.04, 0.055, ax))
            lines = np.maximum(0, np.sin(y * 2 * np.pi / 0.016))
            d = d + fore * lines * 0.00035 * wr
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 170, 19) - 0.5) * 0.00028 * (0.4 + p["pores"])
        return d + micro

    def skin_savci(self, x, y, z):
        """38 yaş, oval yüzlü kadın. Diğer heykeller kullanılmaz."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0011 * asym * sgn
        xz = x + 0.001 * asym
        d = ell(x, y, z, (0, 0.012, -0.016), (0.062 * w, 0.102 * p["head_h"], 0.078 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.048, 0.004), (0.044 * w, 0.02, 0.03)), 0.02)
        d = smin(d, sph(ax, yy, z, (0.038 * w, -0.004, 0.04), 0.01 * p["cheek"]), 0.018)
        d = smin(d, cap(ax, y, z, (0.038 * jw * w, -0.02, -0.008), (0.012 * jw, -0.076, 0.024), 0.01), 0.022)
        d = smin(d, ell(xz, y, z, (0, -0.082, 0.04), (0.014, 0.014, 0.012)), 0.02)
        brow = cap(ax, yy, z, (0.006, 0.03, 0.05), (0.038 * w, 0.034, 0.042), 0.0032)
        d = smin(d, brow, 0.01)
        sock_c = (0.026 * w, 0.012, 0.054)
        sock = ell(ax, yy, z, sock_c, (0.016 * p["eye_size"], 0.009 * p["eye_size"], 0.014))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.009, sock_c[2] - 0.002), (0.015 * p["eye_size"], 0.0018, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.007, sock_c[2] - 0.001), (0.014 * p["eye_size"], 0.0018, 0.0035))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        line = ell(ax, yy, z, (0.03 * w, 0.004, sock_c[2] + 0.004), (0.012, 0.0012, 0.004))
        d = d + (1.0 - np.clip(line / 0.008, 0, 1)) * 0.0004 * max(p["eye_bag"], 0.1)
        tip_y = -0.034 - 0.003 * p["nose_hook"]
        tip_z = 0.066 + 0.006 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.028, 0.048), (0, tip_y + 0.01, tip_z - 0.004), 0.004 * p["nose_bridge"])
        d = smin(d, bridge, 0.01)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.0064 * p["nose_w"], 0.0054, 0.006)), 0.008)
        d = smin(d, sph(ax, y, z, (0.0062 * p["nose_w"], tip_y + 0.001, tip_z - 0.006), 0.0044 * p["nose_w"]), 0.005)
        nostril = ell(ax, y, z, (0.0036 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.0016, 0.0015, 0.0028))
        d = smax(d, -nostril, 0.0014)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.005), (0, -0.048, 0.058), 0.0036), 0.007)
        mw = p["mouth_w"]
        md = p["mouth_down"]
        upper = ell(ax, y, z, (0, -0.052, 0.056), (0.014 * mw, 0.0026, 0.0032))
        lower = ell(ax, y, z, (0, -0.06, 0.052), (0.0135 * mw, 0.0034, 0.0036))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.014)
        mline = cap(ax, y, z, (0.0, -0.055, 0.058), (0.013 * mw, -0.056 - 0.002 * md, 0.052), 0.0003)
        d = smax(d, -mline, 0.0005)
        phil = cap(xz, y, z, (0, tip_y - 0.002, tip_z - 0.008), (0, -0.05, 0.056), 0.0007)
        d = smax(d, -phil, 0.0005)
        er = p["ear"]
        ear = ell(ax, y - 0.0012 * asym * sgn, z, (0.06 * w, -0.002, -0.012), (0.007 * er, 0.024 * er, 0.013 * er))
        d = smin(d, ear, 0.007)
        d = smax(d, -ell(ax, y, z, (0.056 * w, -0.002, -0.006), (0.004, 0.01, 0.005)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.096, -0.024), (0.0, -0.25, -0.032), 0.04 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.03), (0.0, -0.31, -0.034), 0.05 * nw))
        d = smin(d, neck, 0.014)
        wr = p["wrinkle"]
        if wr > 0.02:
            fore = ss(0.048, 0.062, y) * (1 - ss(0.086, 0.1, y)) * ss(0.0, 0.045, z) * (1 - ss(0.035, 0.05, ax))
            lines = np.maximum(0, np.sin(y * 2 * np.pi / 0.016))
            d = d + fore * lines * 0.0003 * wr
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 180, 23) - 0.5) * 0.00026 * (0.45 + p["pores"])
        return d + micro

    def skin_arsiv(self, x, y, z):
        """58 yaş, hafif yuvarlak kadın yüzü. Küre değil; kapak, yanak ve çene altı yaşa göre."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0012 * asym * sgn
        xz = x - 0.001 * asym
        d = ell(x, y, z, (0, 0.01, -0.016), (0.068 * w, 0.094 * p["head_h"], 0.076 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.046, 0.004), (0.046 * w, 0.02, 0.03)), 0.022)
        d = smin(d, sph(ax, yy, z, (0.04 * w, -0.016, 0.038), 0.015 * p["cheek"]), 0.024)
        d = smin(d, cap(ax, y, z, (0.042 * jw * w, -0.02, -0.006), (0.02 * jw, -0.074, 0.022), 0.014), 0.026)
        d = smin(d, sph(ax, y, z, (0.038 * jw * w, -0.058, 0.014), 0.012), 0.02)
        d = smin(d, sph(xz, y, z, (0, -0.082, 0.04), 0.02), 0.022)
        d = smin(d, ell(x, y, z, (0, -0.098, 0.006), (0.026, 0.01, 0.016)), 0.016)
        brow = cap(ax, yy, z, (0.006, 0.03, 0.048), (0.036 * w, 0.028, 0.04), 0.0028)
        d = smin(d, brow, 0.01)
        sock_c = (0.028 * w, 0.01, 0.052)
        sock = ell(ax, yy, z, sock_c, (0.015 * p["eye_size"], 0.01 * p["eye_size"], 0.015))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.006, sock_c[2] - 0.001), (0.015 * p["eye_size"], 0.0024, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.008, sock_c[2] + 0.001), (0.014 * p["eye_size"], 0.0024, 0.004))
        d = smin(d, lid_up, 0.005)
        d = smin(d, lid_lo, 0.004)
        bag = ell(ax, yy, z, (0.028 * w, 0.0, 0.056), (0.014, 0.005, 0.008))
        d = smin(d, bag, 0.008)
        feet = cap(ax, yy, z, (0.034 * w, 0.012, 0.05), (0.046 * w, 0.004, 0.04), 0.0005)
        d = d + (1.0 - np.clip(feet / 0.005, 0, 1)) * 0.0007
        tip_y = -0.036
        tip_z = 0.068 + 0.004 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.026, 0.046), (0, tip_y + 0.01, tip_z - 0.004), 0.0046 * p["nose_bridge"])
        d = smin(d, bridge, 0.012)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.008 * p["nose_w"], 0.006, 0.0064)), 0.01)
        d = smin(d, sph(ax, y, z, (0.008 * p["nose_w"], tip_y + 0.001, tip_z - 0.006), 0.0054 * p["nose_w"]), 0.006)
        nostril = ell(ax, y, z, (0.0044 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.0018, 0.0016, 0.003))
        d = smax(d, -nostril, 0.0014)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.005), (0, -0.048, 0.058), 0.0038), 0.008)
        mw = p["mouth_w"]
        upper = ell(ax, y, z, (0, -0.054, 0.056), (0.014 * mw, 0.0022, 0.003))
        lower = ell(ax, y, z, (0, -0.061, 0.052), (0.0135 * mw, 0.0026, 0.0032))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.012)
        mline = cap(ax, y, z, (0.0, -0.057, 0.058), (0.013 * mw, -0.058, 0.052), 0.0003)
        d = smax(d, -mline, 0.0005)
        for ox in (0.005, 0.011, -0.005, -0.011):
            vline = cap(x, y, z, (ox, -0.048, 0.058), (ox, -0.068, 0.048), 0.00035)
            d = d + (1.0 - np.clip(vline / 0.004, 0, 1)) * 0.00055
        fold = cap(ax, y, z, (0.014, -0.03, 0.056), (0.024, -0.064, 0.044), 0.0022)
        d = smin(d, fold, 0.006)
        groove = cap(ax, y, z, (0.01, -0.028, 0.058), (0.02, -0.062, 0.048), 0.0006)
        d = d + (1.0 - np.clip(groove / 0.006, 0, 1)) * 0.0014
        for oy in (0.052, 0.066):
            fore = ell(x, y, z, (0, oy, 0.036), (0.028, 0.0011, 0.016))
            d = d + (1.0 - np.clip(fore / 0.006, 0, 1)) * 0.0007
        er = p["ear"]
        ear = ell(ax, y - 0.001 * asym * sgn, z, (0.064 * w, -0.004, -0.012), (0.007 * er, 0.024 * er, 0.013 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.06 * w, -0.004, -0.006), (0.004, 0.01, 0.005)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.024), (0.0, -0.25, -0.032), 0.044 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.03), (0.0, -0.31, -0.034), 0.054 * nw))
        d = smin(d, neck, 0.016)
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 160, 27) - 0.5) * 0.00024 * (0.4 + p["pores"])
        return d + micro

    def skin_tarik(self, x, y, z):
        """48 yaş, dolgun iş insanı. Kafatası saç kabuğuyla aynı; İdris heykeli kullanılmaz."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0014 * asym * sgn
        xz = x + 0.0014 * asym
        d = self.skull(x, y, z)
        d = smin(d, ell(x, y, z, (0, 0.046, 0.01), (0.05 * w, 0.02, 0.032)), 0.02)
        d = smin(d, sph(ax, yy, z, (0.046 * w, -0.004, 0.04), 0.011), 0.014)
        d = smin(d, sph(ax, yy, z, (0.04 * w, -0.02, 0.042), 0.016 * p["cheek"]), 0.026)
        d = smin(d, cap(ax, y, z, (0.052 * jw * w, -0.018, -0.004), (0.026 * jw, -0.076, 0.022), 0.014), 0.018)
        d = smin(d, sph(ax, y, z, (0.042 * jw * w, -0.06, 0.016), 0.014), 0.02)
        d = smin(d, sph(xz, y, z, (0, -0.084, 0.042), 0.022), 0.022)
        d = smin(d, ell(x, y, z, (0, -0.104, 0.012), (0.034, 0.012, 0.02)), 0.016)
        brow = cap(ax, yy, z, (0.008, 0.032, 0.05), (0.044 * w, 0.028, 0.042), 0.0042)
        d = smin(d, brow, 0.01)
        sock_c = (0.03 * w, 0.012, 0.052)
        sock = ell(ax, yy, z, sock_c, (0.015 * p["eye_size"], 0.008 * p["eye_size"], 0.02))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.005, sock_c[2]), (0.015 * p["eye_size"], 0.0026, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.007, sock_c[2] + 0.001), (0.014 * p["eye_size"], 0.0022, 0.004))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.03 * w, 0.001, 0.056), (0.014, 0.0045, 0.008))
        d = smin(d, bag, 0.007)
        tip_y = -0.036 - 0.004 * p["nose_hook"]
        tip_z = 0.074 + 0.006 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.028, 0.05), (0, tip_y + 0.012, tip_z - 0.004), 0.006 * p["nose_bridge"])
        d = smin(d, bridge, 0.012)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.009 * p["nose_w"], 0.0066, 0.007)), 0.01)
        d = smin(d, sph(ax, y, z, (0.009 * p["nose_w"], tip_y + 0.001, tip_z - 0.007), 0.0062 * p["nose_w"]), 0.006)
        nostril = ell(ax, y, z, (0.005 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.002, 0.0018, 0.0032))
        d = smax(d, -nostril, 0.0015)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.006), (0, -0.05, 0.06), 0.004), 0.008)
        mw = p["mouth_w"]
        upper = ell(ax, y, z, (0, -0.054, 0.058), (0.015 * mw, 0.0026, 0.0032))
        lower = ell(ax, y, z, (0, -0.062, 0.054), (0.0145 * mw, 0.0036, 0.004))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.014)
        mline = cap(ax, y, z, (0.0, -0.057, 0.06), (0.015 * mw, -0.055, 0.054), 0.0003)
        d = smax(d, -mline, 0.0005)
        d = smin(d, sph(x, y, z, (0.016, -0.053, 0.055), 0.0032), 0.004)
        fold = cap(ax, y, z, (0.016, -0.03, 0.06), (0.026, -0.064, 0.046), 0.0024)
        d = smin(d, fold, 0.006)
        groove = cap(ax, y, z, (0.012, -0.028, 0.062), (0.022, -0.062, 0.05), 0.0007)
        d = d + (1.0 - np.clip(groove / 0.006, 0, 1)) * 0.0012
        fore = ell(x, y, z, (0, 0.055, 0.04), (0.03, 0.001, 0.016))
        d = d + (1.0 - np.clip(fore / 0.006, 0, 1)) * 0.0005
        er = p["ear"]
        ear = ell(ax, y - 0.001 * asym * sgn, z, (0.072 * w, -0.006, -0.012), (0.008 * er, 0.026 * er, 0.014 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.068 * w, -0.006, -0.006), (0.0044, 0.011, 0.006)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.02), (0.0, -0.25, -0.028), 0.056 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.026), (0.0, -0.31, -0.03), 0.066 * nw))
        d = smin(d, neck, 0.018)
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 150, 33) - 0.5) * 0.00022 * (0.35 + p["pores"])
        return d + micro

    def skin_zafer(self, x, y, z):
        """42 yaş, güneş yemiş şantiye şefi. Kafatası saç kabuğuyla aynı."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0016 * asym * sgn
        xz = x + 0.0016 * asym
        d = self.skull(x, y, z)
        d = smin(d, ell(x, y, z, (0, 0.05, 0.008), (0.052 * w, 0.022, 0.034)), 0.02)
        d = smin(d, sph(ax, yy, z, (0.046 * w, -0.006, 0.044), 0.012 * p["cheek"]), 0.014)
        d = smin(d, sph(ax, yy, z, (0.036 * w, -0.024, 0.036), 0.01), 0.016)
        d = smin(d, cap(ax, y, z, (0.056 * jw * w, -0.016, 0.002), (0.024 * jw, -0.082, 0.028), 0.014), 0.014)
        d = smin(d, sph(ax, y, z, (0.048 * jw * w, -0.042, 0.008), 0.011), 0.01)
        d = smin(d, ell(xz, y, z, (0, -0.078, 0.05), (0.018 * jw, 0.018, 0.016)), 0.026)
        brow = cap(ax, yy, z, (0.006, 0.03, 0.052), (0.046 * w, 0.034, 0.044), 0.0052)
        d = smin(d, brow, 0.01)
        sock_c = (0.03 * w, 0.01, 0.05)
        sock = ell(ax, yy, z, sock_c, (0.013 * p["eye_size"], 0.0054 * p["eye_size"], 0.02))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.0032, sock_c[2] + 0.002), (0.014 * p["eye_size"], 0.0034, 0.005))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.007, sock_c[2] + 0.001), (0.014 * p["eye_size"], 0.002, 0.004))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.03 * w, 0.001, 0.056), (0.013, 0.004, 0.007))
        d = smin(d, bag, 0.006)
        feet = cap(ax, yy, z, (0.036 * w, 0.012, 0.05), (0.048 * w, 0.004, 0.04), 0.0005)
        d = d + (1.0 - np.clip(feet / 0.005, 0, 1)) * 0.0006
        tip_y = -0.038 - 0.006 * p["nose_hook"]
        tip_z = 0.076 + 0.006 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.028, 0.05), (0, tip_y + 0.012, tip_z - 0.004), 0.0062 * p["nose_bridge"])
        d = smin(d, bridge, 0.01)
        d = smin(d, sph(xz, y, z, (0.003 * asym, -0.008, tip_z - 0.012), 0.0032), 0.004)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.0092 * p["nose_w"], 0.0062, 0.0066)), 0.008)
        d = smin(d, sph(ax, y, z, (0.01 * p["nose_w"], tip_y + 0.001, tip_z - 0.007), 0.0064 * p["nose_w"]), 0.006)
        nostril = ell(ax, y, z, (0.0052 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.0022, 0.0018, 0.0034))
        d = smax(d, -nostril, 0.0015)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.006), (0, -0.05, 0.062), 0.004), 0.008)
        mw = p["mouth_w"]
        md = p["mouth_down"]
        upper = ell(ax, y, z, (0, -0.054, 0.06), (0.015 * mw, 0.0024, 0.003))
        lower = ell(ax, y, z, (0, -0.062, 0.054), (0.014 * mw, 0.0032, 0.0036))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.012)
        mline = cap(ax, y, z, (0.0, -0.057, 0.062), (0.015 * mw, -0.06 - 0.003 * md, 0.054), 0.0003)
        d = smax(d, -mline, 0.0005)
        fold = cap(ax, y, z, (0.016, -0.03, 0.062), (0.026, -0.064, 0.048), 0.002)
        d = smin(d, fold, 0.005)
        groove = cap(ax, y, z, (0.012, -0.028, 0.064), (0.022, -0.06, 0.052), 0.0006)
        d = d + (1.0 - np.clip(groove / 0.006, 0, 1)) * 0.001
        fore = ell(x, y, z, (0, 0.055, 0.04), (0.032, 0.0011, 0.016))
        d = d + (1.0 - np.clip(fore / 0.006, 0, 1)) * 0.0006
        er = p["ear"]
        ear = ell(ax, y - 0.0012 * asym * sgn, z, (0.07 * w, -0.006, -0.012), (0.008 * er, 0.026 * er, 0.014 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.066 * w, -0.006, -0.006), (0.0044, 0.011, 0.006)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.022), (0.0, -0.25, -0.03), 0.052 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.028), (0.0, -0.31, -0.032), 0.062 * nw))
        d = smin(d, neck, 0.016)
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 190, 29) - 0.5) * 0.00032 * (0.5 + p["pores"])
        return d + micro

    def skin_mert(self, x, y, z):
        """27 yaş, ince oval, gergin genç erkek. Player'ın geniş çenesinden ayrı."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0012 * asym * sgn
        xz = x + 0.0012 * asym
        d = ell(x, y, z, (0, 0.012, -0.016), (0.062 * w, 0.102 * p["head_h"], 0.08 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.05, 0.004), (0.044 * w, 0.02, 0.03)), 0.02)
        d = smin(d, sph(ax, yy, z, (0.038 * w, -0.004, 0.04), 0.009 * p["cheek"]), 0.016)
        d = smin(d, sph(ax, yy, z, (0.03 * w, -0.022, 0.034), 0.01), 0.018)
        d = smin(d, cap(ax, y, z, (0.04 * jw * w, -0.026, -0.004), (0.016 * jw, -0.078, 0.028), 0.011), 0.02)
        d = smin(d, sph(xz, y, z, (0, -0.08, 0.042), 0.018), 0.026)
        brow = cap(ax, yy, z, (0.005, 0.034, 0.05), (0.04 * w, 0.028, 0.042), 0.0034)
        d = smin(d, brow, 0.01)
        sock_c = (0.027 * w, 0.013, 0.052)
        sock = ell(ax, yy, z, sock_c, (0.0135 * p["eye_size"], 0.0082 * p["eye_size"], 0.02))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.01, sock_c[2] - 0.001), (0.013 * p["eye_size"], 0.0015, 0.0036))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.008, sock_c[2] + 0.001), (0.012 * p["eye_size"], 0.0018, 0.0034))
        d = smin(d, lid_up, 0.003)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.027 * w, 0.003, 0.056), (0.011, 0.0024, 0.005))
        d = smin(d, bag, 0.004)
        line = ell(ax, yy, z, (0.032 * w, 0.006, 0.054), (0.01, 0.001, 0.003))
        d = d + (1.0 - np.clip(line / 0.006, 0, 1)) * 0.00035
        tip_y = -0.036
        tip_z = 0.068 + 0.005 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.028, 0.046), (0, tip_y + 0.012, tip_z - 0.006), 0.0044 * p["nose_bridge"])
        d = smin(d, bridge, 0.01)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.007 * p["nose_w"], 0.0056, 0.0062)), 0.008)
        d = smin(d, sph(ax, y, z, (0.0064 * p["nose_w"], tip_y + 0.001, tip_z - 0.006), 0.0046 * p["nose_w"]), 0.005)
        nostril = ell(ax, y, z, (0.0038 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.0017, 0.0015, 0.0028))
        d = smax(d, -nostril, 0.0014)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.005), (0, -0.048, 0.056), 0.0034), 0.007)
        mw = p["mouth_w"]
        upper = ell(ax, y, z, (0, -0.052, 0.056), (0.014 * mw, 0.0022, 0.003))
        lower = ell(ax, y, z, (0, -0.06, 0.052), (0.0132 * mw, 0.003, 0.0034))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.014)
        mline = cap(ax, y, z, (0.0, -0.055, 0.058), (0.013 * mw, -0.056, 0.052), 0.00028)
        d = smax(d, -mline, 0.0005)
        phil = cap(xz, y, z, (0, tip_y - 0.002, tip_z - 0.008), (0, -0.05, 0.056), 0.0006)
        d = smax(d, -phil, 0.0005)
        er = p["ear"]
        ear = ell(ax, y - 0.001 * asym * sgn, z, (0.062 * w, -0.004, -0.012), (0.007 * er, 0.024 * er, 0.013 * er))
        d = smin(d, ear, 0.007)
        d = smax(d, -ell(ax, y, z, (0.058 * w, -0.004, -0.006), (0.004, 0.01, 0.005)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.098, -0.024), (0.0, -0.25, -0.032), 0.042 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.03), (0.0, -0.31, -0.034), 0.052 * nw))
        d = smin(d, neck, 0.014)
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 170, 19) - 0.5) * 0.0002 * (0.35 + p["pores"])
        return d + micro

    def skin_haldun(self, x, y, z):
        """58 yaş, uzun ve kemikli profesör. Arşiv'in yuvarlak yüzünden ayrı."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0014 * asym * sgn
        xz = x + 0.0014 * asym
        d = ell(x, y, z, (0, 0.02, -0.016), (0.06 * w, 0.112 * p["head_h"], 0.078 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.072, 0.004), (0.048 * w, 0.026, 0.03)), 0.018)
        temple = ell(ax, y, z, (0.046 * w, 0.034, -0.004), (0.012, 0.02, 0.014))
        d = d + (1.0 - np.clip(temple / 0.02, 0, 1)) * 0.0024
        d = smin(d, sph(ax, yy, z, (0.04 * w, -0.002, 0.042), 0.011), 0.012)
        hol = ell(ax, yy, z, (0.032 * w, -0.032, 0.038), (0.012, 0.018, 0.014))
        d = d + (1.0 - np.clip(hol / 0.018, 0, 1)) * 0.0026
        d = smin(d, cap(ax, y, z, (0.04 * jw * w, -0.02, -0.006), (0.015 * jw, -0.088, 0.026), 0.011), 0.016)
        d = smin(d, sph(ax, y, z, (0.03 * jw * w, -0.068, 0.012), 0.008), 0.012)
        d = smin(d, ell(xz, y, z, (0, -0.082, 0.05), (0.015 * jw, 0.02, 0.014)), 0.026)
        brow = cap(ax, yy, z, (0.006, 0.032, 0.05), (0.04 * w, 0.03, 0.042), 0.0042)
        d = smin(d, brow, 0.01)
        sock_c = (0.026 * w, 0.012, 0.044)
        sock = ell(ax, yy, z, sock_c, (0.013 * p["eye_size"], 0.0062 * p["eye_size"], 0.02))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.004, sock_c[2] + 0.002), (0.013 * p["eye_size"], 0.0028, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.007, sock_c[2] + 0.001), (0.012 * p["eye_size"], 0.0018, 0.003))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.026 * w, 0.002, 0.052), (0.012, 0.0032, 0.006))
        d = smin(d, bag, 0.005)
        feet = cap(ax, yy, z, (0.032 * w, 0.012, 0.048), (0.044 * w, 0.004, 0.038), 0.0005)
        d = d + (1.0 - np.clip(feet / 0.005, 0, 1)) * 0.0007
        tip_y = -0.042 - 0.004 * p["nose_hook"]
        tip_z = 0.072 + 0.006 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.03, 0.046), (0, tip_y + 0.014, tip_z - 0.008), 0.005 * p["nose_bridge"])
        d = smin(d, bridge, 0.01)
        d = smin(d, sph(xz, y, z, (0, -0.004, tip_z - 0.01), 0.0036), 0.004)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.0074 * p["nose_w"], 0.0058, 0.0064)), 0.008)
        d = smin(d, sph(ax, y, z, (0.007 * p["nose_w"], tip_y + 0.001, tip_z - 0.006), 0.005 * p["nose_w"]), 0.005)
        nostril = ell(ax, y, z, (0.0042 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.0018, 0.0016, 0.003))
        d = smax(d, -nostril, 0.0014)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.005), (0, -0.052, 0.058), 0.0036), 0.007)
        mw = p["mouth_w"]
        md = p["mouth_down"]
        upper = ell(ax, y, z, (0, -0.056, 0.056), (0.014 * mw, 0.002, 0.0028))
        lower = ell(ax, y, z, (0, -0.064, 0.05), (0.013 * mw, 0.0026, 0.0032))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.012)
        mline = cap(ax, y, z, (0.0, -0.059, 0.058), (0.013 * mw, -0.062 - 0.004 * md, 0.05), 0.00028)
        d = smax(d, -mline, 0.0005)
        for oy in (0.0, 0.004):
            lip = ell(x, y, z, (0.004, -0.066 - oy, 0.05), (0.0012, 0.004, 0.001))
            d = d + (1.0 - np.clip(lip / 0.004, 0, 1)) * 0.00045
        fold = cap(ax, y, z, (0.014, -0.034, 0.058), (0.022, -0.07, 0.044), 0.0016)
        d = smin(d, fold, 0.004)
        groove = cap(ax, y, z, (0.012, -0.032, 0.06), (0.02, -0.066, 0.048), 0.0005)
        d = d + (1.0 - np.clip(groove / 0.005, 0, 1)) * 0.0008
        for fy, fz in ((0.062, 0.048), (0.048, 0.05)):
            fore = ell(x, y, z, (0, fy, fz), (0.026, 0.001, 0.012))
            d = d + (1.0 - np.clip(fore / 0.006, 0, 1)) * 0.0007
        er = p["ear"]
        ear = ell(ax, y - 0.0012 * asym * sgn, z, (0.062 * w, -0.002, -0.014), (0.007 * er, 0.024 * er, 0.012 * er))
        d = smin(d, ear, 0.007)
        d = smax(d, -ell(ax, y, z, (0.058 * w, -0.002, -0.008), (0.0038, 0.01, 0.005)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.024), (0.0, -0.25, -0.032), 0.044 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.03), (0.0, -0.31, -0.034), 0.054 * nw))
        d = smin(d, neck, 0.014)
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 210, 17) - 0.5) * 0.00028 * (0.45 + p["pores"])
        return d + micro

    def skin_idris(self, x, y, z):
        """54 yaş, geniş çeneli otoriter erkek. Zafer'in yıpranmış şantiye yüzünden ayrı."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.0022 * asym * sgn
        xz = x + 0.002 * asym
        d = ell(x, y, z, (0, 0.014, -0.012), (0.07 * w, 0.1 * p["head_h"], 0.084 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.055, 0.008), (0.056 * w, 0.024, 0.034)), 0.018)
        temple = ell(ax, y, z, (0.052 * w, 0.03, -0.002), (0.012, 0.018, 0.014))
        d = d + (1.0 - np.clip(temple / 0.02, 0, 1)) * 0.002
        d = smin(d, sph(ax, yy, z, (0.048 * w, -0.004, 0.046), 0.012), 0.012)
        d = smin(d, cap(ax, y, z, (0.056 * jw * w, -0.014, 0.0), (0.02 * jw, -0.084, 0.03), 0.014), 0.012)
        d = smin(d, sph(ax, y, z, (0.05 * jw * w, -0.04, 0.012), 0.012), 0.01)
        d = smin(d, sph(ax, y, z, (0.038 * jw * w, -0.068, 0.016), 0.01), 0.012)
        d = smin(d, ell(xz, y, z, (0, -0.084, 0.05), (0.02 * jw, 0.016, 0.014)), 0.024)
        brow = cap(ax, yy, z, (0.006, 0.028, 0.054), (0.048 * w, 0.034, 0.046), 0.006)
        d = smin(d, brow, 0.01)
        sock_c = (0.03 * w, 0.01, 0.046)
        sock = ell(ax, yy, z, sock_c, (0.014 * p["eye_size"], 0.0064 * p["eye_size"], 0.02))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.003, sock_c[2] + 0.002), (0.014 * p["eye_size"], 0.0032, 0.005))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.006, sock_c[2] + 0.001), (0.013 * p["eye_size"], 0.002, 0.004))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.03 * w, 0.0, 0.054), (0.014, 0.004, 0.007))
        d = smin(d, bag, 0.006)
        feet = cap(ax, yy, z, (0.034 * w, 0.01, 0.05), (0.048 * w, 0.002, 0.04), 0.0005)
        d = d + (1.0 - np.clip(feet / 0.005, 0, 1)) * 0.0006
        tip_y = -0.04 - 0.004 * p["nose_hook"]
        tip_z = 0.076 + 0.006 * (p["nose_len"] - 1.0)
        bridge = cap(x, y, z, (0, 0.028, 0.05), (0, tip_y + 0.014, tip_z - 0.008), 0.0056 * p["nose_bridge"])
        d = smin(d, bridge, 0.01)
        d = smin(d, sph(xz, y, z, (0, -0.006, tip_z - 0.012), 0.0038), 0.004)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.0084 * p["nose_w"], 0.0064, 0.007)), 0.008)
        d = smin(d, sph(ax, y, z, (0.009 * p["nose_w"], tip_y + 0.001, tip_z - 0.007), 0.006 * p["nose_w"]), 0.006)
        nostril = ell(ax, y, z, (0.005 * p["nose_w"], tip_y - 0.001, tip_z - 0.002), (0.0022, 0.0018, 0.0032))
        d = smax(d, -nostril, 0.0015)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.006), (0, -0.052, 0.062), 0.004), 0.008)
        mw = p["mouth_w"]
        md = p["mouth_down"]
        upper = ell(ax, y, z, (0, -0.056, 0.06), (0.015 * mw, 0.0022, 0.003))
        lower = ell(ax, y, z, (0, -0.064, 0.054), (0.014 * mw, 0.0032, 0.0036))
        d = smin(d, upper, 0.01)
        d = smin(d, lower, 0.014)
        mline = cap(ax, y, z, (0.0, -0.059, 0.062), (0.014 * mw, -0.062 - 0.004 * md, 0.052), 0.0003)
        d = smax(d, -mline, 0.0005)
        fold = cap(ax, y, z, (0.016, -0.032, 0.064), (0.028, -0.07, 0.048), 0.0022)
        d = smin(d, fold, 0.005)
        groove = cap(ax, y, z, (0.014, -0.03, 0.066), (0.024, -0.066, 0.052), 0.0006)
        d = d + (1.0 - np.clip(groove / 0.006, 0, 1)) * 0.001
        for fy in (0.058, 0.046):
            fore = ell(x, y, z, (0, fy, 0.05), (0.032, 0.0011, 0.014))
            d = d + (1.0 - np.clip(fore / 0.006, 0, 1)) * 0.0008
        er = p["ear"]
        ear = ell(ax, y - 0.0016 * asym * sgn, z, (0.072 * w, -0.004, -0.012), (0.008 * er, 0.026 * er, 0.014 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.068 * w, -0.004, -0.006), (0.0044, 0.011, 0.006)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.1, -0.02), (0.0, -0.25, -0.028), 0.058 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.026), (0.0, -0.31, -0.03), 0.068 * nw))
        d = smin(d, neck, 0.016)
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 180, 23) - 0.5) * 0.00026 * (0.45 + p["pores"])
        return d + micro

    def skin_nevzat(self, x, y, z):
        """48 yaş, yuvarlak ve terli muhasebeci. Tarık'ın dolgun işadamı yüzünden ayrı."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        sgn = np.sign(x)
        asym = p["asym"]
        yy = y - 0.001 * asym * sgn
        xz = x + 0.001 * asym
        d = ell(x, y, z, (0, 0.01, -0.012), (0.072 * w, 0.09 * p["head_h"], 0.08 * p["head_d"]))
        d = smin(d, ell(x, y, z, (0, 0.042, 0.006), (0.05 * w, 0.02, 0.03)), 0.02)
        d = smin(d, sph(ax, yy, z, (0.04 * w, -0.012, 0.04), 0.014 * p["cheek"]), 0.02)
        d = smin(d, cap(ax, y, z, (0.042 * jw * w, -0.02, -0.004), (0.018 * jw, -0.072, 0.026), 0.012), 0.02)
        d = smin(d, sph(xz, y, z, (0, -0.07, 0.038), 0.016), 0.018)
        brow = cap(ax, yy, z, (0.006, 0.03, 0.048), (0.04 * w, 0.028, 0.04), 0.0036)
        d = smin(d, brow, 0.01)
        sock_c = (0.028 * w, 0.012, 0.05)
        sock = ell(ax, yy, z, sock_c, (0.013 * p["eye_size"], 0.0064 * p["eye_size"], 0.018))
        lid_up = ell(ax, yy, z, (sock_c[0], sock_c[1] + 0.006, sock_c[2]), (0.014 * p["eye_size"], 0.0022, 0.004))
        lid_lo = ell(ax, yy, z, (sock_c[0], sock_c[1] - 0.007, sock_c[2] + 0.001), (0.013 * p["eye_size"], 0.002, 0.0035))
        d = smin(d, lid_up, 0.004)
        d = smin(d, lid_lo, 0.003)
        bag = ell(ax, yy, z, (0.028 * w, 0.002, 0.054), (0.013, 0.003, 0.006))
        d = smin(d, bag, 0.005)
        tip_y = -0.034
        tip_z = 0.07
        bridge = cap(x, y, z, (0, 0.026, 0.046), (0, tip_y + 0.012, tip_z - 0.006), 0.0048 * p["nose_bridge"])
        d = smin(d, bridge, 0.01)
        d = smin(d, ell(xz, y, z, (0, tip_y, tip_z), (0.008 * p["nose_w"], 0.006, 0.0064)), 0.008)
        d = smin(d, sph(ax, y, z, (0.007 * p["nose_w"], tip_y + 0.001, tip_z - 0.006), 0.005 * p["nose_w"]), 0.005)
        nostril = ell(ax, y, z, (0.0042 * p["nose_w"], tip_y - 0.001, tip_z - 0.001), (0.0018, 0.0016, 0.003))
        d = smax(d, -nostril, 0.0014)
        d = smin(d, cap(xz, y, z, (0, tip_y + 0.002, tip_z - 0.005), (0, -0.048, 0.058), 0.0036), 0.007)
        mw = p["mouth_w"]
        upper = ell(ax, y, z, (0, -0.05, 0.054), (0.014 * mw, 0.0024, 0.0026))
        lower = ell(ax, y, z, (0, -0.056, 0.052), (0.0135 * mw, 0.0026, 0.0028))
        d = smin(d, upper, 0.008)
        d = smin(d, lower, 0.01)
        mline = cap(ax, y, z, (0.0, -0.053, 0.055), (0.012 * mw, -0.054, 0.05), 0.00018)
        d = smax(d, -mline, 0.0005)
        er = p["ear"]
        ear = ell(ax, y, z, (0.07 * w, -0.004, -0.01), (0.008 * er, 0.024 * er, 0.013 * er))
        d = smin(d, ear, 0.008)
        d = smax(d, -ell(ax, y, z, (0.066 * w, -0.004, -0.004), (0.004, 0.01, 0.005)), 0.004)
        nw = p["neck_w"]
        neck = cap(x, y, z, (0.0, -0.096, -0.02), (0.0, -0.25, -0.028), 0.05 * nw)
        neck = np.minimum(neck, cap(x, y, z, (0.0, -0.25, -0.026), (0.0, -0.31, -0.03), 0.06 * nw))
        d = smin(d, neck, 0.016)
        d = smax(d, -sock, 0.004)
        micro = (noise3(x, y, z, 160, 11) - 0.5) * 0.00022 * (0.4 + p["pores"])
        return d + micro

    # --------------------------------------------------------------- saç
    def hairline(self, x, y, z):
        p = self.p
        h = p["hair"]
        rec = h.get("recede", 0.0)
        front = 0.07 + 0.03 * rec - 0.028 * h.get("front", 0.0) + 0.004 * (noise3(x, y, z, 120, 21) - 0.5) * 2
        # şakaklarda alın girintisi (M şekli)
        front = front + 0.012 * rec * (1 - ss(0.0, 0.05, np.abs(x)))
        if p.get("sculpt") == "behzat":
            temples = ss(0.02, 0.046, np.abs(x)) * (1 - ss(0.06, 0.08, np.abs(x)))
            front = front + 0.02 * max(rec, 0.2) * temples
        side = 0.004 - 0.003 * ss(0.05, 0.075, np.abs(x))
        back = -0.075
        t_side = ss(0.045, 0.072, np.abs(x))
        t_back = ss(0.02, -0.04, z)
        hl = front * (1 - t_side) + side * t_side
        hl = hl * (1 - t_back) + back * t_back
        return hl

    def hair(self, x, y, z):
        p = self.p
        h = p["hair"]
        st = h["style"]
        if st == "none":
            return np.full(np.broadcast(x, y, z).shape, 1.0, dtype=F)
        vol = h.get("volume", 1.0)
        thick = {"short": 0.007, "messy": 0.012, "swept": 0.011, "slicked": 0.0065, "bob": 0.012,
                 "long_tied": 0.0095, "bun": 0.009, "thinning": 0.0045}.get(st, 0.008) * vol * (0.75 + 0.25 * h.get("len", 1.0))
        base = self.skull(x, y, z, grow=thick)
        hl = self.hairline(x, y, z)
        region = y - hl
        d = smax(base, -region, 0.004)
        if st == "thinning":
            keep = np.maximum(np.abs(x) - 0.052, -z - 0.045) + (noise3(x, y, z, 90, 4) - 0.5) * 0.02
            d = np.maximum(d, -keep)
        if st in ("swept", "slicked"):
            # arkaya taranmış: üstte hafif tepe + kenar
            d = smin(d, ell(x, y, z, (0, 0.075 if st == "swept" else 0.06, 0.012), (0.067, 0.034 if st == "swept" else 0.026, 0.085)), 0.015)
            d = smax(d, -(y - hl), 0.004)
        if st == "messy":
            d = smin(d, ell(x, y, z, (0, 0.082, 0.0), (0.066, 0.034, 0.08)), 0.02)
            d = smax(d, -(y - hl), 0.004)
            spikes = (noise3(x, y, z, 60, 7) - 0.5) * 0.005 + (noise3(x, y, z, 150, 8) - 0.5) * 0.0018
            d = d + spikes
        if st == "bob":
            back_hair = ell(x, y, z, (0, -0.03, -0.04), (0.088, 0.094, 0.078))
            back_hair = smax(back_hair, z - 0.02, 0.01)
            side_fringe = ell(x, y, z, (0, 0.03, 0.01), (0.087, 0.11, 0.1))
            side_fringe = smax(side_fringe, -(np.abs(x) - 0.072), 0.01)
            side_fringe = smax(side_fringe, -(y + 0.09), 0.01)
            d = smin(d, back_hair, 0.015)
            d = smin(d, side_fringe, 0.01)
            d = smax(d, -(y + 0.09), 0.004)
            if p.get("sculpt") == "savci":
                ear_gap = ell(np.abs(x), y, z, (0.058 * p["head_w"], -0.002, -0.008), (0.012, 0.018, 0.012))
                d = smax(d, -ear_gap, 0.004)
        if st == "long_tied":
            tail = cap(x, y, z, (0, 0.0, -0.092), (0, -0.19, -0.115), 0.028 * h.get("len", 1.0))
            nape = ell(x, y, z, (0, -0.02, -0.06), (0.075, 0.075, 0.06))
            nape = smax(nape, z - 0.0, 0.01)
            d = smin(d, tail, 0.02)
            d = smin(d, nape, 0.01)
        if st == "bun":
            if p.get("sculpt") == "arsiv":
                d = smin(d, sph(x, y, z, (0, 0.0, -0.092), 0.032), 0.012)
            else:
                d = smin(d, sph(x, y, z, (0, 0.07, -0.082), 0.04), 0.015)
        if p.get("sculpt") == "hayalet" and st == "swept":
            d = smin(d, ell(x, y, z, (0.014, 0.068, -0.012), (0.046, 0.026, 0.062)), 0.012)
            side = ss(0.032, 0.05, np.abs(x))
            crop = 0.04 * side + (0.002) * (1.0 - side)
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "akbaba":
            side = ss(0.035, 0.055, np.abs(x))
            crop = 0.05 * side + 0.018 * (1.0 - side)
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "player":
            d = smin(d, ell(x, y, z, (0, 0.08, 0.006), (0.052, 0.02, 0.05)), 0.014)
            for ox, oz in ((-0.018, 0.05), (0.01, 0.056), (0.026, 0.046)):
                d = smin(d, ell(x, y, z, (ox, 0.052, oz), (0.01, 0.007, 0.014)), 0.006)
            side = ss(0.028, 0.048, np.abs(x))
            back = ss(-0.01, -0.05, z)
            crop = 0.05 * side + 0.016 * (1.0 - side) + 0.014 * back
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "arsiv":
            side = ss(0.025, 0.05, np.abs(x))
            back = ss(-0.01, -0.06, z)
            crop = 0.03 * side + 0.025 * back
            d = np.maximum(d, -(y - crop))
            d = smin(d, sph(x, y, z, (0, -0.02, -0.102), 0.034), 0.008)
            for ox, oz in ((-0.016, 0.046), (0.004, 0.05), (0.018, 0.044)):
                d = smin(d, ell(x, y, z, (ox, 0.04, oz), (0.007, 0.012, 0.008)), 0.005)
        if p.get("sculpt") == "tarik":
            shell = self.skull(x, y, z, grow=0.0035)
            shell = smax(shell, -(y - (self.hairline(x, y, z) - 0.006)), 0.003)
            d = smin(d, shell, 0.006)
            side = ss(0.03, 0.052, np.abs(x))
            back = ss(-0.01, -0.05, z)
            crop = 0.0 * (1.0 - side) + 0.04 * side + 0.015 * back
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "mert":
            shell = ell(x, y, z, (0, 0.012, -0.016), (0.062 * p["head_w"] + 0.006, 0.102 * p["head_h"] + 0.004, 0.08 * p["head_d"] + 0.004))
            shell = smax(shell, -(y - (self.hairline(x, y, z) - 0.008)), 0.005)
            d = shell
            d = smin(d, ell(x, y, z, (0, 0.082, 0.002), (0.042, 0.012, 0.038)), 0.012)
            for ox, oz in ((-0.012, 0.038), (0.004, 0.042), (0.016, 0.034)):
                d = smin(d, ell(x, y, z, (ox, 0.062, oz), (0.007, 0.008, 0.01)), 0.005)
            side = ss(0.026, 0.046, np.abs(x))
            back = ss(-0.01, -0.05, z)
            crop = 0.046 * side + 0.02 * (1.0 - side) + 0.01 * back
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "zafer":
            shell = self.skull(x, y, z, grow=0.005)
            shell = smax(shell, -(y - (self.hairline(x, y, z) - 0.01)), 0.005)
            d = smin(d, shell, 0.006)
            band = cap(np.abs(x), y, z, (0.042, 0.05, 0.02), (0.06, 0.012, -0.02), 0.007)
            d = smin(d, band, 0.006)
            side = ss(0.034, 0.054, np.abs(x))
            back = ss(0.0, -0.045, z)
            crop = 0.012 * (1.0 - side) + 0.028 * side + 0.008 * back
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "haldun":
            shell = ell(x, y, z, (0, 0.02, -0.016), (0.06 * p["head_w"] + 0.006, 0.112 * p["head_h"] + 0.004, 0.078 * p["head_d"] + 0.004))
            shell = smax(shell, -(y - (self.hairline(x, y, z) - 0.014)), 0.006)
            d = shell
            d = smin(d, ell(x, y, z, (0, 0.09, -0.02), (0.046, 0.016, 0.05)), 0.01)
            side = ss(0.028, 0.05, np.abs(x))
            back = ss(0.0, -0.05, z)
            crop = 0.02 * (1.0 - side) + 0.04 * side + 0.012 * back
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "idris":
            shell = ell(x, y, z, (0, 0.014, -0.012), (0.07 * p["head_w"] + 0.004, 0.1 * p["head_h"] + 0.003, 0.084 * p["head_d"] + 0.003))
            shell = smax(shell, -(y - (self.hairline(x, y, z) - 0.014)), 0.006)
            d = shell
            d = smin(d, ell(x, y, z, (0, 0.078, -0.016), (0.05, 0.014, 0.05)), 0.01)
            side = ss(0.032, 0.055, np.abs(x))
            back = ss(0.0, -0.05, z)
            crop = 0.016 * (1.0 - side) + 0.038 * side + 0.01 * back
            d = np.maximum(d, -(y - crop))
        if p.get("sculpt") == "nevzat":
            shell = ell(x, y, z, (0, 0.01, -0.012), (0.072 * p["head_w"] + 0.003, 0.09 * p["head_h"] + 0.003, 0.08 * p["head_d"] + 0.002))
            shell = smax(shell, -(y - (self.hairline(x, y, z) - 0.022)), 0.008)
            d = shell
        if st in ("short", "messy", "swept", "slicked", "bun", "thinning") and p.get("sculpt") not in ("behzat", "hayalet", "akbaba", "player", "arsiv", "tarik", "zafer", "mert", "haldun", "idris", "nevzat"):
            # ense: kafatasının altından boyuna kadar inen saç
            rn = 0.0485 * p["neck_w"] * (0.9 if self.fem else 1.0) + 0.005 + thick * 0.4
            low = {"short": -0.098, "messy": -0.116, "swept": -0.108, "slicked": -0.1, "bun": -0.11, "thinning": -0.092}[st]
            nape = cap(x, y, z, (0.0, -0.06, -0.042), (0.0, low, -0.044), rn)
            nape = smax(nape, z + 0.012, 0.012)
            nape = np.maximum(nape, -(y - (low + (noise3(x, y, z, 80, 14) - 0.5) * 0.014)))
            d = smin(d, nape, 0.01)
        if p.get("sculpt") == "behzat":
            crop = -0.008 - 0.016 * ss(0.0, -0.05, z)
            d = np.maximum(d, -(y - crop))
        # tel dokusu: baştan dışa akan şeritler
        ang = np.arctan2(x, z - (-0.012))
        strand = np.sin(ang * 38 + noise3(x, y, z, 30, 12) * 5) * 0.0009
        return d + strand

    ## Kaş bandı: x-y düzleminde iç uç, dış uç, kalınlık. z yok — kaş deri
    ## yüzeyine oturtulur. Önceden her kaş sabit bir z'ye konuyordu; alın
    ## eğrisi hesaba katılmadığı için dış uçta 13 mm'ye varan boşluk kalıyor,
    ## kaşlar yüzün önünde duran düz çubuklar gibi görünüyordu.
    BROWS = {
        "behzat": ((0.005, 0.030), (0.048, 0.026), 0.0036),
        "hayalet": ((0.004, 0.030), (0.040, 0.028), 0.0032),
        "akbaba": ((0.004, 0.032), (0.046, 0.024), 0.0038),
        "player": ((0.006, 0.036), (0.044, 0.034), 0.0030),
        "savci": ((0.005, 0.030), (0.036, 0.034), 0.0022),
        "arsiv": ((0.005, 0.032), (0.034, 0.030), 0.0016),
        "tarik": ((0.006, 0.036), (0.044, 0.032), 0.0032),
        "zafer": ((0.006, 0.022), (0.044, 0.028), 0.0032),
        "mert": ((0.004, 0.034), (0.038, 0.026), 0.0026),
        "haldun": ((0.006, 0.034), (0.038, 0.030), 0.0022),
        "idris": ((0.006, 0.028), (0.048, 0.034), 0.0034),
        "nevzat": ((0.006, 0.032), (0.042, 0.028), 0.0026),
    }

    def surface_layer(self, skin, out, sink=0.0014):
        """Deriden `out` kadar dışarı taşan, `sink` kadar içine gömülen kabuk.
        Kıl bölgeleri bununla kesiştirilince yüzeyin üstüne oturur."""
        return np.maximum(skin - out, -(skin + sink))

    def brows(self, x, y, z, skin=None):
        p = self.p
        if skin is None:
            skin = self.skin(x, y, z)
        t = p["brows"]["thick"]
        sculpt = p.get("sculpt", "")
        if sculpt in self.BROWS:
            a, b, r = self.BROWS[sculpt]
            jitter = 0.0007
        else:
            a, b, r = (0.012, 0.0385), (0.052, 0.0405 + 0.006 * p["brow_tilt"]), 0.0034
            jitter = 0.0018
        w = p["head_w"]
        yy = y - 0.0012 * p["asym"] * np.sign(x)
        ax = np.abs(x)
        # iç uç -> tepe -> dış uç: hafif kemer, dışa doğru incelen kalınlık.
        inner = (a[0], a[1])
        outer = (b[0] * w, b[1])
        peak = (inner[0] + (outer[0] - inner[0]) * 0.62,
                inner[1] + (outer[1] - inner[1]) * 0.62 + 0.0026)
        # eski yarıçaplar 3B kapsül içindi, büyük kısmı derinin içinde kalıyordu;
        # yüzeye oturan bantta aynı değer olduğundan kalın görünüyor.
        rr = r * t * 0.78 + 0.0004
        band = np.minimum(seg2t(ax, yy, inner, peak, rr, rr * 0.95),
                          seg2t(ax, yy, peak, outer, rr * 0.95, rr * 0.42))
        d = smax(self.surface_layer(skin, 0.0017 + 0.0011 * t), band, 0.0011)
        d = smax(d, F(0.012) - z, 0.004)
        return d + (noise3(x, y, z, 260, 31) - 0.5) * jitter

    ## Bıyık bantları: x-y düzleminde (iç uç, dış uç, kalınlık) listesi.
    ## Kaşlarda olduğu gibi z yok; deri yüzeyine oturtulur.
    MUSTACHE = {
        "behzat": [((0.0, -0.050), (0.020, -0.058), 0.0040)],
        "hayalet": [((0.0, -0.054), (0.016, -0.060), 0.0028)],
        "zafer": [((0.0, -0.046), (0.020, -0.057), 0.0042)],
        "haldun": [((0.0, -0.050), (0.018, -0.058), 0.0030),
                   ((0.008, -0.056), (0.004, -0.074), 0.0018)],
        "idris": [((0.0, -0.048), (0.022, -0.058), 0.0048),
                  ((0.016, -0.056), (0.018, -0.066), 0.0028)],
    }
    MUSTACHE_GENERIC = {
        "heavy": [((0.0, -0.0485), (0.022, -0.0585), 0.0068),
                  ((0.022, -0.0585), (0.028, -0.0775), 0.0056)],
        "full": [((0.0, -0.0485), (0.023, -0.0585), 0.0062),
                 ((0.023, -0.0585), (0.027, -0.0730), 0.0050)],
        "trim": [((0.0, -0.0495), (0.019, -0.0555), 0.0042)],
    }

    def mustache(self, x, y, z, skin=None):
        m = self.p["mustache"]
        if m["style"] == "none":
            return None
        if skin is None:
            skin = self.skin(x, y, z)
        size = m["size"]
        s = size * self.p["mouth_w"]
        segs = self.MUSTACHE.get(self.p.get("sculpt", ""))
        if segs is None:
            segs = self.MUSTACHE_GENERIC.get(m["style"], self.MUSTACHE_GENERIC["trim"])
        ax = np.abs(x)
        band = None
        for a, b, r in segs:
            cur = seg2(ax, y, (a[0] * s, a[1]), (b[0] * s, b[1]), r * size)
            band = cur if band is None else np.minimum(band, cur)
        d = smax(self.surface_layer(skin, 0.0024 + 0.0022 * size), band, 0.0012)
        d = smax(d, F(0.012) - z, 0.004)
        return d + (noise3(x, y, z, 230, 41) - 0.5) * 0.0014

    def beard(self, x, y, z):
        b = self.p["beard"]
        st = b["style"]
        if st in ("none", "stubble_beard"):
            return None
        if self.p.get("sculpt") == "hayalet":
            return self.beard_hayalet(x, y, z)
        if self.p.get("sculpt") == "haldun":
            return self.beard_haldun(x, y, z)
        ax = np.abs(x)
        s = b["size"]
        t = {"full": 0.008, "goatee": 0.008, "stubble_beard": 0.0028}[st] * (s if st != "stubble_beard" else 1.0)
        base = self.skin_jaw(x, y, z, t)
        w = self.p["head_w"]
        if st == "goatee":
            reg = np.maximum(ax - 0.026 * s, y + 0.083)
        else:
            reg = y - (-0.032 + 0.028 * ss(0.045, 0.078, ax))
            if st == "stubble_beard":
                reg = y - (-0.028 + 0.03 * ss(0.04, 0.078, ax))
        d = smax(base, reg, 0.004)
        # ağız deliği
        mouth = ell(ax, y, z, (0, -0.0675, 0.09), (0.0235 * self.p["mouth_w"], 0.0095, 0.03))
        d = smax(d, -mouth, 0.003)
        if st == "stubble_beard":
            d = d + (noise3(x, y, z, 380, 51) - 0.52) * 0.006
        else:
            d = d + (noise3(x, y, z, 70, 52) - 0.5) * 0.005 
        return d

    def beard_hayalet(self, x, y, z):
        """İnce yüze oturan tam sakal. Ağız açıklığı durur."""
        p = self.p
        ax = np.abs(x)
        face = self.skin_hayalet(x, y, z)
        shell = np.maximum(face - 0.0026, -face)
        # Üst sınır orta hatta -0.012 idi: burun (y=-0.046) ve üst dudak sakalın
        # içinde kalıyor, yüzün yarısı kara bir kütle oluyordu. Orta hatta alt
        # dudağın altından başlar, yanlarda favoriye yükselir.
        top = -0.074 + 0.085 * ss(0.014, 0.040, ax)
        region = smax(y - top, -(y + 0.112), 0.004)
        region = smax(region, -0.006 - z, 0.004)
        # Yanları dikey bir düzlemle kesmek sakalı yanaktan sarkan düz bir levhaya
        # çeviriyordu; oval maske çene hattını izler, kenarı yumuşak biter.
        oval = (np.sqrt((x / (0.060 * p["head_w"])) ** 2 + ((y + 0.050) / 0.064) ** 2) - 1.0) * 0.05
        region = smax(region, oval.astype(F), 0.008)
        d = smax(shell, region, 0.003)
        mouth = ell(ax, y, z, (0, -0.065, 0.06), (0.014 * p["mouth_w"], 0.005, 0.014))
        d = smax(d, -mouth, 0.0025)
        return d + (noise3(x, y, z, 90, 52) - 0.5) * 0.0016

    def beard_haldun(self, x, y, z):
        """Kısa gri keçi sakalı. Bıyıktan ince bir geçişle iner, dudağı kapatmaz."""
        p = self.p
        ax = np.abs(x)
        d = cap(x, y, z, (0, -0.07, 0.056), (0, -0.09, 0.052), 0.008)
        d = smax(d, ax - 0.015, 0.004)
        return d + (noise3(x, y, z, 140, 52) - 0.48) * 0.0014

    def stubble_shell(self, x, y, z):
        """Üç günlük sakal: yüzde ince, delikli kabuk. Düz renk lekesi değil."""
        p = self.p
        ax = np.abs(x)
        face = self.skin_behzat(x, y, z)
        shell = np.abs(face) - 0.0015
        top = -0.028 + 0.03 * ss(0.036, 0.058, ax)
        region = smax(y - top, -(y + 0.118), 0.004)
        region = smax(region, -(z + 0.015), 0.006)
        region = smax(region, ax - 0.068 * p["head_w"], 0.006)
        d = smax(shell, region, 0.003)
        mouth = ell(ax, y, z, (0, -0.062, 0.068), (0.018 * p["mouth_w"], 0.0055, 0.018))
        d = smax(d, -mouth, 0.003)
        return d + (0.62 - noise3(x, y, z, 220, 51)) * 0.0035

    def skin_jaw(self, x, y, z, grow):
        """Sakalın üzerine oturduğu şişirilmiş alt yüz."""
        p = self.p
        w, jw = p["head_w"], p["jaw_w"]
        ax = np.abs(x)
        d = ell(x, y, z, (0, -0.036, 0.016), (0.066 * w + grow, 0.066 + grow, 0.07 + grow))
        d = smin(d, cap(ax, y, z, (0.064 * jw * w, -0.035, -0.012), (0.026 * jw, -0.099, 0.062), 0.03 + grow), 0.02)
        cs = 0.88 + 0.1 * p["chin"]
        d = smin(d, ell(x, y, z, (0, -0.096, 0.052), (0.022 * jw + grow, 0.016 * cs + grow, 0.014 * cs + grow)), 0.028)
        d = smin(d, sph(ax, y, z, (0.054 * w, -0.016, 0.056), 0.022 * p["cheek"] + grow), 0.02)
        return d


# ---------------------------------------------------------------- renkler
def skin_colors(h, vx, vy, vz):
    p = h.p
    base = hex_lin(p["skin"])
    shade = hex_lin(p["skin_shadow"])
    ax = np.abs(vx)
    n = vx.shape[0]
    col = np.tile(base, (n, 1))
    var = (noise3(vx, vy, vz, 60, 61) - 0.5) * 0.18 + (noise3(vx, vy, vz, 16, 62) - 0.5) * 0.22
    col = col * (1.0 + var[:, None])
    # kızarıklık: yanak, burun, kulak, alın
    red = np.array([0.55, 0.12, 0.08])
    r = p["ruddy"]
    m = gauss(ax, vy, vz, (0.05, -0.03, 0.07), (0.022, 0.03, 0.03)) * 0.55
    m = np.maximum(m, gauss(ax, vy, vz, (0.0, -0.034, 0.112), (0.016, 0.016, 0.016)) * 0.9)
    m = np.maximum(m, gauss(ax, vy, vz, (0.077, -0.012, -0.014), (0.012, 0.03, 0.02)) * 0.8)
    col = col * (1 - (m * r)[:, None] * 0.6) + red * (m * r)[:, None] * 0.6 * col.mean(axis=1, keepdims=True) * 1.4
    # göz çevresi gölge/morluk
    dark = gauss(ax, vy, vz, (0.034, 0.004, 0.08), (0.024, 0.02, 0.02)) * (0.35 + 0.65 * p["eye_bag"])
    dark = dark * 0.5
    col = col * (1 - dark[:, None]) + shade * dark[:, None] * 0.9
    # dudak
    lip_c = {"hayalet": (0, -0.065, 0.058), "behzat": (0, -0.061, 0.068), "akbaba": (0, -0.062, 0.058), "player": (0, -0.058, 0.058), "savci": (0, -0.056, 0.056), "arsiv": (0, -0.057, 0.054), "tarik": (0, -0.058, 0.058), "zafer": (0, -0.058, 0.06), "mert": (0, -0.056, 0.054), "haldun": (0, -0.06, 0.052), "idris": (0, -0.06, 0.056), "nevzat": (0, -0.056, 0.054)}.get(p.get("sculpt"), (0, -0.067, 0.09))
    lip = gauss(ax, vy, vz, lip_c, (0.018, 0.008, 0.016))
    lipc = hex_lin("#8a4a43") if not h.fem else hex_lin("#9a4a50")
    col = col * (1 - lip[:, None] * 0.75) + lipc * lip[:, None] * 0.75
    seam_c = {"hayalet": (0, -0.065, 0.06), "behzat": (0, -0.061, 0.07), "akbaba": (0, -0.061, 0.06), "player": (0, -0.057, 0.06), "savci": (0, -0.055, 0.056), "arsiv": (0, -0.057, 0.056), "tarik": (0, -0.057, 0.06), "zafer": (0, -0.057, 0.062), "mert": (0, -0.055, 0.056), "haldun": (0, -0.059, 0.054), "idris": (0, -0.059, 0.058), "nevzat": (0, -0.055, 0.056)}.get(p.get("sculpt"), (0, -0.0667, 0.092))
    seam = gauss(ax, vy, vz, seam_c, (0.018, 0.0016, 0.01))
    col = col * (1 - seam[:, None] * 0.7) + shade * 0.5 * seam[:, None] * 0.7
    nos_c = {"hayalet": (0.004, -0.05, 0.09), "behzat": (0.0062, -0.044, 0.092), "akbaba": (0.005, -0.042, 0.078), "player": (0.0046, -0.036, 0.072), "savci": (0.0036, -0.034, 0.066), "arsiv": (0.0044, -0.036, 0.068), "tarik": (0.005, -0.036, 0.074), "zafer": (0.0052, -0.04, 0.076), "mert": (0.0038, -0.036, 0.068), "haldun": (0.0042, -0.042, 0.072), "idris": (0.005, -0.04, 0.074), "nevzat": (0.0044, -0.034, 0.068)}.get(p.get("sculpt"), (0.0075, -0.04, 0.105))
    nos = gauss(ax, vy, vz, nos_c, (0.004, 0.0035, 0.006))
    col = col * (1 - nos[:, None] * 0.8)
    # sakal gölgesi: renk (mavimsi gölge) + alfa = shader'da kıllanma maskesi
    alpha = np.zeros(n)
    if p["stubble"] > 0 or p["beard"]["style"] == "stubble_beard":
        amt = max(p["stubble"], 0.8 if p["beard"]["style"] == "stubble_beard" else 0.0)
        st_color = hex_lin(p["stubble_color"])
        reg = ss(-0.022, -0.05, vy) * ss(0.02, 0.07, vz) * (1 - ss(0.074, 0.084, ax) * 0.4)
        reg = np.maximum(reg, gauss(ax, vy, vz, (0.0, -0.052, 0.1), (0.03, 0.009, 0.02)) * 0.9)
        reg = reg * (1 - gauss(ax, vy, vz, (0, -0.067, 0.092), (0.021, 0.0035, 0.02)) * 0.8)
        reg = np.clip(reg + (noise3(vx, vy, vz, 90, 72) - 0.5) * 0.25, 0, 1)
        if p.get("sculpt") == "player":
            chin = gauss(ax, vy, vz, (0.0, -0.082, 0.04), (0.028, 0.016, 0.018))
            lip = gauss(ax, vy, vz, (0.0, -0.05, 0.06), (0.018, 0.006, 0.012))
            reg = np.clip(np.maximum(chin, lip * 0.7) + (noise3(vx, vy, vz, 90, 72) - 0.5) * 0.2, 0, 1)
            grain = np.clip((noise3(vx, vy, vz, 260, 77) - 0.42) * 1.6, 0, 1)
            alpha = reg * amt * 0.55 * grain
        elif p.get("sculpt") == "mert":
            chin = gauss(ax, vy, vz, (0.0, -0.082, 0.038), (0.02, 0.012, 0.014))
            lip = gauss(ax, vy, vz, (0.0, -0.05, 0.056), (0.014, 0.005, 0.01))
            reg = np.clip(np.maximum(chin, lip * 0.55) + (noise3(vx, vy, vz, 90, 72) - 0.5) * 0.15, 0, 1)
            grain = np.clip((noise3(vx, vy, vz, 260, 77) - 0.55) * 1.4, 0, 1)
            alpha = reg * amt * 0.4 * grain
        elif p.get("sculpt") in ("behzat", "akbaba", "zafer"):
            grain = np.clip((noise3(vx, vy, vz, 260, 77) - 0.35) * 1.4, 0, 1)
            alpha = reg * amt * (0.35 + 0.65 * grain)
            spots = gauss(ax, vy, vz, (0.02, 0.04, 0.05), (0.008, 0.006, 0.006))
            spots = np.maximum(spots, gauss(ax, vy, vz, (0.048, -0.02, 0.04), (0.01, 0.008, 0.008)) * 0.7)
            col = col * (1.0 - (spots * 0.22)[:, None])
        else:
            alpha = reg * amt
            col = col * (1 - (alpha * 0.28)[:, None]) + st_color * (alpha * 0.28)[:, None] * 0.6
    if p.get("sculpt") == "arsiv":
        spots = gauss(ax, vy, vz, (0.012, 0.05, 0.04), (0.01, 0.008, 0.008))
        spots = np.maximum(spots, gauss(ax, vy, vz, (0.04, -0.01, 0.04), (0.012, 0.01, 0.01)) * 0.8)
        spots = np.maximum(spots, gauss(ax, vy, vz, (0.02, -0.04, 0.05), (0.008, 0.006, 0.006)) * 0.6)
        col = col * (1.0 - (spots * 0.16)[:, None])
    if p.get("sculpt") == "haldun":
        spots = gauss(ax, vy, vz, (0.01, 0.06, 0.046), (0.01, 0.008, 0.008))
        spots = np.maximum(spots, gauss(ax, vy, vz, (0.036, -0.01, 0.04), (0.01, 0.008, 0.008)) * 0.7)
        col = col * (1.0 - (spots * 0.14)[:, None])
    if p.get("sculpt") == "idris":
        spots = gauss(ax, vy, vz, (0.016, 0.05, 0.05), (0.012, 0.008, 0.008))
        spots = np.maximum(spots, gauss(ax, vy, vz, (0.04, -0.02, 0.04), (0.01, 0.008, 0.008)) * 0.6)
        col = col * (1.0 - (spots * 0.12)[:, None])
    return np.clip(np.concatenate([col, alpha[:, None]], axis=1), 0, 1)


def hair_colors(h, comp_ids, vx, vy, vz):
    p = h.p
    gray = hex_lin("#bdb8b0")
    n = vx.shape[0]
    out = np.zeros((n, 3))
    # 0 saç, 1 kaş, 2 bıyık, 3 sakal
    cols = [hex_lin(p["hair"]["color"]), hex_lin(p["brows"]["color"]),
            hex_lin(p["mustache"]["color"]), hex_lin(p["beard"]["color"])]
    gr = [p["hair"].get("gray", 0.0), 0.3 * p["hair"].get("gray", 0.0), p["beard"].get("gray", 0.0), p["beard"].get("gray", 0.0)]
    for i in range(4):
        m = comp_ids == i
        if not m.any():
            continue
        c = np.tile(cols[i], (m.sum(), 1))
        g = np.clip((noise3(vx[m], vy[m], vz[m], 420, 81 + i) - (1 - gr[i] * 1.1)) * 3 + (gr[i] > 0.8) * 0.5, 0, 1) * 0.75
        if i in (0, 3):
            ang = np.arctan2(vx[m], vz[m])
            g = np.clip(g + np.sin(ang * 38) * 0.1 * gr[i], 0, 1)
        if i == 0 and p["hair"].get("streak", 0) > 0:
            band = np.exp(-((vx[m] + 0.038) / 0.009) ** 2) * np.clip((vy[m] + 0.08) / 0.12, 0, 1) * np.clip((vz[m] + 0.03) / 0.08, 0, 1)
            g = np.clip(g + band * float(p["hair"]["streak"]), 0, 1)
        if i == 0 and p["hair"].get("temple_gray", 0) > 0:
            axm = np.abs(vx[m])
            if p.get("sculpt") == "zafer":
                temple = np.clip((axm - 0.05) / 0.008, 0, 1) * np.clip((0.064 - axm) / 0.008, 0, 1)
                temple *= np.clip((0.0 - vz[m]) / 0.02, 0, 1) * np.clip((vz[m] + 0.02) / 0.015, 0, 1)
                temple *= np.clip((vy[m] - 0.025) / 0.015, 0, 1) * np.clip((0.055 - vy[m]) / 0.015, 0, 1)
            elif p.get("sculpt") == "idris":
                temple = np.clip((axm - 0.05) / 0.012, 0, 1) * np.clip((0.075 - axm) / 0.012, 0, 1)
                temple *= np.clip((0.0 - vz[m]) / 0.03, 0, 1)
                temple *= np.clip((vy[m] - 0.01) / 0.04, 0, 1)
            else:
                temple = np.clip((axm - 0.026) / 0.028, 0, 1) * np.clip((0.072 - axm) / 0.02, 0, 1)
                temple *= np.clip((vz[m] + 0.02) / 0.06, 0, 1)
            g = np.clip(g + temple * float(p["hair"]["temple_gray"]), 0, 1)
        c = c * (1 - g[:, None]) + gray * g[:, None]
        c *= (1.0 + (noise3(vx[m], vy[m], vz[m], 200, 91 + i) - 0.5) * 0.2)[:, None]
        out[m] = c
    return np.clip(out, 0, 1)


# ---------------------------------------------------------------- ızgara + mesh
class Grid:
    def __init__(self, res, lo, hi):
        self.res = res
        self.lo = np.array(lo, dtype=np.float64)
        n = np.ceil((np.array(hi) - self.lo) / res).astype(int) + 1
        self.n = n
        self.x = (self.lo[0] + np.arange(n[0]) * res).astype(F)[:, None, None]
        self.y = (self.lo[1] + np.arange(n[1]) * res).astype(F)[None, :, None]
        self.z = (self.lo[2] + np.arange(n[2]) * res).astype(F)[None, None, :]


def extract(vol, grid, smooth_normals=True):
    vol = np.asarray(vol, dtype=np.float32)
    verts, faces, normals, _ = marching_cubes(vol, level=0.0, spacing=(grid.res,) * 3, gradient_direction="descent")
    verts = verts + grid.lo
    return verts.astype(np.float32), faces, (-normals).astype(np.float32)


def decimate(verts, faces, colors, target):
    """Kuadrik sadeleştirme: poligon sayısını hedefe indirir, renkleri en yakın tepeden taşır."""
    if len(faces) <= target:
        return verts, faces, None, colors
    import fast_simplification as fs
    from scipy.spatial import cKDTree
    v2, f2 = fs.simplify(verts.astype(np.float64), faces.astype(np.int32), target_count=target, agg=5)
    idx = cKDTree(verts).query(v2)[1]
    m = trimesh.Trimesh(vertices=v2, faces=f2, process=False)
    return v2.astype(np.float32), f2, m.vertex_normals.astype(np.float32), colors[idx]


def export(path, verts, faces, normals, colors):
    rgba = colors if colors.shape[1] == 4 else np.concatenate([colors, np.ones((colors.shape[0], 1))], axis=1)
    rgba = (np.clip(rgba, 0, 1) * 255).astype(np.uint8)
    mesh = trimesh.Trimesh(vertices=verts, faces=faces, vertex_normals=normals, process=False)
    mesh.visual = trimesh.visual.ColorVisuals(mesh, vertex_colors=rgba)
    scene = trimesh.Scene(mesh)
    path.parent.mkdir(parents=True, exist_ok=True)
    scene.export(path)


def set_eyes(h, meta):
    """Göz metasını heykelle tek kaynaktan (Head.EYES) yazar. Asimetri, heykelin
    `yy = y - k * asym * sgn(x)` kuralıyla aynı yöne uygulanır."""
    ex, ey, ez, r, k = h.eye()
    a = h.p["asym"] * k
    meta["eye_l"] = [round(ex, 5), round(ey + a, 5), round(ez, 5)]
    meta["eye_r"] = [round(-ex, 5), round(ey - a, 5), round(ez, 5)]
    meta["eye_radius"] = round(r, 5)


def build(cid, res):
    global SEED
    p = load_params(cid)
    SEED = int(p.get("seed", 1))
    h = Head(p)
    st = p["hair"]["style"]
    lo = (-0.145, -0.33, -0.19)
    hi = (0.145, 0.2, 0.15)
    if st in ("long_tied",):
        lo = (-0.145, -0.36, -0.2)
    g = Grid(res, lo, hi)
    x, y, z = g.x, g.y, g.z
    print(f"[{cid}] grid {g.n} ...", flush=True)
    # asimetri: hafif kayma
    xs = x + F(p["asym"] * 0.0025) * (y * 10.0)
    skin = h.skin(xs, y, z)
    sv, sf, sn = extract(skin, g)
    scol = skin_colors(h, sv[:, 0], sv[:, 1], sv[:, 2])
    # Pişirilmiş ortam kapanması (kırışık, göz çukuru, burun kenarı derinlik kazanır).
    # Yalnız normal yönünde örneklenirse yaklaşık SDF'in kinkleri yüzeyde sert kenarlı
    # koyu lekeler bırakıyor; normal çevresinde yarım küre örneklemesi bunu yumuşatır.
    vx = sv[:, 0] + F(p["asym"] * 0.0025) * (sv[:, 1] * 10.0)
    up = np.zeros_like(sn)
    up[:, 1] = 1.0
    tan = np.cross(sn, up)
    tn = np.linalg.norm(tan, axis=1, keepdims=True)
    flat = tn[:, 0] < 1e-4
    tan[flat] = np.array([1.0, 0.0, 0.0], dtype=np.float32)
    tan = tan / np.where(tn < 1e-4, 1.0, tn)
    bit = np.cross(sn, tan)
    occ = np.zeros(len(sv), dtype=np.float64)
    total = 0.0
    for r, wgt in ((0.004, 0.30), (0.010, 0.38), (0.022, 0.32)):
        for ang, tilt in ((0.0, 0.0), (0.0, 0.68), (2.0944, 0.68), (4.1888, 0.68)):
            dv = sn * np.cos(tilt) + (tan * np.cos(ang) + bit * np.sin(ang)) * np.sin(tilt)
            dd = np.asarray(h.skin(vx + dv[:, 0] * r, sv[:, 1] + dv[:, 1] * r, sv[:, 2] + dv[:, 2] * r))
            # düz yüzeyde eğik örnek yalnız r*cos(eğim) kadar uzaklaşır; 1'e normalle
            occ += np.clip(dd / (r * np.cos(tilt)), 0.0, 1.0) * wgt
            total += wgt
    occ /= total
    shade = hex_lin(p["skin_shadow"])
    k = np.clip(1.0 - occ, 0.0, 1.0)[:, None] * 0.52
    scol[:, :3] = scol[:, :3] * (1.0 - k) + scol[:, :3] * shade * 1.45 * k
    sv, sf, sn2, scol = decimate(sv, sf, scol, TRIS_SKIN)
    sn = sn if sn2 is None else sn2
    export(OUT / f"{cid}_skin.glb", sv, sf, sn, scol)
    print(f"  skin verts {len(sv)} faces {len(sf)}", flush=True)
    # saç bileşenleri
    comps = []
    hair = h.hair(xs, y, z)
    comps.append(hair)
    comps.append(h.brows(xs, y, z, skin))
    mus = h.mustache(xs, y, z, skin)
    bea = h.beard(xs, y, z)
    comps.append(mus if mus is not None else np.full_like(hair, 1.0))
    comps.append(bea if bea is not None else np.full_like(hair, 1.0))
    comps = [c.astype(F) for c in comps]
    hd = comps[0]
    for c in comps[1:]:
        hd = np.minimum(hd, c)
    hv, hf, hn = extract(hd, g)
    # her tepe için en yakın bileşeni bul (kenar noktalarını örnekle)
    idx = np.floor((hv - g.lo) / g.res).astype(int)
    idx = np.clip(idx, 0, np.array(g.n) - 1)
    stack = np.stack([c[idx[:, 0], idx[:, 1], idx[:, 2]] for c in comps], axis=1)
    cid_arr = np.argmin(stack, axis=1)
    hcol = hair_colors(h, cid_arr, hv[:, 0], hv[:, 1], hv[:, 2])
    hv, hf, hn2, hcol = decimate(hv, hf, hcol, TRIS_HAIR)
    hn = hn if hn2 is None else hn2
    export(OUT / f"{cid}_hair.glb", hv, hf, hn, hcol)
    print(f"  hair verts {len(hv)} faces {len(hf)}", flush=True)
    w = p["head_w"]
    if p.get("sculpt") == "behzat":
        meta = {
            "eye_l": [0.03 * w, 0.01, 0.056],
            "eye_r": [-0.03 * w, 0.01 - 0.0018 * p["asym"], 0.056],
            "eye_radius": 0.0094 * p["eye_size"],
            "nose_tip": [0.0016 * p["asym"], -0.04 - 0.01 * p["nose_hook"], 0.078 + 0.01 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.061, 0.072],
        }
    elif p.get("sculpt") == "hayalet":
        meta = {
            "eye_l": [0.026 * w, 0.012, 0.06],
            "eye_r": [-0.026 * w, 0.012 - 0.0012 * p["asym"], 0.06],
            "eye_radius": 0.0096 * p["eye_size"],
            "nose_tip": [-0.0011 * p["asym"], -0.046 - 0.008 * p["nose_hook"], 0.074 + 0.01 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.065, 0.062],
        }
    elif p.get("sculpt") == "akbaba":
        meta = {
            "eye_l": [0.028 * w, 0.011, 0.064],
            "eye_r": [-0.028 * w, 0.011 - 0.0014 * p["asym"], 0.064],
            "eye_radius": 0.01 * p["eye_size"],
            "nose_tip": [0.0012 * p["asym"], -0.042 - 0.008 * p["nose_hook"], 0.076 + 0.008 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.062, 0.064],
        }
    elif p.get("sculpt") == "player":
        meta = {
            "eye_l": [0.03 * w, 0.014, 0.064],
            "eye_r": [-0.03 * w, 0.014 - 0.001 * p["asym"], 0.064],
            "eye_radius": 0.0104 * p["eye_size"],
            "nose_tip": [0.001 * p["asym"], -0.036 - 0.004 * p["nose_hook"], 0.07 + 0.006 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.058, 0.06],
        }
    elif p.get("sculpt") == "savci":
        meta = {
            "eye_l": [0.026 * w, 0.012, 0.062],
            "eye_r": [-0.026 * w, 0.012 - 0.001 * p["asym"], 0.062],
            "eye_radius": 0.0094 * p["eye_size"],
            "nose_tip": [0.001 * p["asym"], -0.034 - 0.003 * p["nose_hook"], 0.066 + 0.006 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.056, 0.056],
            "glass_z": 0.092,
            "glass_pad_z": 0.07,
        }
    elif p.get("sculpt") == "arsiv":
        meta = {
            "eye_l": [0.028 * w, 0.01, 0.062],
            "eye_r": [-0.028 * w, 0.01 - 0.0012 * p["asym"], 0.062],
            "eye_radius": 0.0096 * p["eye_size"],
            "nose_tip": [-0.001 * p["asym"], -0.036, 0.068 + 0.004 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.057, 0.056],
            "glass_z": 0.09,
            "glass_pad_z": 0.068,
            "ear_l": [0.064 * w, -0.004, -0.012],
            "ear_r": [-0.064 * w, -0.004, -0.012],
        }
    elif p.get("sculpt") == "tarik":
        meta = {
            "eye_l": [0.03 * w, 0.012, 0.066],
            "eye_r": [-0.03 * w, 0.012 - 0.0014 * p["asym"], 0.066],
            "eye_radius": 0.0092 * p["eye_size"],
            "nose_tip": [0.0014 * p["asym"], -0.036 - 0.004 * p["nose_hook"], 0.074 + 0.006 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.058, 0.06],
        }
    elif p.get("sculpt") == "zafer":
        meta = {
            "eye_l": [0.03 * w, 0.01, 0.058],
            "eye_r": [-0.03 * w, 0.01 - 0.0016 * p["asym"], 0.058],
            "eye_radius": 0.0084 * p["eye_size"],
            "nose_tip": [0.0016 * p["asym"], -0.038 - 0.006 * p["nose_hook"], 0.076 + 0.006 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.058, 0.062],
        }
    elif p.get("sculpt") == "mert":
        meta = {
            "eye_l": [0.027 * w, 0.013, 0.052],
            "eye_r": [-0.027 * w, 0.013 - 0.0012 * p["asym"], 0.052],
            "eye_radius": 0.0086 * p["eye_size"],
            "nose_tip": [0.0012 * p["asym"], -0.036, 0.068 + 0.005 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.056, 0.056],
        }
    elif p.get("sculpt") == "haldun":
        meta = {
            "eye_l": [0.026 * w, 0.012, 0.052],
            "eye_r": [-0.026 * w, 0.012 - 0.0014 * p["asym"], 0.052],
            "eye_radius": 0.0082 * p["eye_size"],
            "nose_tip": [0.0014 * p["asym"], -0.042 - 0.004 * p["nose_hook"], 0.072 + 0.006 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.06, 0.054],
            "glass_z": 0.078,
            "glass_pad_z": 0.062,
            "ear_l": [0.062 * w, -0.002, -0.014],
            "ear_r": [-0.062 * w, -0.002, -0.014],
        }
    elif p.get("sculpt") == "idris":
        meta = {
            "eye_l": [0.03 * w, 0.01, 0.054],
            "eye_r": [-0.03 * w, 0.01 - 0.0022 * p["asym"], 0.054],
            "eye_radius": 0.0084 * p["eye_size"],
            "nose_tip": [0.002 * p["asym"], -0.04 - 0.004 * p["nose_hook"], 0.076 + 0.006 * (p["nose_len"] - 1.0)],
            "mouth": [0.0, -0.06, 0.058],
            "ear_l": [0.072 * w, -0.004, -0.012],
            "ear_r": [-0.072 * w, -0.004, -0.012],
        }
    elif p.get("sculpt") == "nevzat":
        meta = {
            "eye_l": [0.028 * w, 0.012, 0.048],
            "eye_r": [-0.028 * w, 0.012 - 0.001 * p["asym"], 0.048],
            "eye_radius": 0.0076 * p["eye_size"],
            "nose_tip": [0.001 * p["asym"], -0.034, 0.07],
            "mouth": [0.0, -0.056, 0.056],
            "glass_z": 0.078,
            "glass_pad_z": 0.062,
            "ear_l": [0.07 * w, -0.004, -0.01],
            "ear_r": [-0.07 * w, -0.004, -0.01],
        }
    else:
        meta = {
            "eye_l": [0.029 * w, 0.014, 0.062 - 0.005 * (p["eye_depth"] - 1.0)],
            "eye_r": [-0.029 * w, 0.014, 0.062 - 0.005 * (p["eye_depth"] - 1.0)],
            "eye_radius": 0.0096 * p["eye_size"],
            "nose_tip": [0.0, -0.034, 0.108],
            "mouth": [0.0, -0.0667, 0.094],
        }
    for key, val in {
        "ear_l": [0.076 * w + 0.004, -0.024, -0.014],
        "ear_r": [-(0.076 * w + 0.004), -0.024, -0.014],
    }.items():
        meta.setdefault(key, val)
    meta.update({
        "mouth_corner": [0.021 * p["mouth_w"], -0.0667, 0.09],
        "top": 0.108,
        "chin": -0.13,
        "width": 0.156 * w,
        "eye_color": p["eye_color"],
        "skin": p["skin"],
        "tired": float(p["eye_bag"]),
    })
    set_eyes(h, meta)
    (OUT / f"{cid}_head.json").write_text(json.dumps(meta, indent=1))


def main():
    args = [a for a in sys.argv[1:]]
    res = 0.002
    if "--res" in args:
        i = args.index("--res")
        res = float(args[i + 1])
        del args[i:i + 2]
    data = json.loads(TEMPLATE.read_text())
    ids = args or list(data["characters"].keys())
    for cid in ids:
        build(cid, res)


if __name__ == "__main__":
    main()
