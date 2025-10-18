CREATE OR REPLACE VIEW v_asignado_a_ingeniero AS
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
