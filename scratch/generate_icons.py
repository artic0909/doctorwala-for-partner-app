import os
from PIL import Image

def generate_icons():
    logo_path = r"c:\Saklin Mustak Projects\doctorwala_for_partner\assets\images\logo.png"
    res_base_dir = r"c:\Saklin Mustak Projects\doctorwala_for_partner\android\app\src\main\res"

    if not os.path.exists(logo_path):
        print(f"Error: Logo file not found at {logo_path}")
        return

    # Mipmap densities and their target square dimensions
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    try:
        img = Image.open(logo_path)
        print(f"Successfully opened source logo: {img.size} px")
        
        for folder, size in densities.items():
            folder_path = os.path.join(res_base_dir, folder)
            os.makedirs(folder_path, exist_ok=True)
            
            # High-quality resize using LANCZOS filter
            resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
            output_file_path = os.path.join(folder_path, "ic_launcher.png")
            resized_img.save(output_file_path, "PNG")
            print(f"Generated launcher icon: {output_file_path} ({size}x{size})")
            
        print("\nAll launcher icons generated successfully!")

    except Exception as e:
        print(f"An error occurred while generating icons: {e}")

if __name__ == "__main__":
    generate_icons()
