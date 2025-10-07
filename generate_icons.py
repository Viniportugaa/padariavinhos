from PIL import Image
import os

# Caminho do ícone original
INPUT_ICON = r"V:\ProjetosFlutter\padariavinhos\web\icons\LogoNovaAppVinhosICON.png"

# Pasta de saída
OUTPUT_DIR = r"V:\ProjetosFlutter\padariavinhos\web\icons"

# Tamanhos que precisamos
SIZES = [192, 512]

def generate_icons():
    if not os.path.exists(INPUT_ICON):
        print(f"❌ Arquivo não encontrado: {INPUT_ICON}")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    with Image.open(INPUT_ICON) as img:
        for size in SIZES:
            # Normal
            out_path = os.path.join(OUTPUT_DIR, f"LogoNovaAppVinhosICON-{size}.png")
            img.resize((size, size), Image.Resampling.LANCZOS).save(out_path, "PNG")
            print(f"✅ Gerado: {out_path}")

            # Maskable (com fundo transparente expandido)
            maskable = Image.new("RGBA", (size, size), (0, 0, 0, 0))
            maskable.paste(
                img.resize((size, size), Image.Resampling.LANCZOS), (0, 0)
            )
            mask_path = os.path.join(OUTPUT_DIR, f"LogoNovaAppVinhosICON-maskable-{size}.png")
            maskable.save(mask_path, "PNG")
            print(f"✅ Gerado: {mask_path}")

if __name__ == "__main__":
    generate_icons()
