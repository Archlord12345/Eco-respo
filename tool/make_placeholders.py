#!/usr/bin/env python3
"""Génère des PNG placeholder remplaçables (même nom de fichier)."""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets" / "images"


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path: Path, w: int, h: int, rgb: tuple[int, int, int]) -> None:
    r, g, b = rgb
    raw = b"".join(b"\x00" + bytes([r, g, b]) * w for _ in range(h))
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


GREEN = (46, 125, 50)
LIGHT = (165, 214, 167)
OCHRE = (217, 164, 65)
CREAM = (248, 247, 241)
NAVY = (15, 45, 40)
GRAY = (74, 74, 74)
WHITE = (255, 255, 255)
BLUE = (21, 101, 192)
RED = (198, 40, 40)

FILES: dict[str, tuple[int, int, tuple[int, int, int]]] = {
    "logo.png": (256, 256, GREEN),
    "logo_white.png": (256, 256, WHITE),
    "welcome_hero.png": (900, 1100, LIGHT),
    "welcome_worker.png": (700, 900, GREEN),
    "welcome_city.png": (900, 500, BLUE),
    "cameroon_flag.png": (96, 64, RED),
    "otp_phone.png": (280, 280, LIGHT),
    "avatar_placeholder.png": (256, 256, OCHRE),
    "avatar_moussa.png": (256, 256, GREEN),
    "avatar_sandrine.png": (256, 256, LIGHT),
    "leaf_deco.png": (200, 200, LIGHT),
    "reward_mtn.png": (256, 256, OCHRE),
    "reward_voucher.png": (256, 256, GREEN),
    "reward_partner.png": (256, 256, BLUE),
    "badge_bronze.png": (200, 200, (183, 124, 58)),
    "badge_silver.png": (200, 200, (176, 176, 176)),
    "badge_gold.png": (200, 200, OCHRE),
    "report_dump.png": (640, 400, GRAY),
    "report_bin.png": (640, 400, GREEN),
    "report_household.png": (640, 400, OCHRE),
    "dump_photo.png": (1200, 700, GRAY),
    "map_preview.png": (1200, 700, LIGHT),
    "heatmap.png": (1200, 700, (255, 200, 150)),
    "zones_map.png": (1200, 800, LIGHT),
    "report_detail_photo.png": (800, 600, GRAY),
    "mtn_momo.png": (240, 80, OCHRE),
    "orange_money.png": (240, 80, (255, 140, 0)),
    "afriland.png": (240, 80, BLUE),
    "icon_tri.png": (128, 128, GREEN),
    "icon_recycle.png": (128, 128, GREEN),
    "icon_city.png": (128, 128, GREEN),
    "icon_citizens.png": (128, 128, GREEN),
    "icon_cameroon.png": (128, 128, GREEN),
    "collector_truck.png": (256, 256, OCHRE),
    "notif_collecte.png": (96, 96, GREEN),
    "notif_points.png": (96, 96, OCHRE),
    "notif_map.png": (96, 96, BLUE),
    "proof_placeholder.png": (800, 600, CREAM),
    "onboarding_1.png": (900, 1100, LIGHT),
    "onboarding_2.png": (900, 1100, GREEN),
    "onboarding_3.png": (900, 1100, OCHRE),
}


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    for name, (w, h, color) in FILES.items():
        write_png(ROOT / name, w, h, color)
        print("ok", name)
    (ROOT / "REMPLACER_MOI.txt").write_text(
        "Remplacez ces PNG par vos visuels en conservant le nom de fichier.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
