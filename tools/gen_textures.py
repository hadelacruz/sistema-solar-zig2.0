import os
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "assets")
W, H = 1024, 512
rng = np.random.default_rng(1234)

u = (np.arange(W) + 0.5) / W
v = (np.arange(H) + 0.5) / H
U, V = np.meshgrid(u, v)
LON = U * 2 * np.pi
LAT = (0.5 - V) * np.pi  # +pi/2 arriba, -pi/2 abajo
PX = np.cos(LAT) * np.cos(LON)
PY = np.sin(LAT)
PZ = np.cos(LAT) * np.sin(LON)

# ruido sobre la esfera 3D para que no haya costura
PERM = rng.permutation(256)
PERM = np.concatenate([PERM, PERM])
VALS = rng.random(256)


def _hash(ix, iy, iz):
    return VALS[PERM[PERM[PERM[ix & 255] + (iy & 255)] + (iz & 255)] & 255]


def value_noise(x, y, z):
    ix, iy, iz = np.floor(x).astype(np.int64), np.floor(y).astype(np.int64), np.floor(z).astype(np.int64)
    fx, fy, fz = x - ix, y - iy, z - iz
    fx, fy, fz = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy), fz * fz * (3 - 2 * fz)
    def lerp(a, b, t):
        return a + (b - a) * t
    c000 = _hash(ix, iy, iz); c100 = _hash(ix + 1, iy, iz)
    c010 = _hash(ix, iy + 1, iz); c110 = _hash(ix + 1, iy + 1, iz)
    c001 = _hash(ix, iy, iz + 1); c101 = _hash(ix + 1, iy, iz + 1)
    c011 = _hash(ix, iy + 1, iz + 1); c111 = _hash(ix + 1, iy + 1, iz + 1)
    x00 = lerp(c000, c100, fx); x10 = lerp(c010, c110, fx)
    x01 = lerp(c001, c101, fx); x11 = lerp(c011, c111, fx)
    return lerp(lerp(x00, x10, fy), lerp(x01, x11, fy), fz)


def fbm(freq, octaves=5, offset=0.0, x=None, y=None, z=None):
    x = PX if x is None else x
    y = PY if y is None else y
    z = PZ if z is None else z
    total, amp, norm = 0.0, 1.0, 0.0
    f = freq
    for o in range(octaves):
        total = total + amp * value_noise(x * f + offset + o * 17.1, y * f + o * 3.7, z * f - o * 9.3)
        norm += amp
        amp *= 0.5
        f *= 2.0
    return total / norm


def ridged(freq, octaves=5, offset=0.0):
    n = fbm(freq, octaves, offset)
    return 1.0 - np.abs(n * 2 - 1)


def ramp(t, stops):
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,))
    for (p0, c0), (p1, c1) in zip(stops[:-1], stops[1:]):
        m = (t >= p0) & (t <= p1)
        k = ((t - p0) / max(p1 - p0, 1e-6))[..., None]
        out[m] = (np.array(c0) * (1 - k) + np.array(c1) * k)[m]
    return out


def save(name, rgb, alpha=None):
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    if alpha is None:
        alpha = np.full(rgb.shape[:2], 255.0)
    a = np.clip(alpha, 0, 255).astype(np.uint8)
    img = np.dstack([rgb, a])
    Image.fromarray(img).save(os.path.join(OUT, name), optimize=True)
    print("ok", name)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def gen_sol():
    n = fbm(6, 6)
    g = ridged(14, 4, 5.0)
    t = 0.55 * n + 0.45 * g
    rgb = ramp(t, [(0.0, (150, 30, 0)), (0.35, (230, 90, 10)), (0.6, (255, 170, 40)), (0.85, (255, 230, 120)), (1.0, (255, 255, 220))])
    save("sol.png", rgb)


def gen_ignis():
    base = fbm(4, 6, 2.0)
    rock = ramp(base, [(0.0, (25, 18, 15)), (0.5, (60, 40, 32)), (1.0, (105, 80, 65))])
    cracks = ridged(5, 5, 11.0) ** 10
    lava = np.clip(cracks * 1.6 + smooth(0.62, 0.75, fbm(3, 4, 40.0)) * 0.9, 0, 1)
    lava_col = ramp(lava, [(0.0, (120, 20, 0)), (0.5, (255, 90, 0)), (1.0, (255, 220, 80))])
    rgb = rock * (1 - lava[..., None]) + lava_col * lava[..., None]
    save("ignis.png", rgb, lava * 255)


