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

DELIMITER ;
