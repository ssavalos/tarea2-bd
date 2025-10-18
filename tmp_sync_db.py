import mysql.connector

conn = mysql.connector.connect(host='127.0.0.1', user='root', password='', database='tarea2', port=3306, autocommit=True)
cur = conn.cursor()

statements = [
    "ALTER TABLE Funcionalidad ADD COLUMN IF NOT EXISTS resuelto_en DATETIME NULL",
    "ALTER TABLE ErrorBug ADD COLUMN IF NOT EXISTS resuelto_en DATETIME NULL",
    "UPDATE Funcionalidad SET resuelto_en = NOW() WHERE resuelto_en IS NULL AND estado_funcion IN ('Resuelto','Cerrado')",
    "UPDATE ErrorBug SET resuelto_en = NOW() WHERE resuelto_en IS NULL AND estado_error IN ('Resuelto','Cerrado')"
]
for stmt in statements:
    cur.execute(stmt)

proc_sql = """
DROP PROCEDURE IF EXISTS sp_asignar_funcionalidad;
CREATE PROCEDURE sp_asignar_funcionalidad(IN p_id_func INT, IN p_id_topico INT)
BEGIN
  INSERT IGNORE INTO Asignacion_Funcionalidad (id_funcionalidad, ing_rut)
  SELECT p_id_func, ie.ing_rut
  FROM Ingeniero_Especialidad ie
  LEFT JOIN (
    SELECT ing_rut, COUNT(*) AS carga
    FROM (
      SELECT ing_rut FROM Asignacion_Funcionalidad
      UNION ALL
      SELECT ing_rut FROM Asignacion_Error
    ) tot
    GROUP BY ing_rut
  ) c ON c.ing_rut = ie.ing_rut
  WHERE ie.id_topico = p_id_topico
  ORDER BY COALESCE(c.carga,0), ie.ing_rut
  LIMIT 3;
END;
"""
for _ in cur.execute(proc_sql, multi=True):
    pass

proc_sql = """
DROP PROCEDURE IF EXISTS sp_asignar_error;
CREATE PROCEDURE sp_asignar_error(IN p_id_bug INT, IN p_id_topico INT)
BEGIN
  INSERT IGNORE INTO Asignacion_Error (id_bug, ing_rut)
  SELECT p_id_bug, ie.ing_rut
  FROM Ingeniero_Especialidad ie
  LEFT JOIN (
    SELECT ing_rut, COUNT(*) AS carga
    FROM (
      SELECT ing_rut FROM Asignacion_Funcionalidad
      UNION ALL
      SELECT ing_rut FROM Asignacion_Error
    ) tot
    GROUP BY ing_rut
  ) c ON c.ing_rut = ie.ing_rut
  WHERE ie.id_topico = p_id_topico
  ORDER BY COALESCE(c.carga,0), ie.ing_rut
  LIMIT 3;
END;
"""
for _ in cur.execute(proc_sql, multi=True):
    pass

view_sql = """
DROP VIEW IF EXISTS v_asignado_a_ingeniero;
CREATE VIEW v_asignado_a_ingeniero AS
SELECT 'funcionalidad' AS tipo,
       af.ing_rut,
       f.id_funcionalidad AS id_solicitud,
       f.titulo_funcion AS titulo,
       t.nombre_topico AS topico,
       f.estado_funcion AS estado,
       f.fecha_funcion AS fecha,
       f.resumen_funcion,
       f.ambiente_funcion,
       u.user_nombre AS solicitante,
       u.user_rut AS solicitante_rut
FROM Asignacion_Funcionalidad af
JOIN Funcionalidad f ON f.id_funcionalidad = af.id_funcionalidad
JOIN Topico t ON t.id_topico = f.id_topico
JOIN Usuario u ON u.user_rut = f.user_rut
UNION ALL
SELECT 'error',
       ae.ing_rut,
       e.id_bug,
       e.titulo_error,
       t.nombre_topico,
       e.estado_error,
       e.fecha_error,
       e.descripcion_error AS resumen_funcion,
       NULL AS ambiente_funcion,
       u.user_nombre,
       u.user_rut
FROM Asignacion_Error ae
JOIN ErrorBug e ON e.id_bug = ae.id_bug
JOIN Topico t ON t.id_topico = e.id_topico
JOIN Usuario u ON u.user_rut = e.user_rut;
"""
for _ in cur.execute(view_sql, multi=True):
    pass

