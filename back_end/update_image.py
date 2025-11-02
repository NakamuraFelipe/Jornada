import os
from database import get_db_connection

# Caminho da pasta onde estão as imagens
IMAGE_FOLDER = r"C:\Temp"

# Mapeamento entre nome do arquivo e id_usuario correspondente
IMAGE_MAP = {
    "felipe": 1,
    "maria": 2,
    "joao": 3,
    "carla": 4
}

def update_user_images():
    """
    Atualiza o campo 'foto' dos usuários na tabela 'usuario'
    com base nas imagens da pasta C:\Temp.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    for name, user_id in IMAGE_MAP.items():
        # Tenta encontrar o arquivo com as extensões mais comuns
        file_path = None
        for ext in [".jpg", ".jpeg", ".png"]:
            possible_path = os.path.join(IMAGE_FOLDER, f"{name}{ext}")
            if os.path.exists(possible_path):
                file_path = possible_path
                break

        if not file_path:
            print(f"⚠️  Imagem não encontrada para {name} em {IMAGE_FOLDER}")
            continue

        try:
            # Lê o conteúdo binário da imagem
            with open(file_path, "rb") as img_file:
                image_data = img_file.read()

            # Atualiza a foto no banco
            sql = "UPDATE usuario SET foto = %s WHERE id_usuario = %s"
            cursor.execute(sql, (image_data, user_id))
            conn.commit()

            print(f"✅ Foto de {name.capitalize()} atualizada com sucesso (ID {user_id})")

        except Exception as e:
            print(f"❌ Erro ao atualizar {name}: {e}")
            conn.rollback()

    cursor.close()
    conn.close()
    print("\n🚀 Atualização de imagens finalizada com sucesso!")

if __name__ == "__main__":
    update_user_images()