def gen_terra():
    h = fbm(2.2, 7, 7.0)
    sea = 0.52
    land = h > sea
    lat = np.abs(LAT) / (np.pi / 2)
    land_t = (h - sea) / (1 - sea)
    land_col = ramp(land_t * 2.2, [(0.0, (194, 178, 128)), (0.1, (70, 140, 50)), (0.45, (40, 100, 35)), (0.75, (120, 100, 70)), (1.0, (240, 240, 240))])
    desert = smooth(0.0, 0.25, 0.35 - np.abs(lat - 0.28)) * smooth(0.45, 0.6, fbm(4, 4, 70.0))
    land_col = land_col * (1 - desert[..., None]) + np.array((210, 180, 110)) * desert[..., None]
    depth = (sea - h) / sea
    sea_col = ramp(depth * 3, [(0.0, (40, 110, 170)), (0.3, (15, 60, 130)), (1.0, (5, 25, 80))])
    rgb = np.where(land[..., None], land_col, sea_col)
    ice = smooth(0.78, 0.86, lat + (fbm(8, 3, 3.0) - 0.5) * 0.12)
    rgb = rgb * (1 - ice[..., None]) + np.array((235, 245, 255)) * ice[..., None]
    ocean = np.where(land, 0.0, 1.0) * (1 - ice)
    save("terra.png", rgb, ocean * 255)


def gen_nubes():
    # Nubes estiradas en dirección este-oeste (se escala x/z para alargarlas).
    c = fbm(3, 6, 21.0, x=PX * 0.6, y=PY * 1.8, z=PZ * 0.6)
    d = smooth(0.5, 0.75, c)
    rgb = np.full((H, W, 3), 255.0)
    save("nubes.png", rgb, d * 230)


def gen_luna():
    height = 0.55 + (fbm(5, 6, 33.0) - 0.5) * 0.5
    for _ in range(170):
        theta = rng.random() * 2 * np.pi
        phi = np.arcsin(rng.random() * 2 - 1)
        cx, cy, cz = np.cos(phi) * np.cos(theta), np.sin(phi), np.cos(phi) * np.sin(theta)
        r = 0.03 + rng.random() ** 3 * 0.25
        d = np.arccos(np.clip(PX * cx + PY * cy + PZ * cz, -1, 1)) / r
        bowl = np.where(d < 1, -(1 - d * d) * 0.6, 0.0)
        rim = np.exp(-((d - 1.0) ** 2) / 0.02) * 0.25
        height = height + (bowl + rim) * min(1.0, r * 6)
    height = np.clip((height - height.min()) / (height.max() - height.min()), 0, 1)
    g = 70 + height * 140 + (fbm(20, 3, 50.0) - 0.5) * 40
    rgb = np.dstack([g, g * 0.98, g * 0.95])
    save("luna.png", rgb, height * 255)


def gen_zephyr():
    warp = fbm(3, 5, 90.0) - 0.5
    bands = np.sin(LAT * 14 + warp * 4.0) * 0.5 + 0.5
    fine = np.sin(LAT * 45 + warp * 9.0) * 0.5 + 0.5
    t = bands * 0.75 + fine * 0.25
    rgb = ramp(t, [(0.0, (150, 90, 50)), (0.3, (200, 140, 85)), (0.55, (235, 210, 170)), (0.8, (190, 120, 70)), (1.0, (245, 230, 200))])
    # Gran tormenta ovalada
    slat, slon = np.radians(-22), np.pi * 0.7
    dl = (LON - slon + np.pi) % (2 * np.pi) - np.pi
    e = (dl / 0.32) ** 2 + ((LAT - slat) / 0.12) ** 2
    storm = smooth(1.0, 0.2, e)
    swirl = np.sin(np.sqrt(e) * 12 - np.arctan2(LAT - slat, dl) * 2) * 0.5 + 0.5
    storm_col = ramp(swirl, [(0.0, (170, 60, 35)), (1.0, (230, 120, 80))])
    rgb = rgb * (1 - storm[..., None]) + storm_col * storm[..., None]
    save("zephyr.png", rgb)


def gen_glacia():
    base = fbm(4, 6, 60.0)
    rgb = ramp(base, [(0.0, (120, 170, 210)), (0.5, (190, 225, 245)), (1.0, (245, 252, 255))])
    cracks = ridged(6, 5, 77.0) ** 14
    rgb = rgb * (1 - cracks[..., None] * 0.7) + np.array((40, 110, 170)) * cracks[..., None] * 0.7
    save("glacia.png", rgb)


def gen_anillos():
    w = 512
    r = np.linspace(0, 1, w)
    n = np.interp(r * 60, np.arange(64), rng.random(64))
    opa = (0.35 + 0.65 * n) * smooth(0.0, 0.06, r) * smooth(1.0, 0.92, r)
    opa = opa * np.where((r > 0.55) & (r < 0.6), 0.1, 1.0)  # división tipo Cassini
    col = ramp(n, [(0.0, (160, 130, 100)), (1.0, (235, 215, 180))])
    rgb = np.repeat(col[None, :, :], 4, axis=0)
    a = np.repeat(opa[None, :], 4, axis=0)
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    img = np.dstack([rgb, np.clip(a * 255, 0, 255).astype(np.uint8)])
    Image.fromarray(img).save(os.path.join(OUT, "anillos.png"), optimize=True)
    print("ok anillos.png")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    gen_sol(); gen_ignis(); gen_terra(); gen_nubes(); gen_luna(); gen_zephyr(); gen_glacia(); gen_anillos()
