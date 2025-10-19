"""
Script para poblar la base de datos en MySQL 
link: http://localhost:8888/phpMyAdmin5/index.php?route=/database/structure&db=tarea2
"""

from dotenv import load_dotenv
import os
import random
import datetime
import hashlib
from faker import Faker
import mysql.connector
from collections import defaultdict, Counter


load_dotenv()

DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")

if not all([DB_NAME, DB_USER, DB_PASS is not None, DB_HOST, DB_PORT]):
    raise SystemExit("??? Faltan variables de entorno DB_* en el archivo .env")

faker = Faker('es_ES')
random.seed(42)

NUM_USERS = 50
NUM_ING = 80
NUM_BUGS = 300
NUM_FUNCS = 200
NUM_TOPICS = 10
NUM_CRITERIA = 3

def random_date(start_year=2023, end_year=2025):
    start = datetime.date(start_year, 1, 1)
    end = datetime.date(end_year, 12, 31)
    days = (end - start).days
    return start + datetime.timedelta(days=random.randint(0, max(0, days)))

def generate_rut():
    rut = random.randint(1_000_000, 25_000_000)
    dv_options = list(map(str, range(10))) + ["K"]
    dv = random.choice(dv_options)
    return f"{rut}-{dv}"

def main():
    conn = mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        port=DB_PORT
    )
    cur = conn.cursor()

    try:
        # Deshabilitar triggers temporalmente
        cur.execute("DROP TRIGGER IF EXISTS trg_min_3_criterios")
        cur.execute("DROP TRIGGER IF EXISTS trg_max_2_especialidades")
        cur.execute("DROP TRIGGER IF EXISTS trg_limite_diario_func")
        cur.execute("DROP TRIGGER IF EXISTS trg_limite_diario_error")
        cur.execute("DROP TRIGGER IF EXISTS trg_bloqueo_update_func")
        cur.execute("DROP TRIGGER IF EXISTS trg_bloqueo_delete_func")
        cur.execute("DROP TRIGGER IF EXISTS trg_bloqueo_update_error")
        cur.execute("DROP TRIGGER IF EXISTS trg_bloqueo_delete_error")
        cur.execute("DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_func")
        cur.execute("DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_func_update")
        cur.execute("DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_error")
        cur.execute("DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_error_update")
        cur.execute("DROP TRIGGER IF EXISTS trg_max_20_asignaciones_func")
        cur.execute("DROP TRIGGER IF EXISTS trg_max_20_asignaciones_error")
        
        # Tópicos
        topics = [
            (1, "Backend"), (2, "Seguridad"), (3, "UX/UI"), (4, "DevOps"),
            (5, "Machine Learning"), (6, "Testing"), (7, "Cloud"),
            (8, "Data Science"), (9, "Mobile"), (10, "Infraestructura")
        ]
        cur.executemany(
            "INSERT IGNORE INTO Topico (id_topico, nombre_topico) VALUES (%s, %s)",
            topics
        )

        # Usuarios
        user_ruts, users = [], []
        for _ in range(NUM_USERS):
            rut = generate_rut()
            user_ruts.append(rut)
            users.append((rut, faker.name(), faker.email()))
        cur.executemany(
            "INSERT IGNORE INTO Usuario (user_rut, user_nombre, user_email) VALUES (%s, %s, %s)",
            users
        )

        # Credenciales para usuarios normales (Auth_User)
        auth_users_normal = []
        for rut in user_ruts:
            password_hash = "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi"  # Hash de "password"
            auth_users_normal.append((rut, password_hash, 'usuario'))
        
        cur.executemany(
            "INSERT IGNORE INTO Auth_User (rut, pass_hash, rol) VALUES (%s, %s, %s)",
            auth_users_normal
        )

        # Ingenieros
        ing_ruts, ings = [], []
        for _ in range(NUM_ING):
            rut = generate_rut()
            ing_ruts.append(rut)
            ings.append((rut, faker.name(), faker.email()))
        cur.executemany(
            "INSERT IGNORE INTO Ingeniero (ing_rut, nombre_ing, email_ing) VALUES (%s, %s, %s)",
            ings
        )

        # Credenciales para ingenieros (Auth_User)
        auth_users_ing = []
        for rut in ing_ruts:
            password_hash = "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi"  # Hash de "password"
            auth_users_ing.append((rut, password_hash, 'ingeniero'))
        
        cur.executemany(
            "INSERT IGNORE INTO Auth_User (rut, pass_hash, rol) VALUES (%s, %s, %s)",
            auth_users_ing
        )

        # Especialidades
        ing_especial = []
        topic_to_ing = defaultdict(list)
        for ing in ing_ruts:
            k = random.randint(1, min(2, NUM_TOPICS))
            for t in random.sample(range(1, NUM_TOPICS + 1), k):
                ing_especial.append((t, ing))
                topic_to_ing[t].append(ing)
        if ing_especial:
            cur.executemany(
                "INSERT IGNORE INTO Ingeniero_Especialidad (id_topico, ing_rut) VALUES (%s, %s)",
                ing_especial
            )

        # Funcionalidades
        estados_func = ["Abierto", "En Progreso", "Resuelto", "Cerrado"]
        cuenta_func_dia = defaultdict(int)
        funcs = []
        for fid in range(1, NUM_FUNCS + 1):
            while True:
                fecha = random_date(2010, 2025)
                user_rut = random.choice(user_ruts)
                if cuenta_func_dia[(user_rut, fecha)] < 25:
                    cuenta_func_dia[(user_rut, fecha)] += 1
                    break

            titulo = faker.sentence(nb_words=5)
            if len(titulo) < 20:
                titulo += " " + faker.word()
            titulo = titulo[:100]
            ambiente = random.choice(["Web", "Móvil"])
            resumen = faker.sentence(nb_words=10)
            estado = random.choice(estados_func)
            id_topico = random.randint(1, NUM_TOPICS)
            resuelto_en = None
            if estado == "Resuelto":
                resuelto_en = datetime.datetime.combine(fecha, datetime.time()) + datetime.timedelta(days=random.randint(0, 2))
            elif estado == "Cerrado":
                resuelto_en = datetime.datetime.combine(fecha, datetime.time()) + datetime.timedelta(days=random.randint(3, 10))
            funcs.append((fid, titulo, ambiente, resumen, estado, fecha, resuelto_en, id_topico, user_rut))

        cur.executemany(
            "INSERT IGNORE INTO Funcionalidad "
            "(id_funcionalidad, titulo_funcion, ambiente_funcion, resumen_funcion, estado_funcion, fecha_funcion, resuelto_en, id_topico, user_rut) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
            funcs
        )

        func_assignments = []
        func_load = Counter()
        for fid, _, _, _, _, _, _, topico_id, _ in funcs:
            candidatos = topic_to_ing.get(topico_id, [])
            if not candidatos:
                continue
            candidatos = sorted(candidatos, key=lambda ing: (func_load[ing], ing))
            for ing in candidatos[:3]:
                func_assignments.append((fid, ing))
                func_load[ing] += 1

        if func_assignments:
            cur.executemany(
                "INSERT IGNORE INTO Asignacion_Funcionalidad (id_funcionalidad, ing_rut) VALUES (%s, %s)",
                func_assignments
            )

        # Criterios
        criterios = []
        criterio_id = 1
        for fid in range(1, NUM_FUNCS + 1):
            for _ in range(NUM_CRITERIA):
                criterios.append((criterio_id, faker.sentence(nb_words=6), fid))
                criterio_id += 1
        cur.executemany(
            "INSERT IGNORE INTO Criterio_Aceptacion (id_criterio, descripcion_criterio, id_funcionalidad) "
            "VALUES (%s,%s,%s)",
            criterios
        )

        # Errores
        estados_bug = ["Abierto", "En Progreso", "Resuelto", "Cerrado"]
        cuenta_bug_dia = defaultdict(int)
        bugs = []
        for bid in range(1, NUM_BUGS + 1):
            while True:
                fecha = random_date(2010, 2025)
                user_rut = random.choice(user_ruts)
                if cuenta_bug_dia[(user_rut, fecha)] < 25:
                    cuenta_bug_dia[(user_rut, fecha)] += 1
                    break

            titulo = f"Error {bid}"
            descripcion = faker.paragraph(nb_sentences=2)
            estado = random.choice(estados_bug)
            id_topico = random.randint(1, NUM_TOPICS)
            resuelto_en = None
            if estado == "Resuelto":
                resuelto_en = datetime.datetime.combine(fecha, datetime.time()) + datetime.timedelta(days=random.randint(0, 2))
            elif estado == "Cerrado":
                resuelto_en = datetime.datetime.combine(fecha, datetime.time()) + datetime.timedelta(days=random.randint(3, 10))
            bugs.append((bid, titulo, descripcion, fecha, estado, resuelto_en, id_topico, user_rut))

        cur.executemany(
            "INSERT IGNORE INTO ErrorBug "
            "(id_bug, titulo_error, descripcion_error, fecha_error, estado_error, resuelto_en, id_topico, user_rut) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s)",
            bugs
        )

        error_assignments = []
        error_load = Counter()
        for bid, _, _, _, _, _, topico_id, _ in bugs:
            candidatos = topic_to_ing.get(topico_id, [])
            if not candidatos:
                continue
            candidatos = sorted(candidatos, key=lambda ing: (error_load[ing], ing))
            for ing in candidatos[:3]:
                error_assignments.append((bid, ing))
                error_load[ing] += 1

        if error_assignments:
            cur.executemany(
                "INSERT IGNORE INTO Asignacion_Error (id_bug, ing_rut) VALUES (%s, %s)",
                error_assignments
            )

        # Recrear triggers
        cur.execute("""
        CREATE TRIGGER trg_min_3_criterios
        AFTER DELETE ON Criterio_Aceptacion
        FOR EACH ROW
        BEGIN
          DECLARE n INT;
          SELECT COUNT(*) INTO n FROM Criterio_Aceptacion WHERE id_funcionalidad = OLD.id_funcionalidad;
          IF n < 3 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cada funcionalidad debe tener al menos 3 criterios.';
          END IF;
        END
        """)
        
        cur.execute("""
        CREATE TRIGGER trg_max_2_especialidades
        BEFORE INSERT ON Ingeniero_Especialidad
        FOR EACH ROW
        BEGIN
          DECLARE n INT;
          SELECT COUNT(*) INTO n FROM Ingeniero_Especialidad WHERE ing_rut = NEW.ing_rut;
          IF n >= 2 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener m??s de 2 especialidades.';
          END IF;
        END
        """)
        
        conn.commit()
        print("Poblamiento completado exitosamente")

    except Exception as e:
        conn.rollback()
        print("Error:", e)
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()
