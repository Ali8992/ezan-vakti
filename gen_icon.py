from PIL import Image, ImageDraw
import os

BASE = r"C:\Users\megat\ezan_vakti"
OUT_MASTER = os.path.join(BASE, "assets", "icon_master.png")
os.makedirs(os.path.join(BASE, "assets"), exist_ok=True)

SIZE = 1024
BG = (11, 61, 46, 255)        # koyu yeşil #0B3D2E
GOLD = (255, 193, 7, 255)     # sarı #FFC107
GOLD_LIGHT = (255, 213, 79, 255)
WHITE = (255, 255, 255, 255)

img = Image.new("RGBA", (SIZE, SIZE), BG)
d = ImageDraw.Draw(img)

cx = SIZE // 2
cy = int(SIZE * 0.58)

# Hilal (üstte)
moon_cx, moon_cy, moon_r = cx, int(SIZE*0.16), 70
d.ellipse([moon_cx-moon_r, moon_cy-moon_r, moon_cx+moon_r, moon_cy+moon_r], fill=GOLD)
d.ellipse([moon_cx-moon_r+25, moon_cy-moon_r-10, moon_cx+moon_r+25, moon_cy+moon_r-10], fill=BG)

# Kubbe (ortada büyük)
dome_w, dome_h = 340, 230
d.ellipse([cx-dome_w//2, cy-dome_h, cx+dome_w//2, cy+30], fill=GOLD)
# Kubbe üstü alem
d.rectangle([cx-10, cy-dome_h-70, cx+10, cy-dome_h+10], fill=GOLD)
d.ellipse([cx-18, cy-dome_h-95, cx+18, cy-dome_h-59], fill=GOLD_LIGHT)

# Ana bina gövde
body_top = cy - 20
body_bottom = cy + 170
body_left = cx - 240
body_right = cx + 240
d.rectangle([body_left, body_top, body_right, body_bottom], fill=GOLD)
# Kapı (yeşil)
door_w, door_h = 90, 130
d.rectangle([cx-door_w//2, body_bottom-door_h, cx+door_w//2, body_bottom], fill=BG)
d.ellipse([cx-door_w//2, body_bottom-door_h-45, cx+door_w//2, body_bottom-door_h+45], fill=BG)
# Pencereler (yeşil 4 tane)
for px in [-170, -90, 90, 170]:
    d.rectangle([cx+px-25, body_top+40, cx+px+25, body_top+120], fill=BG)
    d.ellipse([cx+px-25, body_top+15, cx+px+25, body_top+65], fill=BG)

# Minareler (2 tane)
for mx in [cx-320, cx+320]:
    # gövde
    d.rectangle([mx-28, cy-260, mx+28, body_bottom], fill=GOLD)
    # şerefeler
    for sy in [cy-200, cy-90, cy+20]:
        d.rectangle([mx-45, sy, mx+45, sy+18], fill=GOLD_LIGHT)
        d.ellipse([mx-45, sy-14, mx+45, sy+14], fill=GOLD_LIGHT)
    # külah
    d.polygon([(mx-32, cy-260), (mx+32, cy-260), (mx, cy-360)], fill=GOLD_LIGHT)
    d.ellipse([mx-8, cy-390, mx+8, cy-374], fill=GOLD)

# Zemin çizgisi
d.rectangle([60, body_bottom, SIZE-60, body_bottom+18], fill=GOLD_LIGHT)

img.save(OUT_MASTER)
print(f"master saved: {OUT_MASTER}")

# mipmap boyutları
sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
res_dir = os.path.join(BASE, "android", "app", "src", "main", "res")
for folder, px in sizes.items():
    target = os.path.join(res_dir, folder, "ic_launcher.png")
    small = img.resize((px, px), Image.LANCZOS)
    small.save(target)
    print(f"saved {target} {px}x{px}")

print("DONE")
