from PIL import Image
import os

source_path = 'assets/img/App icon.jpg'
if not os.path.exists(source_path):
    print("Source image not found:", source_path)
    exit(1)

img = Image.open(source_path).convert('RGBA')

# Square crop if needed
w, h = img.size
min_dim = min(w, h)
left = (w - min_dim) // 2
top = (h - min_dim) // 2
img_cropped = img.crop((left, top, left + min_dim, top + min_dim))

resolutions = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

base_res_dir = 'android/app/src/main/res'
for folder, size in resolutions.items():
    target_dir = os.path.join(base_res_dir, folder)
    os.makedirs(target_dir, exist_ok=True)
    target_file = os.path.join(target_dir, 'ic_launcher.png')
    resized = img_cropped.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(target_file, format='PNG')
    print(f"Generated {target_file} ({size}x{size})")

print("App launcher icons generated successfully!")
