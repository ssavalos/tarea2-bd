CREATE OR REPLACE VIEW v_asignado_a_ingeniero AS
SELECT 'funcionalidad' AS tipo, af.ing_rut, f.id_funcionalidad AS id,
       f.titulo_funcion AS titulo, t.nombre_topico AS topico,
       f.estado_funcion AS estado, f.fecha_funcion AS fecha
FROM Asignacion_Funcionalidad af
JOIN Funcionalidad f ON f.id_funcionalidad = af.id_funcionalidad
JOIN Topico t ON t.id_topico = f.id_topico
UNION ALL
SELECT 'error', ae.ing_rut, e.id_bug, e.titulo_error,
       t.nombre_topico, e.estado_error, e.fecha_error
FROM Asignacion_Error ae
JOIN ErrorBug e ON e.id_bug = ae.id_bug
JOIN Topico t ON t.id_topico = e.id_topico;
