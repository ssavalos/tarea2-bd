"""
Script para despoblar (limpiar) la base de datos en MySQL
Elimina todos los datos respetando las dependencias de claves foráneas
"""

from dotenv import load_dotenv
import os
import mysql.connector

load_dotenv()

DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")

if not all([DB_NAME, DB_USER, DB_PASS is not None, DB_HOST, DB_PORT]):
    raise SystemExit("❌ Faltan variables de entorno DB_* en el archivo .env")

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
        print("🧹 Iniciando despoblamiento de la base de datos...")
        
        # Deshabilitar foreign key checks y triggers temporalmente para facilitar el borrado
        cur.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        # Guardar y eliminar triggers que podrían interferir
        print("  🔧 Deshabilitando triggers temporalmente...")
        cur.execute("DROP TRIGGER IF EXISTS trg_min_3_criterios")
        cur.execute("DROP TRIGGER IF EXISTS trg_max_2_especialidades")
        cur.execute("DROP TRIGGER IF EXISTS trg_bloqueo_update_func")
        cur.execute("DROP TRIGGER IF EXISTS trg_bloqueo_delete_func")

        # Eliminar datos en orden inverso de dependencias
        # Primero las tablas con dependencias (hijas), luego las padres

        print("  📋 Eliminando asignaciones...")
        cur.execute("DELETE FROM Asignacion_Funcionalidad")
        affected = cur.rowcount
        print(f"    ✓ Asignacion_Funcionalidad: {affected} registros eliminados")

        cur.execute("DELETE FROM Asignacion_Error")
        affected = cur.rowcount
        print(f"    ✓ Asignacion_Error: {affected} registros eliminados")

        print("  💬 Eliminando reseñas...")
        cur.execute("DELETE FROM Resena_Funcionalidad")
        affected = cur.rowcount
        print(f"    ✓ Resena_Funcionalidad: {affected} registros eliminados")

        cur.execute("DELETE FROM Resena_Error")
        affected = cur.rowcount
        print(f"    ✓ Resena_Error: {affected} registros eliminados")
        
        print("  📝 Eliminando criterios de aceptación...")
        cur.execute("DELETE FROM Criterio_Aceptacion")
        affected = cur.rowcount
        print(f"    ✓ Criterio_Aceptacion: {affected} registros eliminados")
        
        print("  🔧 Eliminando especialidades de ingenieros...")
        cur.execute("DELETE FROM Ingeniero_Especialidad")
        affected = cur.rowcount
        print(f"    ✓ Ingeniero_Especialidad: {affected} registros eliminados")
        
        print("  ⚙️ Eliminando funcionalidades...")
        cur.execute("DELETE FROM Funcionalidad")
        affected = cur.rowcount
        print(f"    ✓ Funcionalidad: {affected} registros eliminados")
        
        print("  🐛 Eliminando errores/bugs...")
        cur.execute("DELETE FROM ErrorBug")
        affected = cur.rowcount
        print(f"    ✓ ErrorBug: {affected} registros eliminados")
        
        print("  � Eliminando usuarios de autenticación...")
        cur.execute("DELETE FROM Auth_User")
        affected = cur.rowcount
        print(f"    ✓ Auth_User: {affected} registros eliminados")
        
        print("  � Eliminando ingenieros...")
        cur.execute("DELETE FROM Ingeniero")
        affected = cur.rowcount
        print(f"    ✓ Ingeniero: {affected} registros eliminados")
        
        print("  � Eliminando usuarios...")
        cur.execute("DELETE FROM Usuario")
        affected = cur.rowcount
        print(f"    ✓ Usuario: {affected} registros eliminados")
        
        print("  � Eliminando tópicos...")
        cur.execute("DELETE FROM Topico")
        affected = cur.rowcount
        print(f"    ✓ Topico: {affected} registros eliminados")
        
        # Reiniciar auto_increment en las tablas que lo usan
        print("  🔄 Reiniciando contadores auto_increment...")
        auto_increment_tables = [
            "Auth_User", "Topico", "Funcionalidad", "Criterio_Aceptacion", "Resena_Funcionalidad",
            "ErrorBug", "Resena_Error"
        ]
        
        for table in auto_increment_tables:
            cur.execute(f"ALTER TABLE {table} AUTO_INCREMENT = 1")
            print(f"    ↻ {table} reiniciado")
        
        # Recrear triggers eliminados
        print("  🔄 Recreando triggers...")
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
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener más de 2 especialidades.';
          END IF;
        END
        """)
        
        cur.execute("""
        CREATE TRIGGER trg_bloqueo_update_func
        BEFORE UPDATE ON Funcionalidad
        FOR EACH ROW
        BEGIN
          IF OLD.estado_funcion = 'En Progreso' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar una funcionalidad en progreso.';
          END IF;
        END
        """)
        
        cur.execute("""
        CREATE TRIGGER trg_bloqueo_delete_func
        BEFORE DELETE ON Funcionalidad
        FOR EACH ROW
        BEGIN
          IF OLD.estado_funcion = 'En Progreso' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar una funcionalidad en progreso.';
          END IF;
        END
        """)
        
        # Rehabilitar foreign key checks
        cur.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        conn.commit()
        print("\n✅ Despoblamiento completado exitosamente")
        print("📊 La base de datos está ahora vacía y lista para nuevos datos")

    except Exception as e:
        conn.rollback()
        print(f"\n❌ Error durante el despoblamiento: {e}")
        print("🔄 Se ha realizado rollback de los cambios")
    finally:
        cur.close()
        conn.close()

def verificar_vaciado():
    """Función para verificar que todas las tablas estén vacías"""
    conn = mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        port=DB_PORT
    )
    cur = conn.cursor()
    
    print("\n🔍 Verificación post-despoblamiento:")
    
    tables = [
        'Auth_User', 'Usuario', 'Ingeniero', 'Topico',
        'Funcionalidad', 'Criterio_Aceptacion', 'Resena_Funcionalidad',
        'ErrorBug', 'Resena_Error',
        'Ingeniero_Especialidad', 'Asignacion_Funcionalidad', 'Asignacion_Error'
    ]
    
    all_empty = True
    for table in tables:
        try:
            cur.execute(f'SELECT COUNT(*) FROM {table}')
            count = cur.fetchone()[0]
            status = "✅ Vacía" if count == 0 else f"⚠️  {count} registros"
            print(f"  {table}: {status}")
            if count > 0:
                all_empty = False
        except Exception as e:
            print(f"  {table}: ❌ Error - {e}")
    
    if all_empty:
        print("\n🎉 ¡Todas las tablas están vacías!")
    else:
        print("\n⚠️  Algunas tablas aún contienen datos")
    
    conn.close()

if __name__ == "__main__":
    # Solicitar confirmación del usuario
    print("⚠️  ADVERTENCIA: Este script eliminará TODOS los datos de la base de datos")
    print(f"   Base de datos: {DB_NAME}")
    print(f"   Servidor: {DB_HOST}:{DB_PORT}")
    
    confirmacion = input("\n¿Estás seguro de que quieres continuar? (escribe 'SI' para confirmar): ")
    
    if confirmacion.upper() == 'SI':
        main()
        verificar_vaciado()
    else:
        print("❌ Operación cancelada por el usuario")
        print("💡 Para confirmar, debes escribir exactamente 'SI'")
