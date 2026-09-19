#!/usr/bin/env python3
"""Build and process all Éco-Responsable Flutter assets."""
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "images"

def run(cmd):
    print("Running:", cmd)
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print("Error:", res.stderr)
    return res.returncode == 0

def build():
    # Ensure directories
    for sub in ["auth", "logos", "map", "payments", "profile", "reporting", "rewards", "shared"]:
        (ASSETS / sub).mkdir(parents=True, exist_ok=True)

    # 1. Cameroon Flag (Green #007A5E, Red #CE1126 with centered yellow star #FCD116, Yellow #FCD116)
    # Authentic 3:2 ratio flag
    run("""
    convert -size 100x200 xc:"#007A5E" /tmp/flag_green.png && \
    convert -size 100x200 xc:"#CE1126" /tmp/flag_red.png && \
    convert -size 100x200 xc:"#FCD116" /tmp/flag_yellow.png && \
    convert +append /tmp/flag_green.png /tmp/flag_red.png /tmp/flag_yellow.png /tmp/flag_base.png && \
    convert /tmp/flag_base.png -fill "#FCD116" -stroke "#D9A441" -strokewidth 1 \
        -draw "polygon 150,72 159,98 186,98 164,114 172,140 150,124 128,140 136,114 114,98 141,98" \
        assets/images/shared/cameroon_flag.png
    """)

    # 2. Onboarding 1 & Welcome Hero from welcome_city.png
    if (ASSETS / "auth" / "welcome_city.png").exists():
        run("""
        convert assets/images/auth/welcome_city.png -resize 900x1200^ -gravity center -extent 900x1200 assets/images/auth/onboarding_1.png
        convert assets/images/auth/welcome_city.png -resize 900x1100^ -gravity center -extent 900x1100 assets/images/auth/welcome_hero.png
        """)

    # 3. Onboarding 2 & 3 from generated images
    run("convert /assets/onboarding_report_1789811531269.jpg -resize 900x1200^ -gravity center -extent 900x1200 assets/images/auth/onboarding_2.png")
    run("convert /assets/onboarding_rewards_1789811550789.jpg -resize 900x1200^ -gravity center -extent 900x1200 assets/images/auth/onboarding_3.png")

    # 4. Worker & Avatars
    run("convert /assets/avatar_collector_1789811599555.jpg -resize 700x900^ -gravity center -extent 700x900 assets/images/auth/welcome_worker.png")
    run("convert /assets/avatar_collector_1789811599555.jpg -resize 256x256^ -gravity center -extent 256x256 assets/images/profile/avatar_moussa.png")
    run("convert /assets/avatar_collector_1789811599555.jpg -resize 256x256^ -gravity center -extent 256x256 assets/images/profile/avatar_placeholder.png")
    run("convert /assets/avatar_citizen_1789811617603.jpg -resize 256x256^ -gravity center -extent 256x256 assets/images/profile/avatar_sandrine.png")

    # 5. Reporting photos
    run("convert /assets/dump_photo_1789811568082.jpg -resize 1200x750^ -gravity center -extent 1200x750 assets/images/reporting/dump_photo.png")
    run("convert /assets/dump_photo_1789811568082.jpg -resize 800x600^ -gravity center -extent 800x600 assets/images/reporting/report_detail_photo.png")
    run("convert /assets/collector_truck_1789811584292.jpg -resize 800x600^ -gravity center -extent 800x600 assets/images/reporting/collector_truck.png")

    # 6. Payment Badges (MTN MoMo, Orange Money, Afriland)
    run("""
    convert -size 300x100 xc:"#FFCC00" \
        -fill "#000000" -draw "roundrectangle 10,10 290,90 20,20" \
        -fill "#FFCC00" -draw "roundrectangle 14,14 286,86 18,18" \
        -fill "#000000" -font Liberation-Sans-Bold -pointsize 26 -gravity center -annotate +0-12 "MTN" \
        -fill "#004B87" -font Liberation-Sans-Bold -pointsize 20 -gravity center -annotate +0+16 "MoMo" \
        assets/images/payments/mtn_momo.png
    """)

    run("""
    convert -size 300x100 xc:"#FF6600" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 28 -gravity center -annotate +0-12 "orange" \
        -fill "#FFFFFF" -font Liberation-Sans -pointsize 22 -gravity center -annotate +0+16 "money" \
        assets/images/payments/orange_money.png
    """)

    run("""
    convert -size 300x100 xc:"#0B2F64" \
        -fill "#D9A441" -stroke "#D9A441" -strokewidth 2 -draw "polygon 25,30 45,70 65,30" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 22 -gravity west -annotate +75-10 "Afriland" \
        -fill "#D9A441" -font Liberation-Sans -pointsize 16 -gravity west -annotate +75+16 "First Bank" \
        assets/images/payments/afriland.png
    """)

    # 7. Badges (Gold, Silver, Bronze)
    for name, color, inner in [
        ("badge_gold.png", "#D4AF37", "#FFF2A8"),
        ("badge_silver.png", "#A8A9AD", "#E8E8E8"),
        ("badge_bronze.png", "#CD7F32", "#F4C299"),
    ]:
        run(f"""
        convert -size 240x240 xc:none \
            -fill "{color}" -draw "circle 120,120 120,18" \
            -fill "{inner}" -draw "circle 120,120 120,32" \
            -fill "{color}" -draw "circle 120,120 120,44" \
            -fill "{inner}" -stroke "{color}" -strokewidth 2 \
            -draw "polygon 120,70 128,95 155,95 133,110 142,135 120,119 98,135 107,110 85,95 112,95" \
            assets/images/rewards/{name}
        """)

    # 8. Logo and Logo White
    run("""
    convert -size 512x512 xc:none \
        -fill "#2E7D32" -draw "circle 256,256 256,40" \
        -fill "#FFFFFF" -draw "circle 256,256 256,70" \
        -fill "#2E7D32" -draw "path 'M 256,120 C 350,150 370,270 290,340 C 230,390 150,330 180,240 C 190,200 230,150 256,120 Z'" \
        -fill "#A5D6A7" -draw "path 'M 256,140 C 320,190 310,280 256,310 C 240,260 245,200 256,140 Z'" \
        -fill "#D9A441" -draw "circle 256,340 256,322" \
        assets/images/logos/logo.png
    """)

    run("""
    convert -size 512x512 xc:none \
        -fill "#FFFFFF" -draw "circle 256,256 256,40" \
        -fill "none" -stroke "#FFFFFF" -strokewidth 16 -draw "circle 256,256 256,70" \
        -fill "#FFFFFF" -draw "path 'M 256,120 C 350,150 370,270 290,340 C 230,390 150,330 180,240 C 190,200 230,150 256,120 Z'" \
        assets/images/logos/logo_white.png
    """)

    # 9. Maps (map_preview, zones_map, heatmap)
    run("""
    convert -size 900x550 xc:"#E5F2E5" \
        -stroke "#FFFFFF" -strokewidth 18 \
        -draw "line 0,180 900,240" -draw "line 0,380 900,320" -draw "line 280,0 320,550" -draw "line 650,0 580,550" \
        -stroke "#D0E7D2" -strokewidth 8 \
        -draw "line 0,80 900,120" -draw "line 120,0 160,550" -draw "line 480,0 500,550" -draw "line 800,0 760,550" \
        -stroke "#2E7D32" -strokewidth 8 -fill none \
        -draw "path 'M 140,420 Q 320,380 300,220 T 600,200 T 750,300'" \
        -fill "#2E7D32" -stroke "#FFFFFF" -strokewidth 3 \
        -draw "circle 140,420 140,405" -draw "circle 300,220 300,205" -draw "circle 600,200 600,185" -draw "circle 750,300 750,285" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 14 -gravity northwest \
        -draw "text 135,413 '1'" -draw "text 295,213 '2'" -draw "text 595,193 '3'" -draw "text 745,293 '4'" \
        -fill "#1B5E20" -font Liberation-Sans-Bold -pointsize 20 -stroke none \
        -draw "text 40,40 'Plan de tournée • Douala / Yaoundé'" \
        assets/images/map/map_preview.png
    """)

    run("""
    convert assets/images/map/map_preview.png \
        -fill "rgba(46, 125, 50, 0.25)" -stroke "#2E7D32" -strokewidth 2 \
        -draw "polygon 40,80 260,60 280,260 50,240" \
        -fill "rgba(217, 164, 65, 0.25)" -stroke "#D9A441" -strokewidth 2 \
        -draw "polygon 320,100 600,80 580,280 340,300" \
        -fill "rgba(21, 101, 192, 0.25)" -stroke "#1565C0" -strokewidth 2 \
        -draw "polygon 200,320 540,300 520,500 180,480" \
        -fill "#1B5E20" -font Liberation-Sans-Bold -pointsize 18 \
        -draw "text 80,150 'Zone Bastos (Actif)'" \
        -draw "text 370,160 'Zone Bonabéri (En collecte)'" \
        -draw "text 240,390 'Zone Mvan (Planifié)'" \
        assets/images/map/zones_map.png
    """)

    run("""
    convert assets/images/map/map_preview.png \
        -fill "rgba(230, 81, 0, 0.45)" -stroke none \
        -draw "circle 320,240 320,130" \
        -fill "rgba(216, 27, 96, 0.55)" \
        -draw "circle 320,240 320,180" \
        -fill "rgba(255, 179, 0, 0.5)" \
        -draw "circle 620,210 620,120" \
        -fill "#FFFFFF" -stroke "#000000" -strokewidth 1 -font Liberation-Sans-Bold -pointsize 16 \
        -draw "text 270,245 'Point chaud: Déchets'" \
        assets/images/map/heatmap.png
    """)

    # 10. Reporting Card Category Illustrations (report_dump, report_bin, report_household, proof_placeholder)
    run("""
    convert -size 400x260 xc:"#F5F5F5" \
        -fill "#E0E0E0" -draw "roundrectangle 12,12 388,248 18,18" \
        -fill "#D32F2F" -draw "circle 200,100 200,50" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 48 -gravity center -annotate +0-30 "!" \
        -fill "#212121" -font Liberation-Sans-Bold -pointsize 20 -gravity center -annotate +0+50 "Dépôt sauvage" \
        -fill "#757575" -font Liberation-Sans -pointsize 14 -gravity center -annotate +0+80 "Signalement citoyen" \
        assets/images/reporting/report_dump.png
    """)

    run("""
    convert -size 400x260 xc:"#F5F5F5" \
        -fill "#E8F5E9" -draw "roundrectangle 12,12 388,248 18,18" \
        -fill "#2E7D32" -draw "roundrectangle 160,60 240,160 8,8" \
        -fill "#1B5E20" -draw "roundrectangle 150,50 250,65 4,4" \
        -fill "#212121" -font Liberation-Sans-Bold -pointsize 20 -gravity center -annotate +0+50 "Bac débordant" \
        -fill "#757575" -font Liberation-Sans -pointsize 14 -gravity center -annotate +0+80 "Point d'apport saturé" \
        assets/images/reporting/report_bin.png
    """)

    run("""
    convert -size 400x260 xc:"#F5F5F5" \
        -fill "#FFF8E1" -draw "roundrectangle 12,12 388,248 18,18" \
        -fill "#D9A441" -draw "circle 170,110 170,70" \
        -fill "#2E7D32" -draw "circle 230,110 230,70" \
        -fill "#212121" -font Liberation-Sans-Bold -pointsize 20 -gravity center -annotate +0+50 "Ordures ménagères" \
        -fill "#757575" -font Liberation-Sans -pointsize 14 -gravity center -annotate +0+80 "Collecte à domicile" \
        assets/images/reporting/report_household.png
    """)

    run("""
    convert -size 600x400 xc:"#F1F8E9" \
        -stroke "#81C784" -strokewidth 3 -strokepath "dasharray 8 6" -fill "none" \
        -draw "roundrectangle 20,20 580,380 20,20" \
        -fill "#2E7D32" -stroke none -draw "circle 300,170 300,120" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 32 -gravity center -annotate +0-30 "📷" \
        -fill "#1B5E20" -font Liberation-Sans-Bold -pointsize 22 -gravity center -annotate +0+40 "Preuve photo de collecte" \
        -fill "#558B2F" -font Liberation-Sans -pointsize 16 -gravity center -annotate +0+70 "Appuyez pour prendre ou choisir une photo" \
        assets/images/reporting/proof_placeholder.png
    """)

    # 11. Rewards vouchers (reward_mtn, reward_voucher, reward_partner)
    run("""
    convert -size 360x220 xc:"#FFCC00" \
        -fill "#000000" -draw "roundrectangle 12,12 348,208 16,16" \
        -fill "#FFCC00" -draw "roundrectangle 16,16 344,204 14,14" \
        -fill "#000000" -font Liberation-Sans-Bold -pointsize 28 -gravity center -annotate +0-40 "MTN MoMo" \
        -fill "#004B87" -font Liberation-Sans-Bold -pointsize 36 -gravity center -annotate +0+10 "2 500 FCFA" \
        -fill "#333333" -font Liberation-Sans -pointsize 14 -gravity center -annotate +0+55 "Recharge crédit ou cash" \
        assets/images/rewards/reward_mtn.png
    """)

    run("""
    convert -size 360x220 xc:"#2E7D32" \
        -fill "#FFFFFF" -draw "roundrectangle 12,12 348,208 16,16" \
        -fill "#E8F5E9" -draw "roundrectangle 16,16 344,204 14,14" \
        -fill "#2E7D32" -font Liberation-Sans-Bold -pointsize 26 -gravity center -annotate +0-40 "Bon d'Achat Éco" \
        -fill "#1B5E20" -font Liberation-Sans-Bold -pointsize 36 -gravity center -annotate +0+10 "5 000 FCFA" \
        -fill "#4CAF50" -font Liberation-Sans -pointsize 14 -gravity center -annotate +0+55 "Valable magasins partenaires" \
        assets/images/rewards/reward_voucher.png
    """)

    run("""
    convert -size 360x220 xc:"#0288D1" \
        -fill "#FFFFFF" -draw "roundrectangle 12,12 348,208 16,16" \
        -fill "#E1F5FE" -draw "roundrectangle 16,16 344,204 14,14" \
        -fill "#0277BD" -font Liberation-Sans-Bold -pointsize 26 -gravity center -annotate +0-40 "Pass Partenaire" \
        -fill "#01579B" -font Liberation-Sans-Bold -pointsize 36 -gravity center -annotate +0+10 "Remise 20%" \
        -fill "#039BE5" -font Liberation-Sans -pointsize 14 -gravity center -annotate +0+55 "HYSACAM & Boutiques bio" \
        assets/images/rewards/reward_partner.png
    """)

    # 12. Notification Icons & Profile decorations
    run("""
    convert -size 120x120 xc:none \
        -fill "#2E7D32" -draw "circle 60,60 60,8" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 42 -gravity center -annotate +0+0 "🚛" \
        assets/images/profile/notif_collecte.png
    """)

    run("""
    convert -size 120x120 xc:none \
        -fill "#D9A441" -draw "circle 60,60 60,8" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 42 -gravity center -annotate +0+0 "⭐" \
        assets/images/profile/notif_points.png
    """)

    run("""
    convert -size 120x120 xc:none \
        -fill "#1565C0" -draw "circle 60,60 60,8" \
        -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 42 -gravity center -annotate +0+0 "📍" \
        assets/images/profile/notif_map.png
    """)

    run("""
    convert -size 160x160 xc:none \
        -fill "#81C784" -draw "path 'M 80,10 C 140,40 150,110 110,140 C 70,170 20,130 30,80 C 40,50 65,25 80,10 Z'" \
        -fill "#4CAF50" -draw "path 'M 80,30 C 120,60 125,110 95,130 C 75,100 75,60 80,30 Z'" \
        assets/images/profile/leaf_deco.png
    """)

    # 13. Map icons
    for icon_name, symbol in [
        ("icon_recycle.png", "♻"),
        ("icon_city.png", "🏙"),
        ("icon_citizens.png", "👥"),
        ("icon_cameroon.png", "🇨🇲"),
        ("icon_tri.png", "♻"),
    ]:
        dest = ASSETS / "map" / icon_name if icon_name != "icon_tri.png" else ASSETS / "payments" / icon_name
        run(f"""
        convert -size 128x128 xc:none \
            -fill "#2E7D32" -draw "circle 64,64 64,10" \
            -fill "#FFFFFF" -font Liberation-Sans-Bold -pointsize 54 -gravity center -annotate +0+0 "{symbol}" \
            {dest}
        """)

    # 14. OTP Phone shared
    run("""
    convert -size 280x280 xc:none \
        -fill "#E8F5E9" -draw "circle 140,140 140,20" \
        -fill "#2E7D32" -draw "roundrectangle 95,50 185,230 18,18" \
        -fill "#FFFFFF" -draw "roundrectangle 103,70 177,200 8,8" \
        -fill "#2E7D32" -draw "circle 140,215 140,210" \
        -fill "#D9A441" -font Liberation-Sans-Bold -pointsize 26 -gravity center -annotate +0-10 "•••" \
        assets/images/shared/otp_phone.png
    """)

    print("Assets generation finished successfully!")

if __name__ == "__main__":
    build()
