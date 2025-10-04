DELIMITER $$

CREATE PROCEDURE sp_asignar_funcionalidad(IN p_id_func INT, IN p_id_topico INT)
BEGIN
  INSERT INTO Asignacion_Funcionalidad (id_funcionalidad, ing_rut)
  SELECT p_id_func, ie.ing_rut
  FROM Ingeniero_Especialidad ie
  LEFT JOIN (
    SELECT ing_rut, COUNT(*) AS carga
    FROM (
      SELECT ing_rut FROM Asignacion_Funcionalidad
      UNION ALL
      SELECT ing_rut FROM Asignacion_Error
    ) x GROUP BY ing_rut
  ) c ON c.ing_rut = ie.ing_rut
  WHERE ie.id_topico = p_id_topico
    AND COALESCE(c.carga,0) < 20
  ORDER BY COALESCE(c.carga,0) ASC
  LIMIT 3;
END$$

CREATE PROCEDURE sp_asignar_error(IN p_id_bug INT, IN p_id_topico INT)
BEGIN
  INSERT INTO Asignacion_Error (id_bug, ing_rut)
  SELECT p_id_bug, ie.ing_rut
  FROM Ingeniero_Especialidad ie
  LEFT JOIN (
    SELECT ing_rut, COUNT(*) AS carga
    FROM (
      SELECT ing_rut FROM Asignacion_Funcionalidad
      UNION ALL
      SELECT ing_rut FROM Asignacion_Error
    ) x GROUP BY ing_rut
  ) c ON c.ing_rut = ie.ing_rut
  WHERE ie.id_topico = p_id_topico
    AND COALESCE(c.carga,0) < 20
  ORDER BY COALESCE(c.carga,0) ASC
  LIMIT 3;
END$$

DELIMITER ;
