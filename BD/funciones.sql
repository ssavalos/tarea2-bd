DELIMITER $$

CREATE FUNCTION fn_total_solicitudes_usuario(p_user_rut VARCHAR(12))
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE n INT;
  SELECT (
    (SELECT COUNT(*) FROM Funcionalidad WHERE user_rut = p_user_rut) +
    (SELECT COUNT(*) FROM ErrorBug WHERE user_rut = p_user_rut)
  ) INTO n;
  RETURN n;
END$$

DELIMITER ;
