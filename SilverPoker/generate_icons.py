from PIL import Image
import os

def generate_app_icons(input_image_path):
    # 创建输出目录
    output_dir = "SilverPoker/SilverPokerApp/Resources/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    # 定义所需的图标尺寸
    icon_sizes = [
        (20, "icon_20.png"),
        (29, "icon_29.png"),
        (40, "icon_40.png"),
        (58, "icon_58.png"),
        (60, "icon_60.png"),
        (76, "icon_76.png"),
        (80, "icon_80.png"),
        (87, "icon_87.png"),
        (120, "icon_120.png"),
        (152, "icon_152.png"),
        (167, "icon_167.png"),
        (180, "icon_180.png"),
        (1024, "icon_1024.png")
    ]
    
    # 打开原始图片
    with Image.open(input_image_path) as img:
        # 确保图片是正方形
        width, height = img.size
        size = min(width, height)
        left = (width - size) // 2
        top = (height - size) // 2
        img = img.crop((left, top, left + size, top + size))
        
        # 生成不同尺寸的图标
        for icon_size, icon_name in icon_sizes:
            resized_img = img.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
            output_path = os.path.join(output_dir, icon_name)
            resized_img.save(output_path, "PNG")
            print(f"Generated {icon_name} ({icon_size}x{icon_size})")

if __name__ == "__main__":
    # 假设原始图片保存为 original_icon.png
    generate_app_icons("original_icon.png") 