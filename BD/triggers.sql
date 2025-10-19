DELIMITER $$

CREATE TRIGGER trg_min_3_criterios
AFTER DELETE ON Criterio_Aceptacion
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Criterio_Aceptacion WHERE id_funcionalidad = OLD.id_funcionalidad;
  IF n < 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cada funcionalidad debe tener al menos 3 criterios.';
  END IF;
END$$

CREATE TRIGGER trg_max_2_especialidades
BEFORE INSERT ON Ingeniero_Especialidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Ingeniero_Especialidad WHERE ing_rut = NEW.ing_rut;
  IF n >= 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener más de 2 especialidades.';
  END IF;
END$$

CREATE TRIGGER trg_bloqueo_update_func
BEFORE UPDATE ON Funcionalidad
FOR EACH ROW
BEGIN
  IF OLD.estado_funcion = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar una funcionalidad en progreso.';
  END IF;
END$$

CREATE TRIGGER trg_bloqueo_delete_func
BEFORE DELETE ON Funcionalidad
FOR EACH ROW
BEGIN
  IF OLD.estado_funcion = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar una funcionalidad en progreso.';
  END IF;
END$$

-- Trigger: No se permiten títulos duplicados del mismo tipo de solicitud
CREATE TRIGGER trg_no_titulo_duplicado_func
BEFORE INSERT ON Funcionalidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad WHERE titulo_funcion = NEW.titulo_funcion;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una funcionalidad con este título.';
  END IF;
END$$

CREATE TRIGGER trg_no_titulo_duplicado_func_update
BEFORE UPDATE ON Funcionalidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad WHERE titulo_funcion = NEW.titulo_funcion AND id_funcionalidad != NEW.id_funcionalidad;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una funcionalidad con este título.';
  END IF;
END$$

CREATE TRIGGER trg_no_titulo_duplicado_error
BEFORE INSERT ON ErrorBug
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug WHERE titulo_error = NEW.titulo_error;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un error con este título.';
  END IF;
END$$

CREATE TRIGGER trg_no_titulo_duplicado_error_update
BEFORE UPDATE ON ErrorBug
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug WHERE titulo_error = NEW.titulo_error AND id_bug != NEW.id_bug;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un error con este título.';
  END IF;
END$$

-- Trigger: Un Ingeniero puede estar asignado a un máximo de 20 solicitudes
CREATE TRIGGER trg_max_20_asignaciones_func
BEFORE INSERT ON Asignacion_Funcionalidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Asignacion_Funcionalidad WHERE ing_rut = NEW.ing_rut;
  IF n >= 20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener más de 20 funcionalidades asignadas.';
  END IF;
END$$

CREATE TRIGGER trg_max_20_asignaciones_error
BEFORE INSERT ON Asignacion_Error
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Asignacion_Error WHERE ing_rut = NEW.ing_rut;
  IF n >= 20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener más de 20 errores asignados.';
  END IF;
END$$

-- Trigger: Validación diaria de límite de solicitudes (backup a nivel BD)
CREATE TRIGGER trg_limite_diario_func
BEFORE INSERT ON Funcionalidad
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad 
  WHERE user_rut = NEW.user_rut AND DATE(fecha_funcion) = CURDATE();
  IF n >= 25 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Has alcanzado el máximo de 25 funcionalidades por día.';
  END IF;
END$$

CREATE TRIGGER trg_limite_diario_error
BEFORE INSERT ON ErrorBug
FOR EACH ROW
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug 
  WHERE user_rut = NEW.user_rut AND DATE(fecha_error) = CURDATE();
  IF n >= 25 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Has alcanzado el máximo de 25 errores por día.';
  END IF;
END$$

-- Triggers adicionales para errores "En Progreso"
CREATE TRIGGER trg_bloqueo_update_error
BEFORE UPDATE ON ErrorBug
FOR EACH ROW
BEGIN
  IF OLD.estado_error = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar un error en progreso.';
  END IF;
END$$

CREATE TRIGGER trg_bloqueo_delete_error
BEFORE DELETE ON ErrorBug
FOR EACH ROW
BEGIN
  IF OLD.estado_error = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar un error en progreso.';
  END IF;
END$$

DELIMITER ;