trigger_sql = """
DROP TRIGGER IF EXISTS trg_min_3_criterios;
DROP TRIGGER IF EXISTS trg_max_2_especialidades;
DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_func;
DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_func_update;
DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_error;
DROP TRIGGER IF EXISTS trg_no_titulo_duplicado_error_update;
DROP TRIGGER IF EXISTS trg_max_20_asignaciones_func;
DROP TRIGGER IF EXISTS trg_max_20_asignaciones_error;
DROP TRIGGER IF EXISTS trg_limite_diario_func;
DROP TRIGGER IF EXISTS trg_limite_diario_error;

CREATE TRIGGER trg_min_3_criterios
AFTER DELETE ON Criterio_Aceptacion
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Criterio_Aceptacion WHERE id_funcionalidad = OLD.id_funcionalidad;
  IF n < 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cada funcionalidad debe tener al menos 3 criterios.';
  END IF;
END;

CREATE TRIGGER trg_max_2_especialidades
BEFORE INSERT ON Ingeniero_Especialidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Ingeniero_Especialidad WHERE ing_rut = NEW.ing_rut;
  IF n >= 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener más de 2 especialidades.';
  END IF;
END;

CREATE TRIGGER trg_no_titulo_duplicado_func
BEFORE INSERT ON Funcionalidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad WHERE titulo_funcion = NEW.titulo_funcion;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una funcionalidad con este título.';
  END IF;
END;

CREATE TRIGGER trg_no_titulo_duplicado_func_update
BEFORE UPDATE ON Funcionalidad
FOR EACH ROW
BEGIN
  IF NEW.titulo_funcion <> OLD.titulo_funcion THEN
    DECLARE n INT;
    SELECT COUNT(*) INTO n FROM Funcionalidad WHERE titulo_funcion = NEW.titulo_funcion AND id_funcionalidad <> NEW.id_funcionalidad;
    IF n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una funcionalidad con este título.';
    END IF;
  END IF;
END;

CREATE TRIGGER trg_no_titulo_duplicado_error
BEFORE INSERT ON ErrorBug
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug WHERE titulo_error = NEW.titulo_error;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un error con este título.';
  END IF;
END;

CREATE TRIGGER trg_no_titulo_duplicado_error_update
BEFORE UPDATE ON ErrorBug
FOR EACH ROW
BEGIN
  IF NEW.titulo_error <> OLD.titulo_error THEN
    DECLARE n INT;
    SELECT COUNT(*) INTO n FROM ErrorBug WHERE titulo_error = NEW.titulo_error AND id_bug <> NEW.id_bug;
    IF n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un error con este título.';
    END IF;
  END IF;
END;

CREATE TRIGGER trg_max_20_asignaciones_func
BEFORE INSERT ON Asignacion_Funcionalidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Asignacion_Funcionalidad WHERE ing_rut = NEW.ing_rut;
  IF n >= 20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener más de 20 funcionalidades asignadas.';
  END IF;
END;

CREATE TRIGGER trg_max_20_asignaciones_error
BEFORE INSERT ON Asignacion_Error
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Asignacion_Error WHERE ing_rut = NEW.ing_rut;
  IF n >= 20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener más de 20 errores asignados.';
  END IF;
END;

CREATE TRIGGER trg_limite_diario_func
BEFORE INSERT ON Funcionalidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad WHERE user_rut = NEW.user_rut AND fecha_funcion = CURDATE();
  IF n >= 25 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Has alcanzado el máximo de 25 funcionalidades por día.';
  END IF;
END;

CREATE TRIGGER trg_limite_diario_error
BEFORE INSERT ON ErrorBug
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug WHERE user_rut = NEW.user_rut AND fecha_error = CURDATE();
  IF n >= 25 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Has alcanzado el máximo de 25 errores por día.';
  END IF;
END;
"""
for _ in cur.execute(trigger_sql, multi=True):
    pass

cur.close()
conn.close()
