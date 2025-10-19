-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 19-10-2025 a las 23:33:11
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `tarea2`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_asignar_error` (IN `p_id_bug` INT, IN `p_id_topico` INT)   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_asignar_funcionalidad` (IN `p_id_func` INT, IN `p_id_topico` INT)   BEGIN
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

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_total_solicitudes_usuario` (`p_user_rut` VARCHAR(12)) RETURNS INT(11) DETERMINISTIC BEGIN
  DECLARE n INT;
  SELECT (
    (SELECT COUNT(*) FROM Funcionalidad WHERE user_rut = p_user_rut) +
    (SELECT COUNT(*) FROM ErrorBug WHERE user_rut = p_user_rut)
  ) INTO n;
  RETURN n;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asignacion_error`
--

CREATE TABLE `asignacion_error` (
  `id_bug` int(11) NOT NULL,
  `ing_rut` varchar(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `asignacion_error`
--

INSERT INTO `asignacion_error` (`id_bug`, `ing_rut`) VALUES
(302, '10344146-K'),
(302, '12345678-0'),
(302, '1241284-1');

--
-- Disparadores `asignacion_error`
--
DELIMITER $$
CREATE TRIGGER `trg_max_20_asignaciones_error` BEFORE INSERT ON `asignacion_error` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Asignacion_Error WHERE ing_rut = NEW.ing_rut;
  IF n >= 20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener m├ís de 20 errores asignados.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asignacion_funcionalidad`
--

CREATE TABLE `asignacion_funcionalidad` (
  `id_funcionalidad` int(11) NOT NULL,
  `ing_rut` varchar(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `asignacion_funcionalidad`
--

INSERT INTO `asignacion_funcionalidad` (`id_funcionalidad`, `ing_rut`) VALUES
(213, '11014145-K'),
(213, '12345678-0'),
(213, '13179613-4'),
(215, '14275203-K'),
(215, '15198153-3'),
(215, '16396513-2');

--
-- Disparadores `asignacion_funcionalidad`
--
DELIMITER $$
CREATE TRIGGER `trg_max_20_asignaciones_func` BEFORE INSERT ON `asignacion_funcionalidad` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Asignacion_Funcionalidad WHERE ing_rut = NEW.ing_rut;
  IF n >= 20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener m├ís de 20 funcionalidades asignadas.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_user`
--

CREATE TABLE `auth_user` (
  `id` int(11) NOT NULL,
  `rut` varchar(12) NOT NULL,
  `pass_hash` varchar(255) NOT NULL,
  `rol` enum('usuario','ingeniero') NOT NULL
) ;

--
-- Volcado de datos para la tabla `auth_user`
--

INSERT INTO `auth_user` (`id`, `rut`, `pass_hash`, `rol`) VALUES
(2, '12345678-9', '$2y$10$SQ7r3O.hJTZRxj5K6KN1iu5lN62no/N7UsN3MiE97mZ/NiH9INN3i', 'usuario'),
(3, '12345678-0', '$2y$10$CoGJbBt7zkpZi0zxDgROj.7X5QyRbeUnQIrCeCAsSWUTpvUixZnUW', 'ingeniero');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `criterio_aceptacion`
--

CREATE TABLE `criterio_aceptacion` (
  `id_criterio` int(11) NOT NULL,
  `descripcion_criterio` text NOT NULL,
  `id_funcionalidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `criterio_aceptacion`
--

INSERT INTO `criterio_aceptacion` (`id_criterio`, `descripcion_criterio`, `id_funcionalidad`) VALUES
(1, 'Hay posibilidad siguientes unas sangre padre.', 1),
(2, 'Expresión poco cámara cuba gracias acuerdo niños datos.', 1),
(3, 'Y señora aún siguientes cosas historia mayores.', 1),
(4, 'Proceso obra tenían dicho hay mar.', 2),
(5, 'Plaza constitución objetivo entrar otro dejó.', 2),
(6, 'Según casos incluso difícil.', 2),
(7, 'Lado empresa dos n.', 3),
(8, 'Contenido capaz nosotros maría bajo.', 3),
(9, 'Curso parecía economía luego análisis habrá.', 3),
(10, 'Autor tema libre américa sola diciembre pocos.', 4),
(11, 'Televisión cuando españoles partes zonas queda rosa.', 4),
(12, 'Estudio especialmente educación fuego constitución mayores.', 4),
(13, 'Principio marco crecimiento tema reforma deben.', 5),
(14, 'Vino prensa tema película.', 5),
(15, 'Banco zona importante.', 5),
(16, 'Profesional análisis día camino uso existe cuarto.', 6),
(17, 'Aún estuvo pueblo sean esto organización podía nosotros.', 6),
(18, 'Película presencia función muy esas unión.', 6),
(19, 'Menos civil señor algún.', 7),
(20, 'Unidad p tarde mesa comisión civil corte.', 7),
(21, 'Va hoy universidad nadie dólares.', 7),
(22, 'Futuro según boca eso alguien pública jefe.', 8),
(23, 'Música pone siquiera soy partes propuesta consejo.', 8),
(24, 'Uso mucho régimen consecuencia.', 8),
(25, 'Políticos b negro tras ésta punto.', 9),
(26, 'Social alrededor elecciones hacen había pueda.', 9),
(27, 'Aun lado mí real.', 9),
(28, 'Hijo doctor pueda antes.', 10),
(29, 'Ambos chile país haber domingo.', 10),
(30, 'Buscar local los felipe fuego fuerza.', 10),
(31, 'A cerca problemas luego b partidos.', 11),
(32, 'Mantener estados título quiere anterior.', 11),
(33, 'Unión posición norte expresión salida e.', 11),
(34, 'Exterior por estaban quería pudo niños llegó diciembre.', 12),
(35, 'Concepto lo idea mujer abril solución era.', 12),
(36, 'Una máximo noche proyecto este primero.', 12),
(37, 'Varios busca construcción.', 13),
(38, 'Cuadro fuera una mano contrario ante ciencia.', 13),
(39, 'Congreso así memoria intereses presidente ayuda persona.', 13),
(40, 'Junto juego objeto cantidad producción bueno rodríguez.', 14),
(41, 'Elecciones produce problemas memoria vio media martín.', 14),
(42, 'Pie causa empresas más.', 14),
(43, 'Octubre principio diario considera carlos república existen.', 15),
(44, 'Especial qué democracia tenido.', 15),
(45, 'Millones período de común asimismo consumo donde decir.', 15),
(46, 'Nombre policía hace ese perdido contenido p.', 16),
(47, 'Como empresa pablo.', 16),
(48, 'Construcción domingo carácter.', 16),
(49, 'Próximo nos propia sido tiene imagen.', 17),
(50, 'Capaz esas cuatro don mes primeros económica secretario.', 17),
(51, 'Atrás palabra antes esa josé lenguaje seguro.', 17),
(52, 'Blanca viaje podemos estructura resultados américa.', 18),
(53, 'Empresas cultura nuestro ninguna investigación decisión quedó.', 18),
(54, 'Objeto análisis relación efectos luz miembros.', 18),
(55, 'Consumo miguel trabajo blanco niveles cambio.', 19),
(56, 'Y elecciones pedro dio jamás.', 19),
(57, 'Especialmente artículo al situación capacidad.', 19),
(58, 'Ejemplo universidad cambio.', 20),
(59, 'Pensar campo estar hacen imagen electoral.', 20),
(60, 'Su año llevar saber.', 20),
(61, 'Vivir imágenes este.', 21),
(62, 'Elementos has falta precisamente millones club.', 21),
(63, 'Autor policía relación embargo madrid aumento.', 21),
(64, 'Educación aquí esos actitud adelante.', 22),
(65, 'Mira mitad actitud tenía.', 22),
(66, 'Origen elecciones g segunda.', 22),
(67, 'América podrá misma campo.', 23),
(68, 'Empresas ellas miedo conciencia dentro ciento operación ver.', 23),
(69, 'Abril medios pablo uno estamos edad.', 23),
(70, 'Mayores reunión encuentran.', 24),
(71, 'Efectos lenguaje mayoría través libro todos nuestros.', 24),
(72, 'Pasado verdad realizar pp jefe parece ver.', 24),
(73, 'Hace salir pp casi aquel particular peor.', 25),
(74, 'Cuadro paso hubo sus zona resultado baja menor.', 25),
(75, 'Juez justicia libro salida.', 25),
(76, 'Forma junio hacerlo haber primero empresas hombres.', 26),
(77, 'Juan las socialista pesetas viaje.', 26),
(78, 'Tratamiento ejemplo revolución rosa también todos.', 26),
(79, 'Ser unidos mayores mayores estudio.', 27),
(80, 'Corte la corazón oficial este.', 27),
(81, 'Empresa media nombre trabajar alguien necesidad sea.', 27),
(82, 'Militares valor cuales dos suficiente pedro.', 28),
(83, 'Europea español seis comercio uno objetivo.', 28),
(84, 'Trabajar organización por quiero grandes.', 28),
(85, 'Realidad consejo empresa mirada.', 29),
(86, 'Rosa presencia español viaje varias existe.', 29),
(87, 'Día al sol llama sur fútbol.', 29),
(88, 'Esos yo primera dejar sin argentina.', 30),
(89, 'Muerte rafael encima precio población el.', 30),
(90, 'Otra deja casos crisis.', 30),
(91, 'Contenido segunda minutos demás.', 31),
(92, 'Corazón conocimiento guerra día través hijo consumo no.', 31),
(93, 'Precio jorge algunos música volver.', 31),
(94, 'Duda explicó países has grande vio color.', 32),
(95, 'Grupo causa encuentran perdido ocho.', 32),
(96, 'Sigue puede programa viaje origen importantes.', 32),
(97, 'Respecto dicen alto visto pudo.', 33),
(98, 'Electoral familia niños color mayor mantener.', 33),
(99, 'Estaban bajo mantener los.', 33),
(100, 'Puerta sueño quedó valor tu mi sigue serie.', 34),
(101, 'Aún dicen mirada flores unidos.', 34),
(102, 'Nivel garcía esos pueblo parís necesario.', 34),
(103, 'España domingo e existencia nos actividad democracia.', 35),
(104, 'Habían artículo considera eso natural.', 35),
(105, 'Idea hecho soy pronto pueda mucha sociales hubo.', 35),
(106, 'Película mantener hospital necesario capacidad allí viene.', 36),
(107, 'Rafael club dado aspecto dentro aquí ni.', 36),
(108, 'Esos teoría hicieron congreso.', 36),
(109, 'Juan radio medio personas presencia.', 37),
(110, 'Septiembre allá poder europa buenos.', 37),
(111, 'Existencia unidos puerta proyectos estoy.', 37),
(112, 'Sin puerto son obras hay media.', 38),
(113, 'Comunidad sus misma allí él mientras.', 38),
(114, 'Ni etc hijo resulta país sociedad especie.', 38),
(115, 'Dijo tratamiento conciencia algunas hasta hubiera presenta.', 39),
(116, 'Lugar últimos comisión hablar pequeña empresa entonces.', 39),
(117, 'Está creo asimismo.', 39),
(118, 'Importante reunión español además contra mejores.', 40),
(119, 'Asimismo alto dinero líder estuvo estar.', 40),
(120, 'Civil material lucha palabras dado aunque amigo.', 40),
(121, 'Asociación único carácter casos tu pues hijos.', 41),
(122, 'Partido señora cultura al existencia u.', 41),
(123, 'Obras últimos bajo.', 41),
(124, 'Siguiente cantidad idea última.', 42),
(125, 'Medidas conocer nuestros psoe tampoco tiene.', 42),
(126, 'Pasó p noche zonas debido.', 42),
(127, 'Éxito humano puso realidad ha.', 43),
(128, 'Política reforma expresión ello tenían.', 43),
(129, 'Título garcía sector presencia electoral semanas supuesto.', 43),
(130, 'Don líder población fuego.', 44),
(131, 'Hizo españa m efecto calle mar he pp.', 44),
(132, 'Jóvenes reunión aquellos superior europea solo.', 44),
(133, 'Dado va ver ii obra mí sistema.', 45),
(134, 'Autoridades fuego puedo argentina habla propuesta intereses.', 45),
(135, 'Sobre manera pueda cultura resultados dirección madrid cualquier.', 45),
(136, 'Oficial solamente cada puede.', 46),
(137, 'Hacía junto en internacional haciendo tenemos.', 46),
(138, 'General padres semanas había gran nuevo estaba.', 46),
(139, 'Económica puso quien llega francisco generales.', 47),
(140, 'Ante poder principal de iba aquel.', 47),
(141, 'Servicios realizar especie constitución unidos s pocos.', 47),
(142, 'Veces salir como otro.', 48),
(143, 'Grande podrá clase estar.', 48),
(144, 'Vida quería durante sea último.', 48),
(145, 'Pública deben costa reunión hemos.', 49),
(146, 'Hablar quería cuando carlos.', 49),
(147, 'Crecimiento político esfuerzo aquí considera tengo.', 49),
(148, 'Toda siendo banco.', 50),
(149, 'Voz espacio cuanto diferencia tú edad.', 50),
(150, 'Aumento santiago costa los había construcción libertad.', 50),
(151, 'Estos vuelta zonas felipe siguiente cual.', 51),
(152, 'Comisión realidad veces.', 51),
(153, 'Fuerte idea bastante septiembre.', 51),
(154, 'Muestra hecho crisis país tienen comunidad.', 52),
(155, 'Servicio haber habla nombre número llevar.', 52),
(156, 'Construcción jorge precio mientras habían adelante.', 52),
(157, 'Más elecciones profesional señor diciembre perdido haciendo.', 53),
(158, 'I poco ninguna.', 53),
(159, 'Nuestra todo abril n demás.', 53),
(160, 'Suficiente interior está.', 54),
(161, 'Campo pensar particular nadie primera debía pronto segunda.', 54),
(162, 'Llegado millones tenían tu sectores puso.', 54),
(163, 'Posibilidades volvió pero.', 55),
(164, 'Chile lópez entrada.', 55),
(165, 'Están acción solución llama mayo luz.', 55),
(166, 'Sector grupos existencia.', 56),
(167, 'Este mayor banco primer una imágenes mantener.', 56),
(168, 'Productos niños segunda las otros marcha.', 56),
(169, 'Ésta nosotros esto anterior mes ambiente causa.', 57),
(170, 'Miembros duda él mano mejores tienen han.', 57),
(171, 'Cine alguien precio torno situación carlos humanos.', 57),
(172, 'Creación principio argentina tratamiento.', 58),
(173, 'Jefe público enero popular primera.', 58),
(174, 'Sean consejo pocos central productos aumento.', 58),
(175, 'Nadie uno especie poco.', 59),
(176, 'Los producción mundo.', 59),
(177, 'Trabajo partidos ya plaza todos teatro reforma.', 59),
(178, 'Dar próximo vez estados libre humano hacia estas.', 60),
(179, 'Parece momentos uno pasar dijo miedo.', 60),
(180, 'Etc producto después educación.', 60),
(181, 'Fernando economía difícil interior siguientes superior jefe.', 61),
(182, 'Sentido países gran pesar hasta.', 61),
(183, 'Derechos casi acerca nada apoyo españa días.', 61),
(184, 'Fuerza tiene trabajadores solamente asociación economía.', 62),
(185, 'Mis toda noche.', 62),
(186, 'Acción marco soy pedro aspectos toma situación.', 62),
(187, 'Defensa chile existencia flores posición.', 63),
(188, 'Podía tiempos conciencia político permite.', 63),
(189, 'Fue concepto semana sentido.', 63),
(190, 'Volver bajo lo serie.', 64),
(191, 'Asimismo algunas ese ocasiones programas pensar instituto.', 64),
(192, 'Esos necesario cerca mundial resto corazón podía ex.', 64),
(193, 'Quiero seguir educación hay cambios idea explicó sino.', 65),
(194, 'Hizo uno mundo.', 65),
(195, 'Dolor volvió podría sin ayer piel.', 65),
(196, 'Medios principios en fuentes diario así mundial.', 66),
(197, 'Izquierda doctor mil dejar también razones.', 66),
(198, 'Mediante pasó largo seguro distintas mejores.', 66),
(199, 'Vamos obra produce violencia visto ello mediante.', 67),
(200, 'Presidente nueva piel debe me presidente.', 67),
(201, 'Entonces tras lo haya imágenes.', 67),
(202, 'París pregunta habría ex mismos.', 68),
(203, 'Precio intereses rosa civil fin alrededor dolor.', 68),
(204, 'Cierta nos cambio estudio.', 68),
(205, 'Decir idea mira.', 69),
(206, 'Mayores próximo diferencia viejo.', 69),
(207, 'Puedo tiene dirección peso problema temas marcha.', 69),
(208, 'Muy mejores acciones donde buena.', 70),
(209, 'Bastante visto mañana considera propuesta.', 70),
(210, 'Francisco país esa costa pablo manuel cual.', 70),
(211, 'Actividades imposible naturaleza intereses realidad mano.', 71),
(212, 'Joven van libro.', 71),
(213, 'Constitución riesgo propios estoy.', 71),
(214, 'Menos campaña voz pp.', 72),
(215, 'Nivel diciembre línea realidad además.', 72),
(216, 'Éxito parece abril tratamiento.', 72),
(217, 'Tanto trabajar hora información fueron semana.', 73),
(218, 'Hermano e aquí visto general.', 73),
(219, 'Junio nivel quiere ellas quería embargo viene.', 73),
(220, 'Mujeres primeras cuba siete.', 74),
(221, 'Evitar central fuentes situación cuyo hicieron razón.', 74),
(222, 'Ver medios mano respuesta luz medida.', 74),
(223, 'Época obras película cabeza valor caso información.', 75),
(224, 'Arte siglo distintos función encima.', 75),
(225, 'Blanco ayer pudo podía trata serie finalmente.', 75),
(226, 'Solución y cómo.', 76),
(227, 'Llegó otras hemos sus necesario año s.', 76),
(228, 'Señaló través distintas políticos.', 76),
(229, 'Policía que fueron eran.', 77),
(230, 'Volver madre diferencia conocimiento fuerza los señor.', 77),
(231, 'Difícil niño carta antes lugar tampoco militares.', 77),
(232, 'Bastante punto agua cuatro don algo hace.', 78),
(233, 'Partido público ha buenos reunión visita pueblo vamos.', 78),
(234, 'Cuya libre sido nuestra padre cuarto.', 78),
(235, 'Estoy parís propio tribunal haber situación.', 79),
(236, 'Creo pública sangre tendrá libre radio.', 79),
(237, 'Teoría partidos libros cultura superior tan.', 79),
(238, 'Pequeño última sangre r.', 80),
(239, 'Aquel cuadro méxico.', 80),
(240, 'Voluntad teoría sistemas mundo.', 80),
(241, 'Española dado existen partir muy partir entrada.', 81),
(242, 'Tiempos momento nuestras duda.', 81),
(243, 'Secretario quienes acerca aquel larga haciendo reforma.', 81),
(244, 'Durante éste permite siglo asimismo mar.', 82),
(245, 'Pasado años estar enero eso.', 82),
(246, 'Difícil mira mira tu número.', 82),
(247, 'Desarrollo edad menos líder junio comercio área.', 83),
(248, 'Queda debe único lleva puede.', 83),
(249, 'Reunión menos los ministro juez obra último.', 83),
(250, 'Ayer economía espacio diciembre.', 84),
(251, 'Hora ir no otras siempre vía.', 84),
(252, 'Aunque aspecto central comunidad especial.', 84),
(253, 'Mantener tiempos felipe especialmente.', 85),
(254, 'Pregunta autoridades ya parece ii informe fuera.', 85),
(255, 'Volver serie río puede casi silencio población futuro.', 85),
(256, 'Podía lenguaje llegó hija uno guerra luis.', 86),
(257, 'Hubo medida alrededor.', 86),
(258, 'Mercado imposible persona color necesidad mirada.', 86),
(259, 'Habla mediante base gran pesetas dólares.', 87),
(260, 'Militar familia jorge agua últimos fútbol.', 87),
(261, 'Internacional podrá este electoral particular seguridad sería.', 87),
(262, 'Padres sea voy suficiente recuerdo dónde.', 88),
(263, 'Misma cuadro bueno curso.', 88),
(264, 'Dolor menor política estructura jamás miedo aspecto.', 88),
(265, 'Llevar recursos casa cine porque.', 89),
(266, 'Posible imposible formación entrada primer.', 89),
(267, 'E gran comenzó demás una.', 89),
(268, 'Alrededor hijos varias hombre el dan.', 90),
(269, 'Unas nos toda fueron hablar poner sí.', 90),
(270, 'Situación marco nuestras amigos atrás.', 90),
(271, 'Comisión ocasión maría aquellos.', 91),
(272, 'Color o tú solución ellas.', 91),
(273, 'Actitud algunos todos sur.', 91),
(274, 'Exterior ve algunos volvió nuestro.', 92),
(275, 'Forma plazo última río pablo.', 92),
(276, 'Persona aspectos niño debido sido.', 92),
(277, 'Cultural derechos número profesional m r siendo características.', 93),
(278, 'Allí pese precios español.', 93),
(279, 'Posible d porque amor violencia.', 93),
(280, 'Partidos sociales interés verdad plan.', 94),
(281, 'Importantes teatro sólo encuentra estado.', 94),
(282, 'Algunos fuentes llamado dentro duda tu.', 94),
(283, 'Aquellos cerca energía cuales cosas operación vuelve cómo.', 95),
(284, 'Diferencia junto del llegado meses.', 95),
(285, 'Elecciones propuesta cierta.', 95),
(286, 'Como servicios otras allí.', 96),
(287, 'Tanto etapa sala alguien modelo grupos.', 96),
(288, 'Estuvo cine características.', 96),
(289, 'Mucho trata derechos muestra.', 97),
(290, 'Fuentes manera relaciones metros hacía marcha.', 97),
(291, 'Hijo cuando efecto produce decir uno escuela.', 97),
(292, 'Trata plazo verdad pueda papel.', 98),
(293, 'Valores llegar conseguir poco padre.', 98),
(294, 'Noviembre elementos efectos últimos recuerdo económica estudio derecha.', 98),
(295, 'Hacen miedo radio.', 99),
(296, 'García ahí juan palabras campo haciendo encontrar.', 99),
(297, 'Poco hacía julio bien.', 99),
(298, 'Haber los vista habrá investigación real tenemos.', 100),
(299, 'C época persona ciento.', 100),
(300, 'Se habrá dio ese francisco.', 100),
(301, 'Rafael llevar pie verdad encuentro.', 101),
(302, 'Iba seguro posibilidades muy paciente arriba zonas agua.', 101),
(303, 'Futuro ciento guerra tiempos noche cualquier.', 101),
(304, 'Realizar efectos menos casos.', 102),
(305, 'Dolor sólo mitad tarde investigación último civil.', 102),
(306, 'Régimen carta uno enfermedad oro ninguna pública.', 102),
(307, 'N mar mil ello.', 103),
(308, 'Estoy dijo parís forma últimos duda haber.', 103),
(309, 'Fue personal tenía presente revolución ellas poner última.', 103),
(310, 'Camino carlos crecimiento fuerte éxito.', 104),
(311, 'Quizá cierta cosa.', 104),
(312, 'Profesional rey partidos demasiado.', 104),
(313, 'Hizo mirada persona aunque boca haber.', 105),
(314, 'Mal había civil mercado valores muerte frente.', 105),
(315, 'Hacía valor tipo policía mis seguridad luis.', 105),
(316, 'Lleva ciencia se etapa lugar.', 106),
(317, 'Memoria mil sido siquiera ser tenían.', 106),
(318, 'Curso vía resulta.', 106),
(319, 'Amigo siglo lo recursos políticas.', 107),
(320, 'Aquellos sector especial haya podrá otra alta sociales.', 107),
(321, 'Seguridad mano cuyo escuela.', 107),
(322, 'Mí formas corazón cómo congreso casa américa.', 108),
(323, 'Habla nombre línea.', 108),
(324, 'Doctor sigue marcha consejo.', 108),
(325, 'Casos dios vida permite.', 109),
(326, 'España b crisis manera medida.', 109),
(327, 'Gobierno veces parece industria ningún.', 109),
(328, 'Capital corazón unas española gobierno.', 110),
(329, 'Prueba visto permite problema tales.', 110),
(330, 'Europa pedro casa los ex reforma.', 110),
(331, 'Podemos cuatro juicio importancia falta.', 111),
(332, 'Tarde respecto superior cual ciudad.', 111),
(333, 'Veces debido ante.', 111),
(334, 'Hoy jamás programas.', 112),
(335, 'María ello equipo población ese podía.', 112),
(336, 'Objeto número escuela alto personal.', 112),
(337, 'Tomar función miguel es recuerdo esos.', 113),
(338, 'Cierta amor mirada razones atención unas.', 113),
(339, 'Podemos fecha militares hoy.', 113),
(340, 'Sí mirada zonas verdad.', 114),
(341, 'Enfermedad esos conjunto algunos posición produce.', 114),
(342, 'Último algunos ni esfuerzo.', 114),
(343, 'Acto compañía encuentra ser número señor luz.', 115),
(344, 'Asociación contrario ninguna encuentra pablo toma libro.', 115),
(345, 'Nadie papel palabra frente radio atrás carlos.', 115),
(346, 'Palabras ni fueron hacía situación.', 116),
(347, 'Siguiente papel música importante sistema principios.', 116),
(348, 'Económica peor eso dar centros enfermedad podía.', 116),
(349, 'Cámara real hacía.', 117),
(350, 'Apenas izquierda viejo mayoría si.', 117),
(351, 'Humanos pueblo ayuda siempre.', 117),
(352, 'Mejor humanos derechos dicho dónde camino.', 118),
(353, 'Sector especial universidad segundo.', 118),
(354, 'Diario pasó él oro viene.', 118),
(355, 'Alta pese especie estamos.', 119),
(356, 'Cabeza edad están presente.', 119),
(357, 'Productos imposible solución quienes más armas.', 119),
(358, 'Sino demás dios unión tipos ideas.', 120),
(359, 'Tanto música vino minutos son sabía atrás.', 120),
(360, 'Vuelta eran fue acuerdo primera por costa.', 120),
(361, 'Situación instituciones color presente.', 121),
(362, 'Llegar r imágenes ayuda hemos.', 121),
(363, 'Ley este verdad ve dar.', 121),
(364, 'Arriba millones importante esas cosa niño.', 122),
(365, 'Conciencia sí ley seguridad rey.', 122),
(366, 'Tribunal aquellos cuenta instituciones me lo dar.', 122),
(367, 'Voz manos modelo modo deja material menor.', 123),
(368, 'Muchos ayuda plaza silencio.', 123),
(369, 'Aun cultura resulta mesa junio menor.', 123),
(370, 'Cierto energía tal sabía local.', 124),
(371, 'Alrededor habla industria estaban.', 124),
(372, 'Trabajar hechos pueblo mujeres ministro máximo análisis madre.', 124),
(373, 'Días sol curso banco.', 125),
(374, 'Plaza encuentra ministerio días podrá u entre.', 125),
(375, 'Amor cabeza solo hombres ciento.', 125),
(376, 'Después tienen información durante posible alguien color.', 126),
(377, 'Mientras cámara pp mucha hicieron tarde van.', 126),
(378, 'Aspectos libros aquel mira.', 126),
(379, 'Siete libro desarrollo manos todas llevar pasó.', 127),
(380, 'Punto tribunal deja informe texto permite pesetas.', 127),
(381, 'Formación dinero muchos todavía.', 127),
(382, 'Nuevo tanto concepto saber son pues plan.', 128),
(383, 'Su i o cambio.', 128),
(384, 'Cultural gracias puesto blanca.', 128),
(385, 'Libre imágenes nada encima.', 129),
(386, 'Capacidad tiene dado seguir importante cabo.', 129),
(387, 'Tu problema período amor.', 129),
(388, 'Tenía como parecía diciembre color general hospital manuel.', 130),
(389, 'Manos civil por contrario trabajar autoridades valores comercio.', 130),
(390, 'Cabeza cualquier alto fuerza.', 130),
(391, 'Tener formas partidos humanos.', 131),
(392, 'Rodríguez actividad aunque barcelona salud mañana tenido.', 131),
(393, 'Viene presenta alguien compañía capital principales lejos.', 131),
(394, 'Mira calidad lado punto vuelve creo.', 132),
(395, 'Padres fiscal hombres.', 132),
(396, 'Cambios rosa grupos médico.', 132),
(397, 'Producción investigación medidas cuarto secretario pablo.', 133),
(398, 'Derechos texto que después juez dios miembros.', 133),
(399, 'Esas formas mantener joven esos vivir.', 133),
(400, 'Constitución si sangre habrá américa después estilo.', 134),
(401, 'Pp juan diario largo.', 134),
(402, 'Reforma palabras flores.', 134),
(403, 'Exterior muchos haber hombre europea.', 135),
(404, 'Junio millones al carta volvió.', 135),
(405, 'Proyectos cámara hubo conciencia.', 135),
(406, 'Española fuerza común grande antes todas.', 136),
(407, 'Cuadro universidad noviembre quiero estar.', 136),
(408, 'Fue centro recursos aún destino estas.', 136),
(409, 'Joven servicios blanco ellas cargo varias.', 137),
(410, 'Quizá aumento acerca compañía sido.', 137),
(411, 'Líder señora equipo producción ocasiones empresa creo.', 137),
(412, 'Otra resultado niño estructura etc cantidad españa.', 138),
(413, 'Partidos crisis unión nuestras qué.', 138),
(414, 'Tienen trabajadores martín hospital tenemos local política desde.', 138),
(415, 'Clase puede tras tiempo mercado servicio nivel sistemas.', 139),
(416, 'Modelo mujeres cuadro pregunta pocos.', 139),
(417, 'Sabía nacional saber origen hechos actitud persona.', 139),
(418, 'Dan juan quiero pesar seguir capaz nivel.', 140),
(419, 'Puerto material carácter quién voz formas.', 140),
(420, 'Intereses puntos cantidad minutos política las haber.', 140),
(421, 'Familia persona son fue.', 141),
(422, 'Medios movimiento muerte nueva organización operación.', 141),
(423, 'Haber ellas investigación esto.', 141),
(424, 'Intereses mirada trabajadores hoy esto cuarto.', 142),
(425, 'Mundo crecimiento hubiera resto.', 142),
(426, 'S distintos posible.', 142),
(427, 'Blanca tierra creo sur con nuestros.', 143),
(428, 'Cuando seguro consecuencia casi padres.', 143),
(429, 'Mujer una derechos espacio.', 143),
(430, 'Unas principal r.', 144),
(431, 'Aquellas ambiente político relaciones atrás nada solución serán.', 144),
(432, 'Derecho estamos enero podemos llegó blanca proceso fuentes.', 144),
(433, 'Cualquier objetivo tenemos palabras.', 145),
(434, 'Encuentra era calle deja señor universidad.', 145),
(435, 'S presente aquel comunidad un países mismo.', 145),
(436, 'Población según conciencia.', 146),
(437, 'Dios arriba nuestra encontrar fiscal la.', 146),
(438, 'Fueron los río es resto próximo.', 146),
(439, 'Vista pesar fácil hecho tuvo algo decir metros.', 147),
(440, 'Voz señaló sangre larga existen algunos época había.', 147),
(441, 'Servicio suerte decía producto creo sido.', 147),
(442, 'Está dice serán pueblo etapa chile cerca calle.', 148),
(443, 'Van encontrar popular área cuatro texto voz unidad.', 148),
(444, 'Público análisis premio local norte recuerdo.', 148),
(445, 'Del mientras ver sistemas propios segundo.', 149),
(446, 'Estado tal cierta cuales dado.', 149),
(447, 'Momento serán memoria alrededor entrada hijo.', 149),
(448, 'Trata casa local u construcción actual.', 150),
(449, 'Viejo obstante igual bien programa.', 150),
(450, 'Económica estudio voluntad problemas tratamiento vio norte eso.', 150),
(451, 'Cantidad así negro perdido oro economía domingo.', 151),
(452, 'Peso arte existencia época será respecto p.', 151),
(453, 'Además media igual miembros dan realizar mejor según.', 151),
(454, 'Decir europa unidos cuatro partir formas.', 152),
(455, 'Ellos presidente puntos.', 152),
(456, 'Ayuda nuevas claro algunas norte.', 152),
(457, 'Próximo base habrá.', 153),
(458, 'Tuvo niveles nombre sus hija.', 153),
(459, 'Corte joven segunda.', 153),
(460, 'Dentro octubre mismo uno.', 154),
(461, 'Participación dejó c adelante u.', 154),
(462, 'Conciencia sala español fuego.', 154),
(463, 'Asociación hablar pacientes madre civil salida.', 155),
(464, 'Título niños bien grado interior anterior.', 155),
(465, 'Alguna miedo orden mismo aquella cantidad.', 155),
(466, 'Pregunta efectos manera.', 156),
(467, 'Marzo tenía r luis se lleva.', 156),
(468, 'Diferencia estaban ideas asimismo resto cantidad obstante.', 156),
(469, 'Ello valores sistemas nuestras.', 157),
(470, 'Muchas diez dicho llevar.', 157),
(471, 'Misma hubo semana existe.', 157),
(472, 'Joven cambios francisco muerte toda.', 158),
(473, 'Muchos volvió ningún hija alrededor aire cambios.', 158),
(474, 'Defensa aun animales nuevas horas nosotros precio.', 158),
(475, 'Material políticas socialista sola miembros.', 159),
(476, 'El paciente habían siendo habrá televisión.', 159),
(477, 'Guerra junto razón.', 159),
(478, 'Nunca miguel hicieron.', 160),
(479, 'Te tú sólo deja del.', 160),
(480, 'Afirmó propuesta seguridad aspecto.', 160),
(481, 'Contrario primer hay silencio comercio hora compañía pocos.', 161),
(482, 'Volvió da semanas mes.', 161),
(483, 'Modo marcha realidad eran estas semana enfermedad hacía.', 161),
(484, 'Puedo clase congreso armas cuanto hijo primeros nuevos.', 162),
(485, 'Seguridad su razones elecciones distintas color primeras.', 162),
(486, 'Habrá cerca ejemplo baja estaba construcción época vino.', 162),
(487, 'Algunas seis pasó hasta.', 163),
(488, 'Cuestión guerra crisis otra causa van tu.', 163),
(489, 'Felipe llevar estados cosas haciendo.', 163),
(490, 'Dicho formación informe.', 164),
(491, 'Vida ésta proyecto falta nuestros grande.', 164),
(492, 'Naturaleza demasiado josé.', 164),
(493, 'Ojos tipo acto flores.', 165),
(494, 'Palabra quedó ya durante.', 165),
(495, 'Partido difícil falta artículo conseguir.', 165),
(496, 'Conciencia miembros por cultura mantener.', 166),
(497, 'Función principal vamos ese casa trabajo centro.', 166),
(498, 'De puesto rosa plazo posición saber.', 166),
(499, 'Muerte cámara aumento pública.', 167),
(500, 'Acción qué pueblo actitud.', 167),
(501, 'Entre sangre demás vamos primer.', 167),
(502, 'Siguiente fuerza ni natural uno materia.', 168),
(503, 'Nada vamos único natural servicios.', 168),
(504, 'Puntos ante permite causa don pp.', 168),
(505, 'Luz va pensar o bueno evitar diez.', 169),
(506, 'Podía medios movimiento posibilidad consecuencia veces tener.', 169),
(507, 'Silencio junto realizar quién presidente.', 169),
(508, 'Algo hospital políticas pp final miembros.', 170),
(509, 'Todas decir mundial ambiente aire siendo produce.', 170),
(510, 'Mediante pasó alta r señora mundial.', 170),
(511, 'Civil entrada llevar grandes vista han junto nivel.', 171),
(512, 'Aquellos del régimen méxico.', 171),
(513, 'Puerto n oro unión actividad todas serán humana.', 171),
(514, 'Cuatro educación finalmente dar jamás cierto cambio.', 172),
(515, 'Cierta arte diversas lejos seis fácil madre.', 172),
(516, 'Niños nadie cierta personal compañía larga conjunto.', 172),
(517, 'Cierta mañana paz hacía fuego.', 173),
(518, 'Duda resulta futuro problema presencia.', 173),
(519, 'Tenían soy además etc encuentra precios esta.', 173),
(520, 'Persona nuevas allí pie porque primera lejos.', 174),
(521, 'Temas diferencia hoy tienen.', 174),
(522, 'Porque septiembre programas sola acto.', 174),
(523, 'Plaza queda puedo constitución.', 175),
(524, 'Poco pronto militares hijo constitución situación difícil.', 175),
(525, 'Fuerzas o cambio próximo hacer.', 175),
(526, 'Políticos conjunto segundo manera marcha capaz médico.', 176),
(527, 'Función baja le memoria aparece.', 176),
(528, 'Dejar además pasar esto esa texto.', 176),
(529, 'Siquiera salida paciente amigo cualquier europea hizo.', 177),
(530, 'Hubo profesional común por conseguir hasta esos cultura.', 177),
(531, 'Zona posición otra.', 177),
(532, 'Precio dinero esta otra uno llegado.', 178),
(533, 'Fácil militar través principales valor segundo puso.', 178),
(534, 'Internacional tal recursos régimen primero.', 178),
(535, 'Etapa hombre humanos manos volver especie.', 179),
(536, 'Pie fuego formas.', 179),
(537, 'Aun partidos imposible hacía igual paso ahí políticas.', 179),
(538, 'Toda empresa tienen otro hombres participación estuvo.', 180),
(539, 'Exterior estados e lo.', 180),
(540, 'Cuenta pasó respuesta sido.', 180),
(541, 'Ojos mayo hasta libros mismos habría libros.', 181),
(542, 'Flores solamente fin caso vio.', 181),
(543, 'Carrera recursos hombre fuego corte trabajadores paso.', 181),
(544, 'Está los características lucha alguna.', 182),
(545, 'Considera fecha líder total forma.', 182),
(546, 'Acto fuentes mediante máximo.', 182),
(547, 'Nueva casos cierto río escuela presencia primeros sus.', 183),
(548, 'Salir mañana haya.', 183),
(549, 'Espacio hora existencia tema.', 183),
(550, 'Durante estoy buena consejo mujeres suerte.', 184),
(551, 'Tener puesto formas mal congreso pequeña juego.', 184),
(552, 'Calidad posibilidad futuro suficiente del mira.', 184),
(553, 'Vivir tu nivel tan.', 185),
(554, 'Sólo modo aparece hacerlo existe.', 185),
(555, 'Conciencia incluso todo mundial habría fernando acuerdo.', 185),
(556, 'Punto amigos pregunta podemos lo solución está.', 186),
(557, 'Primeras precios estamos medio fuerzas rey teoría espera.', 186),
(558, 'Varios expresión estaban le espacio plan proyecto.', 186),
(559, 'Humano cabo etc último corte objetivo noviembre juan.', 187),
(560, 'El centro ahora.', 187),
(561, 'Sé cara final haber.', 187),
(562, 'Razones lado semanas uso voluntad.', 188),
(563, 'Considera alrededor puerto control hubiera grupos puso quizá.', 188),
(564, 'Seguro razón situación muchos zona estilo.', 188),
(565, 'Está participación libre bueno.', 189),
(566, 'Debía cuarto crisis quienes grandes es.', 189),
(567, 'Encima propios esfuerzo volvió haciendo peso.', 189),
(568, 'Minutos seguir estudios segunda dolor dentro quería.', 190),
(569, 'Sociedad mi próximo tipo estuvo calle tal cualquier.', 190),
(570, 'Cuba trabajo elecciones pueden orden san fuera.', 190),
(571, 'Tarde cabeza cuales verdad caso primera siete.', 191),
(572, 'Él diciembre nuestra alguna resultado alto trata mí.', 191),
(573, 'Esta aquel primeras político.', 191),
(574, 'Baja julio cual alta sino iglesia allá.', 192),
(575, 'Considera hacía línea buen.', 192),
(576, 'Memoria educación toda.', 192),
(577, 'Ver aspectos servicios dólares buen cambios armas ellos.', 193),
(578, 'Tenía mesa informe base importante ojos más pregunta.', 193),
(579, 'Sido estos atención política vino puso esfuerzo.', 193),
(580, 'Hospital fiscal personas pablo pablo demás.', 194),
(581, 'Obstante joven corazón quiero cuyo.', 194),
(582, 'Lleva más posible.', 194),
(583, 'Acciones esas es i puede.', 195),
(584, 'Uno industria destino actividades consejo media.', 195),
(585, 'Nacional juego administración solamente.', 195),
(586, 'Construcción oficial nunca música todo dice nos.', 196),
(587, 'Voy una central prueba nuevas españoles cuya allí.', 196),
(588, 'Hicieron siglo parece calle señora sector alrededor cabo.', 196),
(589, 'He cuatro hermano cuando estudios sería solución.', 197),
(590, 'Período hija ninguna américa rosa nuestro.', 197),
(591, 'Otros difícil próximo.', 197),
(592, 'U más nadie electoral forma tu haciendo.', 198),
(593, 'Técnica era cosa estamos autor.', 198),
(594, 'Fernando ocasiones hermano especial sobre arte.', 198),
(595, 'Amor allí clase nuestros sé premio.', 199),
(596, 'El cuyo joven trabajadores.', 199),
(597, 'Demás para sangre edad mañana.', 199),
(598, 'Varios semana van salida derechos tenían lejos.', 200),
(599, 'Cargo idea estaba mujer principios minutos meses.', 200),
(600, 'Mayor etc cámara cambios fútbol estudio he.', 200),
(615, 'criterio 1', 213),
(616, 'criterio 2', 213),
(617, 'criterio 3', 213),
(621, 'c1', 215),
(622, 'c2', 215),
(623, 'c3', 215);

--
-- Disparadores `criterio_aceptacion`
--
DELIMITER $$
CREATE TRIGGER `trg_min_3_criterios` AFTER DELETE ON `criterio_aceptacion` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Criterio_Aceptacion WHERE id_funcionalidad = OLD.id_funcionalidad;
  IF n < 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cada funcionalidad debe tener al menos 3 criterios.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `errorbug`
--

CREATE TABLE `errorbug` (
  `id_bug` int(11) NOT NULL,
  `titulo_error` varchar(100) NOT NULL,
  `descripcion_error` varchar(200) NOT NULL,
  `fecha_error` date NOT NULL,
  `estado_error` enum('Abierto','En Progreso','Resuelto','Cerrado') NOT NULL,
  `id_topico` int(11) NOT NULL,
  `user_rut` varchar(12) NOT NULL,
  `resuelto_en` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `errorbug`
--

INSERT INTO `errorbug` (`id_bug`, `titulo_error`, `descripcion_error`, `fecha_error`, `estado_error`, `id_topico`, `user_rut`, `resuelto_en`) VALUES
(1, 'Error 1', 'Memoria fondo iglesia alguien.', '2013-11-08', 'Cerrado', 6, '23487347-4', '2013-11-09 00:00:00'),
(2, 'Error 2', 'Millones viene habían cuarto primero pocos. Esta estas vía lugar.', '2011-12-23', 'Abierto', 4, '10837430-K', NULL),
(3, 'Error 3', 'Vivir antes premio dólares. Aire educación se puerto.', '2019-10-10', 'Cerrado', 9, '6457765-5', '2019-10-11 00:00:00'),
(4, 'Error 4', 'Palabra habían próximo como. Deja interior tratamiento período duda pequeño la.', '2011-10-07', 'Cerrado', 6, '5188470-6', '2011-10-08 00:00:00'),
(5, 'Error 5', 'Dentro martín quienes encuentro principales.', '2014-12-21', 'En Progreso', 2, '4245263-5', NULL),
(6, 'Error 6', 'Autor éxito tipo camino civil pública idea.', '2021-06-13', 'Abierto', 9, '24549181-K', NULL),
(7, 'Error 7', 'Siglo distintos habla prueba.', '2021-06-09', 'Cerrado', 6, '24532561-8', '2021-06-10 00:00:00'),
(8, 'Error 8', 'Podemos siquiera ha.', '2024-06-23', 'En Progreso', 2, '17956909-9', NULL),
(9, 'Error 9', 'Ocasión rosa características aquí medidas puso ser s. Durante ocho europea buscar viaje ellos.', '2013-04-14', 'En Progreso', 3, '6357277-6', NULL),
(10, 'Error 10', 'Cuerpo días camino estaban voz voy medida. Quería j especial su.', '2023-07-06', 'Abierto', 3, '17956909-9', NULL),
(11, 'Error 11', 'Artículo juego película quiero prensa vamos. Pie políticos económica siguientes puerta posible marco.', '2024-02-01', 'Cerrado', 10, '2537611-K', '2024-02-02 00:00:00'),
(12, 'Error 12', 'Pero color sueño pedro organización esfuerzo único número. Fuego p decisión.', '2022-12-31', 'Cerrado', 6, '21754078-5', '2023-01-01 00:00:00'),
(13, 'Error 13', 'Llegar segunda políticos gobierno. Río septiembre consumo dar voz.', '2013-05-21', 'Abierto', 8, '21754078-5', NULL),
(14, 'Error 14', 'Militares lópez familia primera proceso diversas pablo. Gobierno presencia encuentra realidad.', '2019-12-02', 'Cerrado', 5, '24549181-K', '2019-12-03 00:00:00'),
(15, 'Error 15', 'Económico historia lenguaje puesto mujeres así joven. Texto a salir televisión último.', '2023-04-07', 'Cerrado', 9, '5682115-1', '2023-04-08 00:00:00'),
(16, 'Error 16', 'Jorge tema formas octubre futuro.', '2011-08-31', 'Cerrado', 8, '12294238-1', '2011-09-01 00:00:00'),
(17, 'Error 17', 'Así idea programa cuenta minutos hacer. Capital encuentro conjunto buen diferentes cual.', '2010-11-05', 'Cerrado', 5, '5682115-1', '2010-11-06 00:00:00'),
(18, 'Error 18', 'Santiago socialista vino aspecto universidad banco también.', '2011-09-21', 'Abierto', 10, '22744459-1', NULL),
(19, 'Error 19', 'Política pues tribunal militar recursos. Queda muerte camino música tiempos participación.', '2023-04-29', 'Cerrado', 8, '8646997-4', '2023-04-30 00:00:00'),
(20, 'Error 20', 'Defensa uso puerto silencio toda.', '2023-01-07', 'Abierto', 8, '10327246-7', NULL),
(21, 'Error 21', 'Clase ocasiones su próximo u país señaló argentina.', '2022-10-28', 'En Progreso', 6, '22744459-1', NULL),
(22, 'Error 22', 'Ésta fuerte felipe resultados años economía.', '2023-07-28', 'En Progreso', 1, '24641507-1', NULL),
(23, 'Error 23', 'Grandes comunidad favor hacen modo sangre mes conjunto. Cosa puesto queda.', '2020-02-08', 'Cerrado', 2, '15157347-0', '2020-02-09 00:00:00'),
(24, 'Error 24', 'Defensa banco p.', '2021-04-26', 'En Progreso', 1, '22744459-1', NULL),
(25, 'Error 25', 'Opinión precio será nunca comunidad cámara ocho. Políticos consecuencia como antonio acuerdo especial tendrá.', '2015-07-23', 'Cerrado', 8, '16510878-6', '2015-07-24 00:00:00'),
(26, 'Error 26', 'Siguientes militares superior vez tierra fuentes. Aquellos libertad los vía través ocasiones día muchas.', '2021-10-03', 'En Progreso', 6, '3677374-3', NULL),
(27, 'Error 27', 'Puerta noviembre española incluso cara creo.', '2018-05-13', 'Cerrado', 7, '6217026-3', '2018-05-14 00:00:00'),
(28, 'Error 28', 'Producción clase etapa.', '2017-08-03', 'Abierto', 6, '6742460-8', NULL),
(29, 'Error 29', 'Relaciones cantidad hacerlo ii. Haber base habría victoria.', '2011-06-24', 'Abierto', 9, '4245263-5', NULL),
(30, 'Error 30', 'Sin mayor septiembre durante dentro ocho josé dónde. Minutos pablo volver espacio don tenido trata dio.', '2025-03-20', 'Cerrado', 5, '16415740-8', '2025-03-21 00:00:00'),
(31, 'Error 31', 'Mujer juan acuerdo profesional ocasión pensar plaza. Servicios ante popular gran gobierno.', '2024-09-22', 'En Progreso', 6, '12920906-3', NULL),
(32, 'Error 32', 'Solución carrera iba participación siendo.', '2011-10-30', 'En Progreso', 6, '6457765-5', NULL),
(33, 'Error 33', 'Pudo hablar cabeza. Poco violencia elecciones tenemos.', '2016-12-16', 'Cerrado', 3, '22744459-1', '2016-12-17 00:00:00'),
(34, 'Error 34', 'Libro miedo debido hablar.', '2023-05-07', 'Abierto', 5, '16510878-6', NULL),
(35, 'Error 35', 'Aquí últimos nueva viejo san.', '2022-07-15', 'Cerrado', 3, '16415740-8', '2022-07-16 00:00:00'),
(36, 'Error 36', 'Situación hermano nombre cosa mujeres.', '2025-01-11', 'Abierto', 7, '9214491-2', NULL),
(37, 'Error 37', 'Busca desde primero rodríguez imposible valores habla. Resultados tener vía cosas.', '2021-05-28', 'Abierto', 6, '9875847-0', NULL),
(38, 'Error 38', 'Fuera españa manera participación propuesta van. Ambos vio hechos trabajo fueron debe había encuentran.', '2016-12-05', 'En Progreso', 6, '7671884-K', NULL),
(39, 'Error 39', 'Zonas propuesta día flores viene. Partido conciencia toma volver.', '2020-11-27', 'En Progreso', 3, '24532561-8', NULL),
(40, 'Error 40', 'Tras hombres capaz jóvenes participación población soy. Iba figura banco lucha población esfuerzo pronto.', '2013-06-23', 'Cerrado', 2, '23706266-8', '2013-06-24 00:00:00'),
(41, 'Error 41', 'Puede cuyo guerra esos. Temas futuro cine trata justicia.', '2021-05-21', 'Abierto', 6, '11881122-0', NULL),
(42, 'Error 42', 'Reunión salud alrededor nos miembros violencia. Años necesario señaló material período misma conjunto apenas.', '2023-11-11', 'Cerrado', 3, '8336273-3', '2023-11-12 00:00:00'),
(43, 'Error 43', 'Te cinco cuyo servicios mujer. Decir nos carlos jefe.', '2013-08-22', 'En Progreso', 8, '7671884-K', NULL),
(44, 'Error 44', 'Juez realidad forma sistema niño encontrar puntos. Juego acerca entrada cuya.', '2010-12-24', 'Cerrado', 4, '3644095-8', '2010-12-25 00:00:00'),
(45, 'Error 45', 'Libre participación fuego hemos. Imagen parecía resulta sentido aquella ya psoe boca.', '2019-12-18', 'Cerrado', 8, '23487347-4', '2019-12-19 00:00:00'),
(46, 'Error 46', 'Aquellos superior estuvo ambiente carne julio deseo local.', '2015-04-01', 'En Progreso', 5, '4389045-6', NULL),
(47, 'Error 47', 'Da nuevos arriba quienes gobierno.', '2020-07-09', 'Cerrado', 10, '24532561-8', '2020-07-10 00:00:00'),
(48, 'Error 48', 'Cerca hijo sociedad a.', '2019-11-19', 'Cerrado', 7, '20372723-3', '2019-11-20 00:00:00'),
(49, 'Error 49', 'O estructura medios mundo quizá.', '2021-04-12', 'Cerrado', 3, '3677374-3', '2021-04-13 00:00:00'),
(50, 'Error 50', 'Paso juicio diversos mundo.', '2014-06-24', 'En Progreso', 5, '12920906-3', NULL),
(51, 'Error 51', 'Mejor c cámara poder ahí.', '2011-03-04', 'Cerrado', 6, '22744459-1', '2011-03-05 00:00:00'),
(52, 'Error 52', 'Aunque cerca pasar puerta.', '2022-06-09', 'Abierto', 5, '15157347-0', NULL),
(53, 'Error 53', 'S productos r pasado nuestros.', '2011-11-19', 'En Progreso', 5, '8369062-K', NULL),
(54, 'Error 54', 'Juez poner ciencia niveles.', '2020-01-29', 'En Progreso', 7, '8646997-4', NULL),
(55, 'Error 55', 'Fuerza grupos medio palabras actitud.', '2012-01-22', 'Cerrado', 6, '16072954-9', '2012-01-23 00:00:00'),
(56, 'Error 56', 'Resultados deben opinión partido joven iba. Plaza salud diez vez.', '2010-08-07', 'Abierto', 7, '3644095-8', NULL),
(57, 'Error 57', 'Varias estamos acuerdo elecciones escuela carta. País comisión razón datos.', '2021-04-05', 'En Progreso', 7, '9875847-0', NULL),
(58, 'Error 58', 'Especie pacientes arte unión escuela volvió.', '2011-10-31', 'En Progreso', 1, '9875847-0', NULL),
(59, 'Error 59', 'Otra jorge muerte partir niño pasar.', '2017-02-23', 'Cerrado', 3, '15157347-0', '2017-02-24 00:00:00'),
(60, 'Error 60', 'Lleva energía ahí estas quizá viaje.', '2013-02-01', 'Cerrado', 8, '9217207-3', '2013-02-02 00:00:00'),
(61, 'Error 61', 'Vez industria única modelo pues medio.', '2025-08-12', 'Cerrado', 8, '8336273-3', '2025-08-13 00:00:00'),
(62, 'Error 62', 'Enfermedad intereses fácil ahora llega uno ya.', '2023-10-20', 'Abierto', 1, '22455603-1', NULL),
(63, 'Error 63', 'Mí violencia final tengo produce nuestras. Siete contenido volvió domingo alrededor.', '2015-09-28', 'En Progreso', 9, '15076749-3', NULL),
(64, 'Error 64', 'Mirada participación esos obras. Futuro concepto que para cine prueba existen.', '2023-08-28', 'Cerrado', 2, '3677374-3', '2023-08-29 00:00:00'),
(65, 'Error 65', 'Casi madrid u blanco aspecto. Junto permite esfuerzo cantidad jorge nuestros mejor.', '2016-06-18', 'Cerrado', 2, '10334531-0', '2016-06-19 00:00:00'),
(66, 'Error 66', 'Comercio joven materia dado punto unidad pero derecha. Norte instituto actividad modelo encuentro.', '2011-01-27', 'Cerrado', 10, '10334531-0', '2011-01-28 00:00:00'),
(67, 'Error 67', 'Tan peso familia.', '2020-04-02', 'Abierto', 8, '23706266-8', NULL),
(68, 'Error 68', 'Pudo estado hospital encontrar. Comenzó enfermedad relación banco.', '2023-05-21', 'Abierto', 9, '4389045-6', NULL),
(69, 'Error 69', 'Real quienes corazón central.', '2022-11-24', 'En Progreso', 5, '10334531-0', NULL),
(70, 'Error 70', 'Trabajadores distintas pasado parece barcelona conocimiento cuya. Mí pesetas pasar iglesia señaló entonces.', '2019-08-18', 'Cerrado', 4, '22455603-1', '2019-08-19 00:00:00'),
(71, 'Error 71', 'Entonces vez aspectos ante. Dado estoy servicio mirada problema momentos segunda.', '2022-10-19', 'En Progreso', 2, '3644095-8', NULL),
(72, 'Error 72', 'Juan seguir modelo. Valores le desarrollo especial ideas como padres.', '2021-09-28', 'Abierto', 9, '9875847-0', NULL),
(73, 'Error 73', 'Habían hemos precisamente pasó vino. Habrá hacia señora iglesia.', '2022-03-16', 'Abierto', 7, '8646997-4', NULL),
(74, 'Error 74', 'Ex importantes favor existe base toda van. Quienes mismos falta pocos juicio imposible miedo.', '2020-07-18', 'Cerrado', 6, '9217207-3', '2020-07-19 00:00:00'),
(75, 'Error 75', 'Casos corte nacional carrera. Cierta conseguir algunas amigo toda.', '2015-09-09', 'Abierto', 6, '24090883-8', NULL),
(76, 'Error 76', 'Veces miguel crisis suficiente salir están alguna. Estructura tengo cultural.', '2011-07-08', 'En Progreso', 2, '12541238-9', NULL),
(77, 'Error 77', 'Formas partir pesar ninguna prueba.', '2023-01-19', 'Cerrado', 3, '24090883-8', '2023-01-20 00:00:00'),
(78, 'Error 78', 'Socialista condiciones estos éxito un. Elecciones reunión general general solución capital realizar país.', '2010-12-30', 'Cerrado', 3, '12541238-9', '2010-12-31 00:00:00'),
(79, 'Error 79', 'Va carácter cabo estoy secretario victoria momento.', '2025-05-10', 'Cerrado', 3, '20372723-3', '2025-05-11 00:00:00'),
(80, 'Error 80', 'Mis lucha deben usted capacidad. Difícil cine aire formación cámara respuesta naturaleza.', '2013-01-09', 'Cerrado', 1, '23706266-8', '2013-01-10 00:00:00'),
(81, 'Error 81', 'Fuentes libertad muerto casi.', '2016-07-31', 'Abierto', 4, '24532561-8', NULL),
(82, 'Error 82', 'Encima primera datos personal pesar grandes victoria nuestro.', '2010-12-10', 'Cerrado', 9, '4112034-6', '2010-12-11 00:00:00'),
(83, 'Error 83', 'Yo expresión natural trabajar. Jóvenes este éxito al juez.', '2018-12-07', 'Cerrado', 5, '4389045-6', '2018-12-08 00:00:00'),
(84, 'Error 84', 'Abril les vuelve da cantidad calle muchas. Pronto tierra silencio ejército origen una.', '2010-10-27', 'En Progreso', 5, '8369062-K', NULL),
(85, 'Error 85', 'B mar secretario varios problema equipo según. Posición casos pequeño sin razones y muy.', '2018-01-03', 'Abierto', 6, '11881122-0', NULL),
(86, 'Error 86', 'Veces tras conciencia josé general frente hace existe.', '2016-02-17', 'Cerrado', 7, '1999828-1', '2016-02-18 00:00:00'),
(87, 'Error 87', 'Valores misma juicio solamente.', '2018-12-21', 'Cerrado', 7, '24090883-8', '2018-12-22 00:00:00'),
(88, 'Error 88', 'Parte encuentro santiago todas negro esta pasa.', '2017-08-09', 'Cerrado', 8, '7671884-K', '2017-08-10 00:00:00'),
(89, 'Error 89', 'Medida felipe proyectos generales radio programas ningún.', '2018-03-29', 'Cerrado', 2, '3677374-3', '2018-03-30 00:00:00'),
(90, 'Error 90', 'Interior propio real hora importante operación qué conocer. Buena bajo destino encontrar.', '2019-07-10', 'Cerrado', 10, '3917183-9', '2019-07-11 00:00:00'),
(91, 'Error 91', 'Información va sean clase electoral régimen. Le tema ver.', '2014-01-18', 'Cerrado', 6, '4389045-6', '2014-01-19 00:00:00'),
(92, 'Error 92', 'Pasó corte conocer zonas esa presencia será.', '2012-04-20', 'Cerrado', 5, '3917183-9', '2012-04-21 00:00:00'),
(93, 'Error 93', 'Madrid existen salida m españa. Importante político especie.', '2016-11-15', 'Cerrado', 3, '21754078-5', '2016-11-16 00:00:00'),
(94, 'Error 94', 'Algún proceso poder estado. Siglo valor alguien volvió.', '2025-06-21', 'Cerrado', 8, '21754078-5', '2025-06-22 00:00:00'),
(95, 'Error 95', 'Último construcción que partido de real había.', '2010-12-13', 'Cerrado', 10, '10057945-K', '2010-12-14 00:00:00'),
(96, 'Error 96', 'Común importantes bueno. Dólares república puede propia trabajadores era contenido pp.', '2019-10-04', 'Abierto', 2, '12416912-4', NULL),
(97, 'Error 97', 'Comisión finalmente les esta fácil hospital.', '2025-01-20', 'Cerrado', 6, '24549181-K', '2025-01-21 00:00:00'),
(98, 'Error 98', 'Encontrar estados rafael año meses incluso.', '2021-07-05', 'En Progreso', 1, '24090883-8', NULL),
(99, 'Error 99', 'Memoria unas junto cómo. Período toda necesidad instituciones josé figura partes.', '2013-03-15', 'Cerrado', 1, '12920906-3', '2013-03-16 00:00:00'),
(100, 'Error 100', 'Deseo joven sí industria líder. Blanca lópez pesar efecto m.', '2012-10-31', 'En Progreso', 6, '23706266-8', NULL),
(101, 'Error 101', 'General psoe vez aquí haber radio madre. Padre cuatro figura llama.', '2018-02-14', 'Abierto', 10, '16415740-8', NULL),
(102, 'Error 102', 'Flores pueden nunca adelante clase último contrario imposible.', '2013-06-10', 'Cerrado', 6, '6742460-8', '2013-06-11 00:00:00'),
(103, 'Error 103', 'Da ella comercio vivir. Sociedad nombre podemos haber juego militares.', '2018-05-06', 'Abierto', 10, '21754078-5', NULL),
(104, 'Error 104', 'Producto conjunto juez tras servicios congreso podrá hizo. Iba en vuelta p congreso allí suficiente.', '2013-02-01', 'Cerrado', 7, '3677374-3', '2013-02-02 00:00:00'),
(105, 'Error 105', 'Efectos ambiente color noviembre título experiencia segundo.', '2017-01-19', 'Cerrado', 4, '22744459-1', '2017-01-20 00:00:00'),
(106, 'Error 106', 'Políticos casos cuerpo torno. Sería carne historia alrededor internacional medida sean personal.', '2012-07-18', 'En Progreso', 8, '1839221-4', NULL),
(107, 'Error 107', 'U servicios ciudad camino nuestros juan europea. Banco su tratamiento miedo miedo uso junto.', '2021-08-12', 'Abierto', 5, '16415740-8', NULL),
(108, 'Error 108', 'Cosa exterior grupos desde seguir decía operación.', '2015-11-03', 'Cerrado', 4, '16510878-6', '2015-11-04 00:00:00'),
(109, 'Error 109', 'En pone voy. Administración asunto somos mujer momento miembros deja.', '2023-09-22', 'Cerrado', 4, '6217026-3', '2023-09-23 00:00:00'),
(110, 'Error 110', 'Y salir políticas estaba más asimismo revolución. Película otro qué cultural pensar.', '2012-10-01', 'Abierto', 8, '8336273-3', NULL),
(111, 'Error 111', 'Edad pero tuvo joven ministro hoy. Necesidad función internacional cuanto.', '2013-11-15', 'Cerrado', 2, '16510878-6', '2013-11-16 00:00:00'),
(112, 'Error 112', 'Fin hace anterior media medidas dos voluntad. Posición buenos comercio otro palabras.', '2025-04-18', 'Cerrado', 2, '4112034-6', '2025-04-19 00:00:00'),
(113, 'Error 113', 'Máximo menor embargo dirección j maría.', '2022-05-03', 'Cerrado', 5, '4389045-6', '2022-05-04 00:00:00'),
(114, 'Error 114', 'Estado conciencia nuestro será adelante personal exterior.', '2013-07-14', 'En Progreso', 6, '16510878-6', NULL),
(115, 'Error 115', 'Única nivel apenas segunda seguridad ocasiones rodríguez centro.', '2021-05-30', 'Abierto', 4, '16072954-9', NULL),
(116, 'Error 116', 'Perdido verdad próximo somos embargo. Sueño derecha clase ex dinero momentos estaban u.', '2013-02-11', 'Cerrado', 1, '10334531-0', '2013-02-12 00:00:00'),
(117, 'Error 117', 'Formación sólo dinero. Muchas ella buenos.', '2018-02-04', 'Cerrado', 8, '10327246-7', '2018-02-05 00:00:00'),
(118, 'Error 118', 'Alguna música precios peor siquiera escuela ejemplo nuevas.', '2022-05-17', 'Abierto', 2, '8336273-3', NULL),
(119, 'Error 119', 'Hora españa etapa música libro.', '2016-12-08', 'Cerrado', 9, '5188470-6', '2016-12-09 00:00:00'),
(120, 'Error 120', 'Piel ocasión con. Centro mayo estudio derecha pasado.', '2019-03-20', 'Cerrado', 10, '11881122-0', '2019-03-21 00:00:00'),
(121, 'Error 121', 'Partir económica sistema. Posición educación ocasiones francia lleva económico.', '2011-08-28', 'Cerrado', 2, '8336273-3', '2011-08-29 00:00:00'),
(122, 'Error 122', 'Obstante presencia tiene llamado doctor servicio. Obras francia ayuda campo estas éste.', '2020-02-04', 'Cerrado', 3, '20372723-3', '2020-02-05 00:00:00'),
(123, 'Error 123', 'Centros ideas campo recuerdo amigos casa. Explicó respuesta ejército aspectos principios hubiera.', '2022-05-14', 'En Progreso', 3, '24549181-K', NULL),
(124, 'Error 124', 'Quería aquellos área españoles en. Primeros estados podía años.', '2019-09-15', 'Abierto', 2, '8646997-4', NULL),
(125, 'Error 125', 'Políticas podía hijos a tuvo.', '2021-08-15', 'Cerrado', 3, '17956909-9', '2021-08-16 00:00:00'),
(126, 'Error 126', 'Españoles países hacia vino llegar época.', '2013-08-19', 'En Progreso', 6, '4112034-6', NULL),
(127, 'Error 127', 'Entrar ambiente momentos ahí. Oposición puso hace.', '2021-08-21', 'Abierto', 5, '6217026-3', NULL),
(128, 'Error 128', 'Temas oficial derechos.', '2014-05-28', 'Cerrado', 3, '24549181-K', '2014-05-29 00:00:00'),
(129, 'Error 129', 'Piel vuelta menos movimiento puntos. Voz jorge sabía asimismo varios que habría.', '2024-01-08', 'Abierto', 9, '12294238-1', NULL),
(130, 'Error 130', 'Gobierno estructura obstante además madrid éste. Resultado él último.', '2024-05-17', 'En Progreso', 3, '1890399-8', NULL),
(131, 'Error 131', 'Silencio comenzó toma dólares rosa. Suficiente región central orden.', '2024-10-10', 'Cerrado', 10, '23487347-4', '2024-10-11 00:00:00'),
(132, 'Error 132', 'Larga pueda mejor ello interior. Humano rosa materia ésta más méxico.', '2010-12-04', 'Abierto', 1, '1839221-4', NULL),
(133, 'Error 133', 'Violencia modo espacio dentro.', '2024-05-21', 'Cerrado', 4, '11881122-0', '2024-05-22 00:00:00'),
(134, 'Error 134', 'Ayuda quizá características cinco rafael humana. Mí parecía secretario ser.', '2022-10-31', 'Abierto', 8, '3644095-8', NULL),
(135, 'Error 135', 'Principales un sectores aparece existe siquiera garcía.', '2024-01-25', 'Cerrado', 5, '4389045-6', '2024-01-26 00:00:00'),
(136, 'Error 136', 'Pie también medidas toda libros dice se. Peor principios éxito pudo hace quería.', '2020-10-31', 'Cerrado', 5, '10334531-0', '2020-11-01 00:00:00'),
(137, 'Error 137', 'Siguientes secretario manera. Hubiera pensar sobre estamos universidad.', '2020-03-04', 'Abierto', 3, '23706266-8', NULL),
(138, 'Error 138', 'Tema posible mal alguna alguien parece cinco.', '2019-11-11', 'Cerrado', 8, '3644095-8', '2019-11-12 00:00:00'),
(139, 'Error 139', 'Personal jóvenes domingo encuentro.', '2014-07-30', 'En Progreso', 6, '4245263-5', NULL),
(140, 'Error 140', 'Domingo próximo b ministerio.', '2017-02-28', 'Cerrado', 7, '10057945-K', '2017-03-01 00:00:00'),
(141, 'Error 141', 'Francisco quiero hacia les muerte miedo parece.', '2012-12-07', 'Cerrado', 9, '8369062-K', '2012-12-08 00:00:00'),
(142, 'Error 142', 'Cambio puerta derecha artículo llegado.', '2022-08-07', 'Cerrado', 4, '15157347-0', '2022-08-08 00:00:00'),
(143, 'Error 143', 'Línea aun otro puede méxico duda hermano.', '2020-06-18', 'Cerrado', 8, '1999828-1', '2020-06-19 00:00:00'),
(144, 'Error 144', 'Organización casos mujeres sí estado hubo ministro. Análisis nombre particular actual mí van fuerte.', '2015-07-24', 'Abierto', 1, '17956909-9', NULL),
(145, 'Error 145', 'Mismo posibilidad llevar duda llama palabra.', '2016-07-05', 'Cerrado', 4, '16415740-8', '2016-07-06 00:00:00'),
(146, 'Error 146', 'Cuestión dan serán valor torno podría argentina estas.', '2013-08-01', 'Cerrado', 4, '4112034-6', '2013-08-02 00:00:00'),
(147, 'Error 147', 'Sólo deja rey nuestras.', '2013-07-29', 'Cerrado', 8, '2537611-K', '2013-07-30 00:00:00'),
(148, 'Error 148', 'Cambios un cinco nosotros.', '2016-12-02', 'Abierto', 2, '2537611-K', NULL),
(149, 'Error 149', 'Diario para ellas figura futuro. Educación niveles mil miembros importantes fuera mayoría.', '2018-10-27', 'Cerrado', 4, '8646997-4', '2018-10-28 00:00:00'),
(150, 'Error 150', 'Viejo materia nuevos misma actual común entre. Su pudo últimos intereses cantidad autor ello.', '2014-10-29', 'Cerrado', 1, '6457765-5', '2014-10-30 00:00:00'),
(151, 'Error 151', 'Tiempos noche cada respecto principios familia democracia. Razones bastante mira buena casa quien mesa.', '2011-02-19', 'Cerrado', 10, '6217026-3', '2011-02-20 00:00:00'),
(152, 'Error 152', 'Equipo información sangre puerto pueden.', '2024-09-03', 'Cerrado', 5, '6742460-8', '2024-09-04 00:00:00'),
(153, 'Error 153', 'Quien flores hicieron dijo baja cinco políticas. Nos investigación u obra.', '2022-01-14', 'Abierto', 7, '22455603-1', NULL),
(154, 'Error 154', 'Quién justicia lucha nuevo. Acción así don mayores.', '2013-01-02', 'Cerrado', 7, '6357277-6', '2013-01-03 00:00:00'),
(155, 'Error 155', 'Año suerte la intereses. Lugar banco marco dolor luz ésta conocer.', '2018-03-17', 'Cerrado', 1, '9217207-3', '2018-03-18 00:00:00'),
(156, 'Error 156', 'Ciento vivir europa parecía nuestras.', '2022-10-16', 'En Progreso', 6, '10327246-7', NULL),
(157, 'Error 157', 'Personal cerca necesidad cabeza b premio capaz.', '2022-05-30', 'Abierto', 7, '6217026-3', NULL),
(158, 'Error 158', 'Concepto puerto autoridades campaña espacio banco ahí. Hecho comisión él esos espera militares otros.', '2021-04-23', 'Cerrado', 10, '21754078-5', '2021-04-24 00:00:00'),
(159, 'Error 159', 'Has música menor consecuencia modelo quienes través. Centro dijo sistema pocos líder mercado.', '2025-04-05', 'Abierto', 3, '23487347-4', NULL),
(160, 'Error 160', 'Alrededor baja ir hace ex fondo luego consumo. Juan decía aparece sino fiscal blanca deja ahí.', '2012-03-03', 'Cerrado', 6, '5188470-6', '2012-03-04 00:00:00'),
(161, 'Error 161', 'Aparece alguna m siglo nosotros nuevos sala. Junio ahí claro cuba ayer baja.', '2022-07-06', 'En Progreso', 4, '9875847-0', NULL),
(162, 'Error 162', 'General nuevos viene hizo cámara palabras esas tiene.', '2023-07-07', 'Cerrado', 9, '8646997-4', '2023-07-08 00:00:00'),
(163, 'Error 163', 'Escuela hacía papel propios. Del fue dicen finalmente debe dio.', '2010-11-26', 'Abierto', 3, '9217207-3', NULL),
(164, 'Error 164', 'Durante humana una medios. General mediante teatro diciembre presidente ve fácil.', '2017-06-21', 'Cerrado', 3, '24641507-1', '2017-06-22 00:00:00'),
(165, 'Error 165', 'Llegar san donde mismos opinión éxito rafael. Comenzó forma mal junio paso región libertad.', '2023-08-07', 'En Progreso', 6, '8646997-4', NULL),
(166, 'Error 166', 'G riesgo tema volver cabo los. Rey paso grupo producción podrá dios partir.', '2023-10-02', 'En Progreso', 7, '4112034-6', NULL),
(167, 'Error 167', 'Días supuesto cabo primeros otra algún dólares. Parte si demás américa con fondo.', '2023-10-30', 'Cerrado', 10, '24090883-8', '2023-10-31 00:00:00'),
(168, 'Error 168', 'Resto debido palabra través uno incluso. Haya cuerpo podía nosotros.', '2017-07-18', 'Cerrado', 10, '8646997-4', '2017-07-19 00:00:00'),
(169, 'Error 169', 'Resulta larga zona económica. Equipo incluso origen silencio imágenes por materia.', '2016-09-21', 'Abierto', 6, '24641507-1', NULL),
(170, 'Error 170', 'Capacidad millones antes período particular hacen a reunión. Público asociación industria.', '2017-06-06', 'Abierto', 7, '6742460-8', NULL),
(171, 'Error 171', 'Saber entrar importante fin socialista dio.', '2023-02-03', 'Abierto', 10, '12294238-1', NULL),
(172, 'Error 172', 'Creo te instituto mano buena materia. López luis domingo sigue claro sabía cambios.', '2020-08-23', 'En Progreso', 1, '6357277-6', NULL),
(173, 'Error 173', 'Finalmente entonces público términos paciente podrá.', '2023-02-02', 'En Progreso', 9, '24641507-1', NULL),
(174, 'Error 174', 'Hacía tribunal veces pequeño blanco única.', '2024-02-09', 'Cerrado', 3, '10057945-K', '2024-02-10 00:00:00'),
(175, 'Error 175', 'Muerto mitad acto trata estado. Padre política esfuerzo suficiente.', '2025-04-08', 'Abierto', 10, '10334531-0', NULL),
(176, 'Error 176', 'Sociales figura violencia ella.', '2025-09-17', 'En Progreso', 1, '1999828-1', NULL),
(177, 'Error 177', 'Vista incluso posibilidad todos buena sería.', '2019-11-22', 'Cerrado', 3, '4112034-6', '2019-11-23 00:00:00'),
(178, 'Error 178', 'Ni afirmó norte dos niveles.', '2019-04-06', 'En Progreso', 7, '9214491-2', NULL),
(179, 'Error 179', 'Final puso producción. Estaban sino éste.', '2021-04-03', 'Cerrado', 1, '11881122-0', '2021-04-04 00:00:00'),
(180, 'Error 180', 'Europa mañana tema memoria cuba debía horas existen.', '2025-10-30', 'En Progreso', 9, '8336273-3', NULL),
(181, 'Error 181', 'Medidas española especialmente carácter menos.', '2017-04-16', 'Cerrado', 9, '21439044-K', '2017-04-17 00:00:00'),
(182, 'Error 182', 'Dice realidad boca hora sí cuya. Encuentran amigos destino cultural sabía régimen cosas.', '2018-06-14', 'En Progreso', 8, '4112034-6', NULL),
(183, 'Error 183', 'Lejos obra hoy hombres mira. Constitución afirmó mejor.', '2021-12-16', 'Cerrado', 5, '4245263-5', '2021-12-17 00:00:00'),
(184, 'Error 184', 'Felipe ni aspecto afirmó visto sería.', '2023-09-07', 'En Progreso', 4, '24641507-1', NULL),
(185, 'Error 185', 'Será sector estudios hubo.', '2016-04-04', 'Cerrado', 4, '10327246-7', '2016-04-05 00:00:00'),
(186, 'Error 186', 'Hechos opinión blanca militares material podrá música dos. Será público sectores podría mesa peso.', '2016-09-04', 'Cerrado', 4, '11881122-0', '2016-09-05 00:00:00'),
(187, 'Error 187', 'Derecho vida todo cabo miembros considera informe que. Años hombres pública película tiempo armas futuro.', '2025-06-25', 'Cerrado', 6, '16510878-6', '2025-06-26 00:00:00'),
(188, 'Error 188', 'Muerto nosotros dijo nivel dentro pues régimen.', '2020-10-05', 'Cerrado', 5, '12541238-9', '2020-10-06 00:00:00'),
(189, 'Error 189', 'Suerte edad sin primeras comercio pudo encontrar. Trabajar conocimiento hechos paciente sólo.', '2012-09-25', 'Cerrado', 7, '22330030-5', '2012-09-26 00:00:00'),
(190, 'Error 190', 'Participación problema rosa hora.', '2017-09-28', 'En Progreso', 5, '11881122-0', NULL),
(191, 'Error 191', 'Encontrar sería socialista últimos ex cambio mismo clase.', '2010-12-11', 'Abierto', 6, '6217026-3', NULL),
(192, 'Error 192', 'Sé reunión pacientes ojos. Campo toda dado mí memoria.', '2019-12-03', 'Cerrado', 8, '22744459-1', '2019-12-04 00:00:00'),
(193, 'Error 193', 'Hasta pacientes le mi no ningún presencia.', '2014-10-19', 'Cerrado', 9, '24532561-8', '2014-10-20 00:00:00'),
(194, 'Error 194', 'Pp plazo cabeza quizá. Ministro bastante diferencia bastante lleva cambios cuyo.', '2025-08-13', 'En Progreso', 2, '12416912-4', NULL),
(195, 'Error 195', 'Manuel revolución evitar ha pasar estos resultado.', '2023-10-23', 'En Progreso', 4, '24090883-8', NULL),
(196, 'Error 196', 'Grande así pocos exterior. Al pero tales.', '2011-02-20', 'En Progreso', 4, '21439044-K', NULL),
(197, 'Error 197', 'Cierta informe parecía cultural. Visita papel joven defensa.', '2011-03-07', 'Cerrado', 6, '15157347-0', '2011-03-08 00:00:00'),
(198, 'Error 198', 'Diversas siguientes momento pacientes servicios cuando la. Manera tenemos puedo zona parece principal.', '2020-08-05', 'En Progreso', 1, '15157347-0', NULL),
(199, 'Error 199', 'Llama algo resultado productos visita nadie único.', '2022-05-06', 'Cerrado', 8, '1890399-8', '2022-05-07 00:00:00'),
(200, 'Error 200', 'Yo con son. Río has hacen y espacio empresa antonio diferencia.', '2020-09-16', 'En Progreso', 5, '22744459-1', NULL),
(201, 'Error 201', 'Podía deseo amigo fin mismo. Precisamente sólo lo público animales entrar.', '2017-03-16', 'Abierto', 2, '6217026-3', NULL),
(202, 'Error 202', 'Cámara vez policía diversas ideas jamás para llegado. Obras semanas programas único.', '2024-08-18', 'En Progreso', 9, '22330030-5', NULL),
(203, 'Error 203', 'Mayores administración varios consejo mil negro.', '2010-11-02', 'Cerrado', 3, '7671884-K', '2010-11-03 00:00:00'),
(204, 'Error 204', 'Obras amigos contenido evitar formación santa. Presencia te después camino garcía c madrid encuentra.', '2010-10-25', 'Cerrado', 3, '5188470-6', '2010-10-26 00:00:00'),
(205, 'Error 205', 'Gobierno estas lucha posibilidad.', '2016-06-29', 'Abierto', 5, '9217207-3', NULL),
(206, 'Error 206', 'Voy carácter teoría posición otros. Actitud ocasión oro se.', '2022-09-27', 'Abierto', 6, '12920906-3', NULL),
(207, 'Error 207', 'Situación dice pueden. Imágenes importante fiscal informe sol dólares libros pasado.', '2016-05-20', 'Cerrado', 3, '20372723-3', '2016-05-21 00:00:00'),
(208, 'Error 208', 'Él grandes seguridad a nuestro existencia fuerzas. Actual varios suficiente si aparece revolución.', '2021-04-23', 'Cerrado', 4, '20372723-3', '2021-04-24 00:00:00'),
(209, 'Error 209', 'Sociedad sabe zonas música éxito. Estos atrás he respuesta comunidad dijo aparece.', '2012-07-11', 'En Progreso', 8, '4245263-5', NULL),
(210, 'Error 210', 'Juez otro cine durante ya del garcía.', '2024-07-16', 'En Progreso', 1, '6357277-6', NULL),
(211, 'Error 211', 'Llevar médico resto efectos pueda vez entre.', '2017-07-24', 'En Progreso', 3, '6217026-3', NULL),
(212, 'Error 212', 'Diferentes número tienen paso era.', '2023-09-14', 'Cerrado', 7, '24549181-K', '2023-09-15 00:00:00'),
(213, 'Error 213', 'Argentina fácil estaban antes tenemos historia ellas.', '2021-07-23', 'Abierto', 7, '4112034-6', NULL),
(214, 'Error 214', 'Hora médico fernando volvió ella superior razones.', '2025-01-04', 'En Progreso', 3, '15157347-0', NULL),
(215, 'Error 215', 'Parecía ve otros vamos nada.', '2020-09-16', 'En Progreso', 1, '4112034-6', NULL),
(216, 'Error 216', 'Película cine julio acuerdo. Tipos relaciones estudios santa.', '2015-11-07', 'En Progreso', 8, '16415740-8', NULL),
(217, 'Error 217', 'Final mar ahora uso carlos sé larga educación.', '2015-12-28', 'Cerrado', 10, '4245263-5', '2015-12-29 00:00:00'),
(218, 'Error 218', 'Niño sola embargo ley. Oficial trata si club.', '2022-11-07', 'Cerrado', 6, '22455603-1', '2022-11-08 00:00:00'),
(219, 'Error 219', 'Atrás derecho realidad figura suficiente primero.', '2025-07-16', 'Abierto', 2, '10334531-0', NULL),
(220, 'Error 220', 'Europea creación comunicación nos fútbol haber ellas.', '2020-06-09', 'En Progreso', 7, '12294238-1', NULL),
(221, 'Error 221', 'Natural menor últimos diversos.', '2025-05-22', 'Cerrado', 2, '8646997-4', '2025-05-23 00:00:00'),
(222, 'Error 222', 'R obra diario para.', '2024-04-29', 'Cerrado', 10, '6217026-3', '2024-04-30 00:00:00'),
(223, 'Error 223', 'Alguna bueno idea meses tres siquiera agua principio.', '2014-12-15', 'En Progreso', 8, '16072954-9', NULL),
(224, 'Error 224', 'Podía viaje régimen nuevas guerra. Común m seguro dolor.', '2013-06-08', 'Cerrado', 7, '20372723-3', '2013-06-09 00:00:00'),
(225, 'Error 225', 'Meses aparece mismo buena quienes.', '2025-09-29', 'Cerrado', 9, '10327246-7', '2025-09-30 00:00:00'),
(226, 'Error 226', 'Zona jorge explicó también camino. Tiene este nivel.', '2024-11-23', 'En Progreso', 10, '15076749-3', NULL),
(227, 'Error 227', 'Millones ningún hermano. Se construcción medios democracia bueno decía función.', '2011-11-02', 'Cerrado', 9, '3677374-3', '2011-11-03 00:00:00'),
(228, 'Error 228', 'Es soy cantidad meses resultado.', '2025-10-14', 'Abierto', 10, '9875847-0', NULL),
(229, 'Error 229', 'Pudo modelo muerte d jóvenes centro estudios persona.', '2012-07-08', 'En Progreso', 10, '5682115-1', NULL),
(230, 'Error 230', 'Formación acuerdo casos fuerte mayoría cosas.', '2022-01-14', 'En Progreso', 6, '17956909-9', NULL),
(231, 'Error 231', 'Instituto española luis propuesta esas e sectores permite.', '2021-09-02', 'Abierto', 4, '21754078-5', NULL),
(232, 'Error 232', 'Comisión viaje económico qué junto entrar suficiente. Aquella común primero hace importancia están congreso ésta.', '2023-01-30', 'Abierto', 9, '2537611-K', NULL),
(233, 'Error 233', 'Destino línea armas fuego.', '2019-12-29', 'Cerrado', 3, '5682115-1', '2019-12-30 00:00:00'),
(234, 'Error 234', 'Estar ellos costa fuera propios todos presenta.', '2021-07-06', 'Cerrado', 10, '3644095-8', '2021-07-07 00:00:00'),
(235, 'Error 235', 'Considera ejemplo valores existencia oro. Central español duda iglesia cabeza distintos hijo embargo.', '2011-04-18', 'Cerrado', 5, '10327246-7', '2011-04-19 00:00:00'),
(236, 'Error 236', 'Crisis quien si edad sólo sido libre quiere. Frente lejos médico amigo.', '2010-06-28', 'Cerrado', 1, '5188470-6', '2010-06-29 00:00:00'),
(237, 'Error 237', 'Martín noche mayor cuerpo administración i.', '2014-11-21', 'Abierto', 1, '6457765-5', NULL),
(238, 'Error 238', 'Dice del día. Calle servicios principal dónde amigo.', '2019-07-03', 'Abierto', 9, '12541238-9', NULL),
(239, 'Error 239', 'Hacen muerto mil dar. Tanto idea pueda servicios.', '2011-05-09', 'Cerrado', 1, '23706266-8', '2011-05-10 00:00:00'),
(240, 'Error 240', 'Entre deseo algunos sociales hombres. Jamás ambiente mil entonces productos movimiento parís.', '2016-06-09', 'En Progreso', 3, '3644095-8', NULL),
(241, 'Error 241', 'Campo efecto diferentes mantener consejo particular aquellas. Vía larga ocho da.', '2024-05-22', 'Cerrado', 6, '10057945-K', '2024-05-23 00:00:00'),
(242, 'Error 242', 'Falta industria casi siguientes importantes. Participación especialmente junio si última felipe parís.', '2018-07-31', 'Cerrado', 7, '21754078-5', '2018-08-01 00:00:00'),
(243, 'Error 243', 'Cuya mucho elementos cama asunto metros.', '2011-10-20', 'En Progreso', 6, '6742460-8', NULL),
(244, 'Error 244', 'Mal ocasión saber cara.', '2012-08-29', 'Cerrado', 9, '7671884-K', '2012-08-30 00:00:00'),
(245, 'Error 245', 'Mi fin uno oposición especie. Allí diciembre sueño solo.', '2012-11-09', 'En Progreso', 1, '10057945-K', NULL),
(246, 'Error 246', 'Porque siempre estudios maría poco. Juicio queda santiago paz muchas grandes objeto.', '2010-07-06', 'Cerrado', 9, '12294238-1', '2010-07-07 00:00:00'),
(247, 'Error 247', 'Encuentran llama pacientes sólo universidad has precisamente. De argentina algún tomar.', '2019-07-07', 'Cerrado', 4, '4389045-6', '2019-07-08 00:00:00'),
(248, 'Error 248', 'Conocer tendrá equipo mira análisis varias fernando.', '2015-07-21', 'Cerrado', 3, '20372723-3', '2015-07-22 00:00:00'),
(249, 'Error 249', 'Distintos visita fiscal materia pequeña nuestros pequeño. Hoy duda julio rey materia rodríguez.', '2016-03-08', 'Abierto', 1, '24532561-8', NULL),
(250, 'Error 250', 'Experiencia mujer ambiente europa economía momentos ello. J civil tarde larga.', '2024-10-22', 'Abierto', 4, '3644095-8', NULL),
(251, 'Error 251', 'Compañía vez señaló precio. Estuvo apoyo medida sala especie argentina méxico.', '2014-08-16', 'Abierto', 10, '23706266-8', NULL),
(252, 'Error 252', 'Corte sino afirmó r policía.', '2010-10-03', 'Abierto', 4, '21754078-5', NULL),
(253, 'Error 253', 'Clase niño actitud medio tenido mercado pablo. Estuvo gonzález pasa precio organización.', '2010-12-29', 'Cerrado', 4, '5188470-6', '2010-12-30 00:00:00'),
(254, 'Error 254', 'Palabra alto vía salir. José argentina vivir carne.', '2022-02-08', 'Abierto', 3, '15076749-3', NULL),
(255, 'Error 255', 'Problemas línea cabeza.', '2021-04-20', 'En Progreso', 10, '6217026-3', NULL),
(256, 'Error 256', 'Mantener acciones partir.', '2017-02-25', 'Cerrado', 4, '22330030-5', '2017-02-26 00:00:00'),
(257, 'Error 257', 'Gran niños alguna pensar apoyo hombre.', '2016-10-08', 'En Progreso', 7, '17956909-9', NULL),
(258, 'Error 258', 'Dice volver algún mediante había otros.', '2016-09-27', 'Abierto', 9, '12416912-4', NULL),
(259, 'Error 259', 'Cosa jefe alguna hemos.', '2023-04-09', 'En Progreso', 7, '24090883-8', NULL),
(260, 'Error 260', 'Oficial américa pero quizá diferencia encuentra ante. Peor unión conocer nada cabeza.', '2022-06-20', 'Abierto', 6, '2537611-K', NULL),
(261, 'Error 261', 'S octubre pacientes hacen. Nuestras opinión domingo parte problemas lo.', '2024-06-06', 'Cerrado', 9, '21439044-K', '2024-06-07 00:00:00'),
(262, 'Error 262', 'Jorge nada etc u. Sabe quiero teoría fuentes población meses silencio algún.', '2017-02-24', 'Cerrado', 7, '9214491-2', '2017-02-25 00:00:00'),
(263, 'Error 263', 'Soy quiero distintas ex poder oro dólares.', '2013-05-07', 'Cerrado', 3, '12294238-1', '2013-05-08 00:00:00'),
(264, 'Error 264', 'Humano dónde película que.', '2022-01-24', 'En Progreso', 4, '24641507-1', NULL),
(265, 'Error 265', 'Como duda dice situación julio ocho función. Decía nuestras amor hubiera popular.', '2016-09-29', 'En Progreso', 8, '16510878-6', NULL),
(266, 'Error 266', 'Especial pasó diversas mesa francia.', '2011-04-18', 'Cerrado', 7, '10327246-7', '2011-04-19 00:00:00'),
(267, 'Error 267', 'Distintas ello vuelta uso. Espacio iglesia economía habla cual creación vino otro.', '2022-07-02', 'En Progreso', 7, '3677374-3', NULL),
(268, 'Error 268', 'Tomar población ambos.', '2015-06-13', 'En Progreso', 6, '6357277-6', NULL),
(269, 'Error 269', 'Zona dólares gran dicen. Puso supuesto muestra lejos estaban verdad.', '2024-07-03', 'Cerrado', 6, '3917183-9', '2024-07-04 00:00:00'),
(270, 'Error 270', 'Ocasión expresión popular europea mujeres.', '2012-01-28', 'En Progreso', 1, '4389045-6', NULL),
(271, 'Error 271', 'Elementos algunos don tomar título.', '2016-01-09', 'Abierto', 2, '16415740-8', NULL),
(272, 'Error 272', 'Medida ellas psoe.', '2014-03-22', 'En Progreso', 8, '8369062-K', NULL),
(273, 'Error 273', 'Pesetas mismo medidas tienen dos. Dolor crecimiento mayor presenta.', '2014-09-08', 'Cerrado', 1, '4245263-5', '2014-09-09 00:00:00'),
(274, 'Error 274', 'Hace podría diversos. Juan eso estudio efectos conocer acciones lenguaje.', '2014-10-02', 'Abierto', 8, '24532561-8', NULL),
(275, 'Error 275', 'Mil reforma puntos mar políticas resto podemos. Sociales tres sería siguiente bastante.', '2015-06-11', 'En Progreso', 7, '9214491-2', NULL),
(276, 'Error 276', 'Primer técnica principales siete decir junto.', '2015-05-15', 'Cerrado', 5, '10327246-7', '2015-05-16 00:00:00'),
(277, 'Error 277', 'Somos razones alto les.', '2018-07-16', 'Cerrado', 5, '20372723-3', '2018-07-17 00:00:00'),
(278, 'Error 278', 'P central ese además. Mejor busca sociales mundial acerca voy unidos.', '2015-11-13', 'Cerrado', 8, '9875847-0', '2015-11-14 00:00:00'),
(279, 'Error 279', 'Pensar sigue los cuatro. Pp padre consecuencia antonio consumo fuerzas período.', '2012-03-18', 'Cerrado', 6, '10057945-K', '2012-03-19 00:00:00'),
(280, 'Error 280', 'Presenta tenido alguna todas.', '2014-07-23', 'Cerrado', 7, '9875847-0', '2014-07-24 00:00:00'),
(281, 'Error 281', 'Gracias sangre humano apoyo sabe europa.', '2011-01-10', 'En Progreso', 3, '22330030-5', NULL),
(282, 'Error 282', 'Antes son humana lugar tribunal.', '2010-05-13', 'Cerrado', 5, '6357277-6', '2010-05-14 00:00:00'),
(283, 'Error 283', 'Escuela consumo mirada.', '2013-06-02', 'Cerrado', 4, '24532561-8', '2013-06-03 00:00:00'),
(284, 'Error 284', 'Aquella debía decir elementos. Director muestra europa joven felipe.', '2018-07-09', 'En Progreso', 8, '22330030-5', NULL),
(285, 'Error 285', 'Recuerdo dicho pronto cama cada pasa ningún. Algún le nada diversos hacen tú vio.', '2022-05-08', 'Cerrado', 5, '22744459-1', '2022-05-09 00:00:00'),
(286, 'Error 286', 'Principios personas público mayo aunque arriba lado. Elementos ello conocer jóvenes juan análisis.', '2020-12-16', 'Cerrado', 8, '10057945-K', '2020-12-17 00:00:00'),
(287, 'Error 287', 'Sentido josé cambio datos supuesto agua cambio.', '2013-10-10', 'Cerrado', 3, '10057945-K', '2013-10-11 00:00:00'),
(288, 'Error 288', 'Hoy tierra importancia mundial otra hasta.', '2013-02-20', 'Cerrado', 3, '10057945-K', '2013-02-21 00:00:00'),
(289, 'Error 289', 'Una conocer octubre mira está dicho. Empresas aire temas sin tema cuales.', '2022-02-28', 'Abierto', 9, '22744459-1', NULL),
(290, 'Error 290', 'López algo segunda trata recursos hacerlo papel hablar.', '2010-10-05', 'Abierto', 1, '23706266-8', NULL),
(291, 'Error 291', 'Radio pues tienen fuego. Relaciones psoe presencia punto actividades.', '2019-04-02', 'En Progreso', 2, '8336273-3', NULL),
(292, 'Error 292', 'Posición primero mirada j paciente. Período parte costa miguel.', '2025-11-11', 'Abierto', 4, '17956909-9', NULL),
(293, 'Error 293', 'Amor llegó baja área semanas obras ahí.', '2021-05-05', 'Cerrado', 1, '20372723-3', '2021-05-06 00:00:00'),
(294, 'Error 294', 'Autor puerto encuentra tenían miguel.', '2023-11-10', 'Cerrado', 8, '24549181-K', '2023-11-11 00:00:00'),
(295, 'Error 295', 'Mira gonzález de.', '2010-05-09', 'Cerrado', 1, '22455603-1', '2010-05-10 00:00:00'),
(296, 'Error 296', 'Quienes misma todo última conseguir investigación centro antonio.', '2010-05-18', 'Cerrado', 9, '3677374-3', '2010-05-19 00:00:00'),
(297, 'Error 297', 'Ver posición da efectos.', '2016-06-06', 'Cerrado', 3, '1839221-4', '2016-06-07 00:00:00'),
(298, 'Error 298', 'Estaba ocasión años noche ni puntos. Nombre muy pasar fuentes.', '2012-05-26', 'En Progreso', 4, '15157347-0', NULL),
(299, 'Error 299', 'Vio ellos tiene ayer.', '2014-04-22', 'Cerrado', 6, '23487347-4', '2014-04-23 00:00:00'),
(300, 'Error 300', 'Investigación capital puerto aun lópez personas casos.', '2015-12-30', 'Abierto', 6, '5188470-6', NULL),
(302, 'ayuda por favor demo', 'ayuda de error', '2025-10-08', 'En Progreso', 4, '12345678-9', NULL);

--
-- Disparadores `errorbug`
--
DELIMITER $$
CREATE TRIGGER `trg_bloqueo_delete_error` BEFORE DELETE ON `errorbug` FOR EACH ROW BEGIN
  IF OLD.estado_error = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar un error en progreso.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_bloqueo_update_error` BEFORE UPDATE ON `errorbug` FOR EACH ROW BEGIN
  IF OLD.estado_error = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar un error en progreso.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_limite_diario_error` BEFORE INSERT ON `errorbug` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug 
  WHERE user_rut = NEW.user_rut AND DATE(fecha_error) = CURDATE();
  IF n >= 25 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Has alcanzado el m├íximo de 25 errores por d├¡a.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_no_titulo_duplicado_error` BEFORE INSERT ON `errorbug` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug WHERE titulo_error = NEW.titulo_error;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un error con este t├¡tulo.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_no_titulo_duplicado_error_update` BEFORE UPDATE ON `errorbug` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM ErrorBug WHERE titulo_error = NEW.titulo_error AND id_bug != NEW.id_bug;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un error con este t├¡tulo.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `funcionalidad`
--

CREATE TABLE `funcionalidad` (
  `id_funcionalidad` int(11) NOT NULL,
  `titulo_funcion` varchar(100) NOT NULL,
  `ambiente_funcion` enum('Web','Móvil') DEFAULT NULL,
  `resumen_funcion` varchar(150) NOT NULL,
  `estado_funcion` enum('Abierto','En Progreso','Resuelto','Cerrado') NOT NULL,
  `fecha_funcion` date NOT NULL,
  `id_topico` int(11) NOT NULL,
  `user_rut` varchar(12) NOT NULL,
  `resuelto_en` datetime DEFAULT NULL
) ;

--
-- Volcado de datos para la tabla `funcionalidad`
--

INSERT INTO `funcionalidad` (`id_funcionalidad`, `titulo_funcion`, `ambiente_funcion`, `resumen_funcion`, `estado_funcion`, `fecha_funcion`, `id_topico`, `user_rut`, `resuelto_en`) VALUES
(1, 'Siete esa julio cierto.', 'Móvil', 'Iglesia frente realidad dentro parte entrada aquí doctor podría millones sería poder tenido.', 'Abierto', '2022-12-07', 7, '24532561-8', NULL),
(2, 'Uso consumo consumo también.', 'Web', 'Partido mercado industria enero dio mujer.', 'Cerrado', '2010-01-14', 7, '3677374-3', '2010-01-15 00:00:00'),
(3, 'Todos lenguaje tanto.', 'Móvil', 'Haciendo eran profesional b democracia palabra mi oposición hacen tiempos solo.', 'Cerrado', '2011-07-28', 2, '21439044-K', '2011-07-29 00:00:00'),
(4, 'Habían boca millones persona pudo sola.', 'Móvil', 'Considera paciente tal europa enero capaz uso decir.', 'Cerrado', '2016-09-26', 6, '8646997-4', '2016-09-27 00:00:00'),
(5, 'Jorge programas animales.', 'Móvil', 'N clase santiago siguiente camino alta estos.', 'En Progreso', '2019-01-10', 4, '9214491-2', NULL),
(6, 'Claro materia hecho tienen.', 'Móvil', 'Sería líder lugar población temas tal hora imágenes cuanto.', 'En Progreso', '2019-06-07', 10, '21439044-K', NULL),
(7, 'Mano atención mayo acuerdo realizar trabajo.', 'Móvil', 'Veces quiero mercado ello le santiago nuestras bajo mantener.', 'Abierto', '2022-10-07', 5, '12294238-1', NULL),
(8, 'Pueden condiciones ello volvió quizá mirada.', 'Móvil', 'Niño dólares informe espacio comercio cultural ante encuentra todo comercio más blanco local.', 'Cerrado', '2016-06-08', 8, '15076749-3', '2016-06-09 00:00:00'),
(9, 'Encontrar puerto asimismo.', 'Web', 'Capital elementos palabra juego instituto justicia julio pues voy.', 'Cerrado', '2019-11-29', 3, '21754078-5', '2019-11-30 00:00:00'),
(10, 'Perdido medios mercado concepto seguridad varios.', 'Móvil', 'He haber frente dice blanco asociación manuel señora.', 'Cerrado', '2024-10-11', 2, '3917183-9', '2024-10-12 00:00:00'),
(11, 'Encuentro posible condiciones libertad quedó conocer.', 'Móvil', 'Ciento curso espacio ejemplo mismo son suelo socialista este encontrar.', 'En Progreso', '2015-04-09', 4, '6742460-8', NULL),
(12, 'Siguiente hablar deja nuevos tratamiento ocho.', 'Web', 'Sus banco enero humanos desarrollo siempre media día juez.', 'En Progreso', '2013-04-22', 8, '1839221-4', NULL),
(13, 'Historia dijo marcha j fin.', 'Web', 'Tomar tres imagen valores investigación acciones c plan armas amor económica algunos.', 'Cerrado', '2023-09-17', 7, '11881122-0', '2023-09-18 00:00:00'),
(14, 'Niños plazo cualquier estaba.', 'Web', 'Segunda fue momentos falta pues propuesta todos.', 'Cerrado', '2024-02-16', 8, '22330030-5', '2024-02-17 00:00:00'),
(15, 'Sido espacio negro. empresas', 'Web', 'Personal otra les importante aún siguientes.', 'Abierto', '2018-12-18', 2, '10334531-0', NULL),
(16, 'Nuestra próximo español.', 'Web', 'Aspecto habla cual zona dicho solamente existencia clase.', 'Cerrado', '2019-07-15', 1, '16072954-9', '2019-07-16 00:00:00'),
(17, 'Cuando materia cierta barcelona hija mayores.', 'Web', 'Objetivo cerca minutos cambios única ejército habían juicio electoral constitución sur debía asimismo.', 'Cerrado', '2022-07-03', 3, '10334531-0', '2022-07-04 00:00:00'),
(18, 'Bien allá principios relación.', 'Móvil', 'Economía interés papel actividad joven marcha minutos.', 'Cerrado', '2020-06-03', 10, '21439044-K', '2020-06-04 00:00:00'),
(19, 'Esas un horas ii haber.', 'Móvil', 'España habrá exterior cargo violencia muchos jorge que movimiento baja peor.', 'En Progreso', '2021-04-28', 8, '10837430-K', NULL),
(20, 'Diciembre orden iglesia.', 'Web', 'Mesa barcelona incluso suficiente comercio suelo antonio estaban diario riesgo aquel.', 'Cerrado', '2020-02-04', 9, '6357277-6', '2020-02-05 00:00:00'),
(21, 'Militar ministerio unas distintos último.', 'Web', 'Instituto dijo estados sería noviembre siguiente partes podemos cama menor dónde.', 'Cerrado', '2020-11-13', 8, '24549181-K', '2020-11-14 00:00:00'),
(22, 'Problemas méxico resultado ellas.', 'Móvil', 'Nada valores días prensa amor si siguientes partido análisis seguir compañía tenemos fútbol.', 'En Progreso', '2011-09-27', 5, '16510878-6', NULL),
(23, 'Electoral pasado propio trata tipo españoles.', 'Web', 'Incluso europea medida su hubo experiencia efecto será haya recuerdo.', 'En Progreso', '2017-07-14', 3, '4112034-6', NULL),
(24, 'Principios suelo economía estilo otra.', 'Web', 'Esto gonzález mucha hay tribunal palabras cómo u resultado presencia.', 'En Progreso', '2015-03-10', 2, '16415740-8', NULL),
(25, 'Trabajar obras ese experiencia período particular.', 'Móvil', 'Pasó creo poco deseo lleva falta podrá modo interior gracias mal.', 'Cerrado', '2019-04-22', 7, '3644095-8', '2019-04-23 00:00:00'),
(26, 'Operación etc él europea título.', 'Móvil', 'Cierta corazón línea intereses pregunta opinión toma pone verdad es cuatro ni república.', 'Cerrado', '2011-05-26', 10, '15076749-3', '2011-05-27 00:00:00'),
(27, 'Con producción quería políticos llegó.', 'Móvil', 'Orden construcción desde siguientes problemas cierta cerca podía.', 'Cerrado', '2025-08-07', 1, '1839221-4', '2025-08-08 00:00:00'),
(28, 'Mil necesario primero santiago.', 'Móvil', 'Puede hecho la miguel personas presenta tienen pese llegar cuarto en.', 'Cerrado', '2017-11-21', 9, '12294238-1', '2017-11-22 00:00:00'),
(29, 'Marzo corazón gente cara.', 'Web', 'Encuentran mis hablar sueño salir importantes cargo dirección negro etc ministerio.', 'Cerrado', '2022-04-01', 4, '12920906-3', '2022-04-02 00:00:00'),
(30, 'Suerte español tomar llegado mundo bastante.', 'Móvil', 'Ayuda dólares vivir escuela caso mal común dinero esta j.', 'Abierto', '2016-02-14', 7, '10837430-K', NULL),
(31, 'Cuatro pública distintas propios necesario.', 'Móvil', 'Habla hacer tengo importante pasar va necesidad tras director señor tú recursos nacional.', 'En Progreso', '2017-07-16', 8, '21439044-K', NULL),
(32, 'Tiene julio valores seguir pudo.', 'Web', 'Si político salud habría otra puede gran mediante tema ambiente actitud septiembre hija.', 'Cerrado', '2012-11-11', 10, '23487347-4', '2012-11-12 00:00:00'),
(33, 'Salir sabe programa miembros j.', 'Web', 'Nacional armas mayores argentina américa papel grupos tarde ejemplo nueva intereses.', 'Abierto', '2022-08-29', 7, '21439044-K', NULL),
(34, 'Somos durante quien carácter llevar.', 'Web', 'Torno asociación ejemplo arriba acciones ideas posición dice objetivo palabra.', 'Abierto', '2013-01-16', 5, '20372723-3', NULL),
(35, 'Crisis obstante ex barcelona unas causa.', 'Web', 'Médico cosas pp primeros todavía tendrá paso deja fue juicio.', 'Cerrado', '2018-07-03', 6, '4112034-6', '2018-07-04 00:00:00'),
(36, 'Asimismo deja j suficiente través llama.', 'Móvil', 'Formas especialmente considera socialista control miembros.', 'Cerrado', '2017-07-27', 7, '8369062-K', '2017-07-28 00:00:00'),
(37, 'Solamente modo cuatro podrá.', 'Móvil', 'Cantidad él expresión último todas solución ocasiones verdad gobierno encima estructura.', 'Abierto', '2015-08-29', 9, '3917183-9', NULL),
(38, 'Visita flores amigo ella siguientes.', 'Web', 'Electoral habrá aire última segundo región donde menor arte fuerzas.', 'Abierto', '2011-03-03', 1, '12541238-9', NULL),
(39, 'Carrera palabras necesario.', 'Web', 'Podría año tenían organización nuestras algunas quizá capital.', 'Abierto', '2010-09-12', 10, '10334531-0', NULL),
(40, 'México imposible sabía reunión.', 'Web', 'Datos dolor juicio jefe llegar españoles.', 'Cerrado', '2013-06-02', 2, '10334531-0', '2013-06-03 00:00:00'),
(41, 'Ahí humana que acción.', 'Móvil', 'Asunto más juego valores esto han carne volver plaza.', 'Cerrado', '2022-08-26', 6, '15076749-3', '2022-08-27 00:00:00'),
(42, 'Militares mitad sol además sigue energía.', 'Web', 'Tampoco comunicación cuanto cuestión exterior cuba santiago nuevas.', 'En Progreso', '2013-10-06', 5, '12920906-3', NULL),
(43, 'Estos podrá carta. diario', 'Web', 'Cada estudio generales pasar hora d director.', 'Cerrado', '2012-06-04', 10, '6457765-5', '2012-06-05 00:00:00'),
(44, 'Modelo lado josé. segundo', 'Móvil', 'Sería obra ambiente ya varios consejo actitud ningún mientras.', 'En Progreso', '2025-03-11', 2, '16415740-8', NULL),
(45, 'Suerte material amigos tierra allí.', 'Web', 'Juego estructura nuevos instituciones ejemplo plan deben.', 'Abierto', '2023-04-13', 5, '9214491-2', NULL),
(46, 'Puerto casos crecimiento reforma consumo.', 'Web', 'Educación haya diversos dicho deben campo realizar vivir mayoría cine empresa conocimiento.', 'Abierto', '2025-05-07', 6, '12920906-3', NULL),
(47, 'Tenido bueno ciencia pasar año existe.', 'Móvil', 'Cuerpo período otro cosas cual existe sabe rosa quiero tales éxito habrá.', 'Abierto', '2021-12-13', 9, '10837430-K', NULL),
(48, 'María condiciones va.', 'Web', 'R hija carta nada un tomar siguiente nombre quería de por tomar cuatro.', 'Cerrado', '2024-07-10', 8, '4245263-5', '2024-07-11 00:00:00'),
(49, 'Paso es cámara ciudad estar.', 'Móvil', 'Ellas domingo proyectos pese seis futuro mucha difícil artículo alta silencio trabajo.', 'Cerrado', '2012-05-14', 3, '10837430-K', '2012-05-15 00:00:00'),
(50, 'Tampoco aumento humanos busca.', 'Móvil', 'Países cabeza cuarto estudios práctica habla padre libros alrededor.', 'Cerrado', '2019-10-08', 8, '7671884-K', '2019-10-09 00:00:00'),
(51, 'Están libertad han. interés', 'Móvil', 'Torno música pueden juicio has desarrollo.', 'Cerrado', '2019-10-09', 4, '10057945-K', '2019-10-10 00:00:00'),
(52, 'Torno hacía momentos donde resto.', 'Móvil', 'Niño madre consecuencia primeras argentina médico programas efecto sé más luz centros.', 'En Progreso', '2011-12-11', 8, '12416912-4', NULL),
(53, 'Punto meses cuando pudo humanos especialmente.', 'Móvil', 'Mira antonio información derecho país gobierno.', 'Cerrado', '2022-10-13', 1, '23487347-4', '2022-10-14 00:00:00'),
(54, 'Allá puede aumento estuvo josé.', 'Web', 'Ciudad atención república d intereses porque mucho debía modelo operación suelo.', 'Cerrado', '2021-02-01', 4, '4112034-6', '2021-02-02 00:00:00'),
(55, 'Obra mundo espera local si.', 'Móvil', 'Cuenta por algún ninguna acto diferencia.', 'Cerrado', '2017-12-16', 10, '6357277-6', '2017-12-17 00:00:00'),
(56, 'Lucha explicó has libros u.', 'Web', 'Puntos g lucha les nada mundo negro nuevo.', 'En Progreso', '2025-09-23', 2, '12416912-4', NULL),
(57, 'Varias animales ambiente.', 'Móvil', 'Aire equipo sociedad verdad segundo ésta dar año plazo.', 'Cerrado', '2015-06-01', 9, '10057945-K', '2015-06-02 00:00:00'),
(58, 'Mundo ésta siendo premio momento.', 'Móvil', 'Nadie tipos nos corte nueva electoral militares.', 'Cerrado', '2015-05-23', 8, '9214491-2', '2015-05-24 00:00:00'),
(59, 'Punto acción teatro dijo segunda hubo.', 'Móvil', 'Paso mundo grande largo a al esa río objetivo sistema.', 'En Progreso', '2010-05-22', 7, '3917183-9', NULL),
(60, 'Cual aquí proceso tengo.', 'Móvil', 'Cuatro mucho tal medio cierto señora cara seis pie.', 'Cerrado', '2025-07-08', 8, '10334531-0', '2025-07-09 00:00:00'),
(61, 'Artículo empresa hechos carlos.', 'Móvil', 'O cada españoles fuerte permite parís miguel lucha tomar dentro unas.', 'Cerrado', '2022-06-01', 9, '3677374-3', '2022-06-02 00:00:00'),
(62, 'Corte chile defensa manos.', 'Móvil', 'Metros joven causa nuestros costa días debido tratamiento hijo ello.', 'Cerrado', '2017-06-02', 5, '12541238-9', '2017-06-03 00:00:00'),
(63, 'Dicen igual siguientes instituciones.', 'Web', 'Donde casa posible unidos tenían actual social.', 'En Progreso', '2015-08-22', 6, '16072954-9', NULL),
(64, 'Niveles vuelve dijo necesario parecía riesgo dólares.', 'Web', 'Adelante única calle arte información favor en.', 'En Progreso', '2012-09-06', 4, '24090883-8', NULL),
(65, 'Segunda joven diciembre cualquier forma.', 'Móvil', 'Guerra cada derechos decisión tribunal sueño.', 'Abierto', '2020-11-10', 4, '12416912-4', NULL),
(66, 'Tienen j muestra dio tan cabeza.', 'Móvil', 'Consumo interior salud u capacidad principios modelo es partido luis haya.', 'En Progreso', '2016-08-23', 5, '16072954-9', NULL),
(67, 'Actual futuro central lucha poder.', 'Web', 'Hace consecuencia tienen idea largo guerra valor ejército no expresión nuestras.', 'Cerrado', '2010-04-26', 1, '16510878-6', '2010-04-27 00:00:00'),
(68, 'Productos posible sector.', 'Móvil', 'Importante obra casos meses última diversas.', 'En Progreso', '2011-03-23', 8, '10327246-7', NULL),
(69, 'Verdad nuevas instituciones zonas agua josé.', 'Móvil', 'Niño camino bueno idea todas calle.', 'Cerrado', '2012-04-20', 8, '22455603-1', '2012-04-21 00:00:00'),
(70, 'Otras y hacer capacidad estamos.', 'Web', 'Larga hoy luego aquellos autoridades izquierda profesional largo ve administración un capacidad.', 'Abierto', '2019-11-18', 5, '4245263-5', NULL),
(71, 'Dar película aquel años cara yo.', 'Web', 'Gracias plan padre debido reforma anterior datos programa corte ya plaza lejos una.', 'Cerrado', '2020-09-18', 8, '1999828-1', '2020-09-19 00:00:00'),
(72, 'Salir haciendo donde.', 'Web', 'Paso ciento problemas campaña tendrá mí claro música movimiento ver objetivo seis fuera.', 'En Progreso', '2011-08-30', 3, '22330030-5', NULL),
(73, 'Ambiente sus ve palabras.', 'Web', 'Términos ve pocos hacia sigue ser.', 'En Progreso', '2022-08-16', 2, '12294238-1', NULL),
(74, 'Dentro pueden oficial ayer.', 'Móvil', 'Otras apenas pensar ciudad estudios ambos tiene boca.', 'En Progreso', '2022-07-08', 9, '8369062-K', NULL),
(75, 'Ambos debe sigue. resto', 'Móvil', 'Única enero oro vuelve enero principios.', 'Cerrado', '2018-07-14', 10, '21754078-5', '2018-07-15 00:00:00'),
(76, 'B mitad fácil humana estructura conseguir.', 'Web', 'Varias quienes arte niños durante del viejo.', 'Abierto', '2019-08-14', 4, '12294238-1', NULL),
(77, 'Debe pp cine producto.', 'Móvil', 'Lo torno obra poder era trabajo enfermedad ex nuevo militar distintas blanca ambiente.', 'Abierto', '2024-01-12', 3, '15076749-3', NULL),
(78, 'Cabo sino mal mis. socialista', 'Web', 'Militares desarrollo animales dan efectos mismos parece esas mitad como temas interés mejor campo.', 'En Progreso', '2015-05-19', 1, '7671884-K', NULL),
(79, 'Día dólares ii días uso.', 'Móvil', 'Cuadro casi sueño sistemas paciente allá.', 'Cerrado', '2019-03-01', 1, '21754078-5', '2019-03-02 00:00:00'),
(80, 'Podía civil deben también nueva madre.', 'Móvil', 'C todas j existe rafael tienen.', 'Cerrado', '2015-03-12', 2, '6217026-3', '2015-03-13 00:00:00'),
(81, 'Nadie atención fin militares.', 'Móvil', 'Bastante muchas porque sistema presente nuestros fútbol.', 'En Progreso', '2025-06-02', 7, '16072954-9', NULL),
(82, 'Visto empresa muchas.', 'Web', 'Pasa comenzó se cara madre toma u.', 'En Progreso', '2012-07-29', 5, '4389045-6', NULL),
(83, 'Lenguaje hermano riesgo volver frente.', 'Web', 'Club sé pequeño verdad cine primeras fernando marco vista niños creación otro tratamiento son.', 'En Progreso', '2013-03-11', 5, '23706266-8', NULL),
(84, 'Ejército cuya partir plazo pero torno.', 'Móvil', 'Estado estamos estas me perdido con ayuda grado quienes bien sí niño exterior.', 'Cerrado', '2023-05-07', 2, '24090883-8', '2023-05-08 00:00:00'),
(85, 'Diez común diario ejemplo miembros.', 'Móvil', 'Defensa lleva concepto donde diversas premio prueba media.', 'Cerrado', '2020-07-06', 5, '9214491-2', '2020-07-07 00:00:00'),
(86, 'Espacio diciembre usted respecto.', 'Móvil', 'Interior razones esa ser misma sector lenguaje.', 'Cerrado', '2021-03-23', 2, '4389045-6', '2021-03-24 00:00:00'),
(87, 'Asunto josé desde tomar próximo más.', 'Móvil', 'Conocimiento aquellas apenas demasiado razones tarde dan estudios ejército razón.', 'Cerrado', '2023-06-01', 10, '9217207-3', '2023-06-02 00:00:00'),
(88, 'Trabajo programa meses son.', 'Web', 'Instituto naturaleza solución dio hija habría siguiente nacional queda efectos b actividades persona.', 'En Progreso', '2015-08-14', 10, '1839221-4', NULL),
(89, 'Elecciones san todavía.', 'Móvil', 'Violencia pie incluso tipos tras cualquier madre.', 'Abierto', '2023-03-03', 3, '1839221-4', NULL),
(90, 'Dicen sea pueden. cerca', 'Móvil', 'También sólo p crecimiento cuatro objeto norte.', 'Cerrado', '2020-07-21', 3, '3677374-3', '2020-07-22 00:00:00'),
(91, 'Movimiento vuelve país actividad.', 'Móvil', 'Río arriba están sabía aspecto puedo son deseo ve modo hora.', 'Abierto', '2023-02-17', 8, '10837430-K', NULL),
(92, 'Libros dos derechos sistemas.', 'Móvil', 'Opinión blanco número personas sociales estructura josé sea.', 'Cerrado', '2017-10-21', 2, '3644095-8', '2017-10-22 00:00:00'),
(93, 'B curso parecía humanos.', 'Móvil', 'Europa hecho además pablo sin puntos.', 'Cerrado', '2013-08-10', 5, '4245263-5', '2013-08-11 00:00:00'),
(94, 'Militares mí ella principios.', 'Web', 'Humano buenos teatro diferencia hacen ello larga.', 'Cerrado', '2024-11-10', 2, '5188470-6', '2024-11-11 00:00:00'),
(95, 'Piel ley puerto solo encuentro.', 'Móvil', 'Juicio derechos queda igual pronto elecciones estos.', 'Abierto', '2017-01-20', 7, '6357277-6', NULL),
(96, 'Comisión bajo norte méxico madrid.', 'Móvil', 'Temas dicho obra soy luis lugar.', 'Cerrado', '2021-07-17', 1, '22455603-1', '2021-07-18 00:00:00'),
(97, 'Dejó ayuda contrario.', 'Móvil', 'Economía alguien dentro lucha luego en esas carlos particular tuvo armas ley.', 'Cerrado', '2014-03-17', 8, '3677374-3', '2014-03-18 00:00:00'),
(98, 'N pequeño hechos económica sociedad.', 'Móvil', 'José mismo partir asociación primero reforma tipo sistemas.', 'En Progreso', '2011-02-27', 5, '15076749-3', NULL),
(99, 'Misma tengo empresa pese barcelona deben.', 'Móvil', 'Objetivo policía ocasiones países últimos clase quizá lópez tanto contra camino decisión último.', 'Abierto', '2019-10-30', 1, '9214491-2', NULL),
(100, 'Mientras doctor horas trabajo.', 'Web', 'Fuerzas señora usted único pasa cuba sociedad económica.', 'En Progreso', '2024-02-18', 5, '12920906-3', NULL),
(101, 'Siguiente producto madre generales estar título.', 'Móvil', 'Sin período hacen cine ocho concepto oro allí si estado tengo.', 'Abierto', '2022-05-10', 4, '22455603-1', NULL),
(102, 'Palabra médico socialista ya conocer película imposible.', 'Web', 'Anterior actividad destino vivir posición doctor.', 'En Progreso', '2012-07-18', 8, '20372723-3', NULL),
(103, 'Ii aun importancia valores cabeza origen.', 'Móvil', 'Consejo peor chile bastante sea siete lópez especial días general instituciones acuerdo.', 'Cerrado', '2016-07-18', 8, '8646997-4', '2016-07-19 00:00:00'),
(104, 'Práctica don todos algunos.', 'Móvil', 'Próximo mujer opinión entrar solo arte nombre domingo.', 'En Progreso', '2020-08-04', 7, '10334531-0', NULL),
(105, 'Sabía idea puerta humanos.', 'Web', 'Lugar luego manera nunca nuestra santiago ciento estados organización cinco.', 'Abierto', '2014-04-11', 5, '12920906-3', NULL),
(106, 'Pronto momento sea. eso', 'Móvil', 'Rosa suelo mismo izquierda pronto análisis mí nada meses hora sean.', 'Abierto', '2019-04-23', 5, '4245263-5', NULL),
(107, 'Rosa punto algunos común relaciones quiero.', 'Móvil', 'Allá produce verdad hace bajo tienen afirmó.', 'En Progreso', '2016-09-11', 8, '6457765-5', NULL),
(108, 'Ninguna otros encuentran llegó acuerdo santa.', 'Móvil', 'Recuerdo resultados juego puerta semanas victoria.', 'Cerrado', '2022-01-30', 9, '24641507-1', '2022-01-31 00:00:00'),
(109, 'Intereses quería estados muestra tiempo.', 'Móvil', 'Democracia vía américa final medios mil además médico mirada.', 'Cerrado', '2022-03-10', 4, '16415740-8', '2022-03-11 00:00:00'),
(110, 'Propios pone madrid.', 'Móvil', 'Sido cambios parece movimiento mayor presenta.', 'En Progreso', '2025-08-23', 7, '10334531-0', NULL),
(111, 'Título allá precio diario.', 'Móvil', 'G período producto enfermedad película donde ocasión el última trata conjunto.', 'Cerrado', '2010-12-24', 7, '4112034-6', '2010-12-25 00:00:00'),
(112, 'Boca parece mundo cara.', 'Web', 'Algún nuevas estudio sangre muestra radio si nuestro.', 'Cerrado', '2024-11-19', 1, '22744459-1', '2024-11-20 00:00:00'),
(113, 'Actividades pueden conciencia llama reunión.', 'Móvil', 'Argentina cuya sala mismos produce pasó pasar general comercio tan pública conjunto banco.', 'Abierto', '2012-10-31', 8, '8646997-4', NULL),
(114, 'Humanos podemos resulta superior s demás.', 'Móvil', 'E haciendo llevar sería ningún fin g muestra modelo tomar población paso.', 'Abierto', '2012-03-27', 3, '3677374-3', NULL),
(115, 'Ciento sí mal debía cantidad español.', 'Web', 'Premio aire qué alta dejó quería todavía señor.', 'Abierto', '2019-03-13', 8, '22744459-1', NULL),
(116, 'Solución estudio salida educación.', 'Móvil', 'Frente diario don algún orden del existen sistemas primeros parís decir san largo económico.', 'Abierto', '2015-12-12', 6, '4245263-5', NULL),
(117, 'Nos político domingo.', 'Móvil', 'Diciembre ahora asimismo movimiento energía cierta banco casos económico chile.', 'Cerrado', '2025-02-15', 8, '4389045-6', '2025-02-16 00:00:00'),
(118, 'Hora mal victoria hospital estoy.', 'Web', 'Primeros resultados b norte compañía casi ahora poner comercio natural.', 'En Progreso', '2022-02-19', 5, '9217207-3', NULL),
(119, 'Mayoría menos sociales.', 'Web', 'Servicios pero tipo aumento principal actual tenido nuestros siguiente.', 'Cerrado', '2015-02-07', 2, '24090883-8', '2015-02-08 00:00:00'),
(120, 'Figura pasó han superior asimismo podría.', 'Web', 'Muerte mal población mal solución caso cambio sol animales tiempos pesetas.', 'Cerrado', '2024-03-19', 3, '16510878-6', '2024-03-20 00:00:00'),
(121, 'Llegado fueron mucho existen.', 'Web', 'Estamos lugar económica juan parte baja pone entrada ellas toda.', 'Abierto', '2025-07-26', 6, '12294238-1', NULL),
(122, 'Local primeras cultura ahora precios.', 'Móvil', 'Productos diversos victoria soy otro quedó económica aspectos buena modelo llama mismos cultura.', 'Cerrado', '2011-04-05', 7, '6217026-3', '2011-04-06 00:00:00'),
(123, 'Pueda programas economía banco domingo.', 'Móvil', 'Teoría dónde posición español noche cuenta calle creo río.', 'En Progreso', '2013-04-07', 3, '10334531-0', NULL),
(124, 'Puso muchos jefe ahí.', 'Móvil', 'Historia paso embargo partes resulta bastante llevar josé única radio policía minutos.', 'En Progreso', '2013-12-05', 8, '3917183-9', NULL),
(125, 'Pasa américa ahí fuerte.', 'Web', 'Suelo trabajadores dirección ciento sus estuvo cierto viejo me punto civil.', 'Cerrado', '2023-01-30', 5, '17956909-9', '2023-01-31 00:00:00'),
(126, 'Interior fondo atención acto hasta hijos.', 'Web', 'Constitución obras problema figura ocho mundo dan.', 'Cerrado', '2020-04-22', 5, '6357277-6', '2020-04-23 00:00:00'),
(127, 'Texto habla voz. razones', 'Web', 'Unidad cine mismo ante casa último vuelta información varios escuela boca.', 'Abierto', '2025-03-13', 8, '4389045-6', NULL),
(128, 'Pequeña proyecto ojos adelante me.', 'Móvil', 'Todas viaje mujer nuestro baja obra.', 'Cerrado', '2017-10-01', 5, '6457765-5', '2017-10-02 00:00:00'),
(129, 'Zonas ya su hijo me.', 'Web', 'Base cinco partir miembros considera resto reforma sabe programas además hubiera riesgo cualquier.', 'Cerrado', '2020-03-31', 8, '12294238-1', '2020-04-01 00:00:00'),
(130, 'Eran posición especial máximo mediante.', 'Móvil', 'Pudo afirmó mayor iglesia decía diversos efecto.', 'Cerrado', '2012-05-23', 10, '10334531-0', '2012-05-24 00:00:00'),
(131, 'Hechos hacerlo varios estaba.', 'Móvil', 'Dan sector hijos fecha nosotros largo larga económica palabra.', 'Abierto', '2016-08-20', 7, '9214491-2', NULL),
(132, 'Ambos volvió propuesta nuevo organización.', 'Web', 'Donde parece pasó derecha buenos quizá etc gran una cuerpo derechos creación programa.', 'Cerrado', '2016-02-27', 5, '22455603-1', '2016-02-28 00:00:00'),
(133, 'Organización porque don profesional desarrollo.', 'Móvil', 'Tendrá llega casa buscar dios nuevos hacía vez cuenta sur puedo embargo.', 'En Progreso', '2015-03-01', 4, '12920906-3', NULL),
(134, 'Problemas gracias gracias demasiado sentido salida.', 'Web', 'Lenguaje allí dio queda llegado lejos aquí.', 'Abierto', '2023-12-05', 1, '6357277-6', NULL),
(135, 'Total final explicó al.', 'Web', 'Instituto si hechos hicieron tema instituciones.', 'Cerrado', '2016-12-05', 3, '21754078-5', '2016-12-06 00:00:00'),
(136, 'Uso sala diez dan domingo.', 'Móvil', 'Comunicación ministro tras casa presenta suelo r dan natural.', 'Cerrado', '2012-01-09', 3, '6217026-3', '2012-01-10 00:00:00'),
(137, 'Él pudo valor. mucho', 'Móvil', 'Momento fondo porque contra ante solución popular ideas.', 'Cerrado', '2014-07-03', 3, '8336273-3', '2014-07-04 00:00:00'),
(138, 'Noche encuentro ve industria.', 'Móvil', 'Encuentran mediante cuerpo autor autoridades material casi año hermano resulta memoria.', 'Cerrado', '2015-10-07', 2, '24641507-1', '2015-10-08 00:00:00'),
(139, 'Desarrollo jefe señora reunión casos.', 'Web', 'Objetivo ante calidad padres profesional cuba.', 'En Progreso', '2020-07-03', 7, '23706266-8', NULL),
(140, 'Tipo nuevas acción diversos reforma arte.', 'Web', 'Trabajo tendrá papel líder señora tú número actividades económico a ley público.', 'Cerrado', '2022-07-02', 1, '9875847-0', '2022-07-03 00:00:00'),
(141, 'Suficiente antonio estado mientras uso momentos.', 'Web', 'Conjunto sea dios quería haber queda segunda haber anterior muestra intereses.', 'Cerrado', '2015-12-07', 6, '4389045-6', '2015-12-08 00:00:00'),
(142, 'Sentido mucha medio.', 'Móvil', 'Sobre pese ciento papel a capacidad miembros jefe miedo larga.', 'Cerrado', '2025-02-02', 6, '24090883-8', '2025-02-03 00:00:00'),
(143, 'Familia fácil podría.', 'Web', 'Llamado líder ambos buscar barcelona resto.', 'Cerrado', '2012-06-06', 1, '6742460-8', '2012-06-07 00:00:00'),
(144, 'Especialmente agua mesa premio.', 'Móvil', 'Modo mejores quien economía lópez va hijos posibilidades serán seis verdad autoridades otras.', 'En Progreso', '2023-11-24', 2, '10327246-7', NULL),
(145, 'Seguridad toda adelante.', 'Móvil', 'Nuevas b aspecto civil tanto fuerza lenguaje llegado don.', 'Cerrado', '2024-04-02', 2, '20372723-3', '2024-04-03 00:00:00'),
(146, 'Acciones llegar aparece entrada.', 'Web', 'U práctica tres c hombre trabajar señaló deja propia plan alrededor.', 'Cerrado', '2013-02-19', 8, '9217207-3', '2013-02-20 00:00:00'),
(147, 'Hechos solo objeto imagen propio.', 'Web', 'Marco sólo horas muy alguna exterior elecciones unas república.', 'En Progreso', '2012-08-09', 7, '15157347-0', NULL),
(148, 'Encima peso cabeza. participación', 'Móvil', 'Relaciones tiempo banco tiempos interés ejército ese dios fueron hay quiere.', 'En Progreso', '2020-03-05', 7, '9875847-0', NULL),
(149, 'Fue técnica para después calidad espera.', 'Móvil', 'Dos trabajo esta norte cierta tan justicia sus importantes.', 'Cerrado', '2024-09-09', 5, '15157347-0', '2024-09-10 00:00:00'),
(150, 'Solo ya iglesia. octubre', 'Móvil', 'Oposición poder revolución hijo garcía cuya francia.', 'En Progreso', '2010-09-26', 8, '9214491-2', NULL),
(151, 'Seguridad esa superior también local.', 'Móvil', 'Economía además cualquier ejército destino joven solamente hay evitar sean.', 'Abierto', '2019-12-22', 6, '10334531-0', NULL),
(152, 'Dado trabajar habría hoy.', 'Móvil', 'Suerte seguro ni banco fuentes autor.', 'Abierto', '2022-03-19', 7, '22744459-1', NULL),
(153, 'Verdad nombre cantidad cuestión.', 'Web', 'Cuatro mayoría según posición trata través va victoria posible él mujer tarde.', 'Cerrado', '2016-03-10', 2, '24532561-8', '2016-03-11 00:00:00'),
(154, 'Estados horas nueva.', 'Web', 'Radio total humana familia español fue seguir lo solo río parecía jefe función.', 'Abierto', '2024-11-12', 6, '15076749-3', NULL),
(155, 'Voy media cuyo temas psoe.', 'Web', 'Blanco como siguiente siguientes calle análisis materia servicio fácil.', 'Abierto', '2015-06-19', 9, '8336273-3', NULL),
(156, 'Nosotros fueron internacional ambiente hacía.', 'Web', 'Sólo sistema tengo siquiera principal pronto.', 'En Progreso', '2014-08-25', 6, '6457765-5', NULL),
(157, 'Familia oficial como momentos vio.', 'Web', 'Tanto aire se hermano oposición sala expresión una junto espera allá.', 'Cerrado', '2013-04-23', 3, '12920906-3', '2013-04-24 00:00:00'),
(158, 'Visita contrario fuerte otros aparece.', 'Móvil', 'Grupos orden llega perdido club mitad políticos gran ellos derecho.', 'En Progreso', '2012-11-30', 2, '4389045-6', NULL),
(159, 'Gracias nombre mayo.', 'Web', 'Sé población consejo años importantes elementos situación enero.', 'Abierto', '2024-10-29', 6, '1839221-4', NULL),
(160, 'Existen nuevos formas.', 'Móvil', 'Razones pp cuya seguir quiere hermano miguel origen tú voluntad enfermedad muy especie bastante.', 'Abierto', '2015-05-04', 3, '6457765-5', NULL),
(161, 'Formación hicieron europa sé hermano.', 'Web', 'Ir situación desarrollo lugar desde éxito acciones cierta tanto blanco afirmó efectos.', 'Cerrado', '2015-12-14', 9, '5682115-1', '2015-12-15 00:00:00'),
(162, 'Cuenta nuestra hijo información conocer.', 'Web', 'Cargo meses objetivo operación dirección propios vio esos rodríguez común puerto.', 'Cerrado', '2012-07-20', 8, '24090883-8', '2012-07-21 00:00:00'),
(163, 'Perdido obstante sentido santiago chile saber.', 'Web', 'Sentido y e sistemas viaje unión habrá de medio comercio nombre.', 'Cerrado', '2018-02-13', 9, '8646997-4', '2018-02-14 00:00:00'),
(164, 'Comercio trabajadores importantes acerca comunicación proyecto.', 'Web', 'No siglo esta unas congreso color pudo he relaciones aspectos.', 'Cerrado', '2014-12-20', 8, '23487347-4', '2014-12-21 00:00:00'),
(165, 'Nada nacional vamos finalmente casos.', 'Web', 'Día número aún capacidad valor tales mercado apenas lado.', 'Cerrado', '2024-06-06', 7, '1839221-4', '2024-06-07 00:00:00'),
(166, 'Países idea relación aun.', 'Web', 'Rodríguez encuentro fuera educación después decisión voy.', 'Cerrado', '2019-07-25', 8, '6742460-8', '2019-07-26 00:00:00'),
(167, 'Haber sino interés guerra tierra empresas.', 'Móvil', 'Ojos acerca debía estudio antes hombres después ya.', 'En Progreso', '2011-08-26', 2, '3917183-9', NULL),
(168, 'Haya luis pese contra llegó.', 'Móvil', 'Tipos esta tiene elecciones grande diversos sentido.', 'Cerrado', '2012-10-30', 10, '12416912-4', '2012-10-31 00:00:00'),
(169, 'Esos segundo primer empresa aspecto.', 'Móvil', 'Diversos aun llamado teoría según voz pues prueba prensa proyectos sector principal aumento.', 'Cerrado', '2021-11-25', 2, '6217026-3', '2021-11-26 00:00:00'),
(170, 'Problemas final quién.', 'Web', 'Mediante ir asociación podía riesgo entre chile oficial santa joven presencia natural.', 'Cerrado', '2025-09-27', 8, '1999828-1', '2025-09-28 00:00:00'),
(171, 'Hermano más pública san.', 'Móvil', 'Común da precios difícil m humanos manera muchas haya sin historia.', 'Cerrado', '2015-02-15', 7, '3644095-8', '2015-02-16 00:00:00'),
(172, 'Hombre ambiente tenido nuevos mal contrario.', 'Web', 'Esa trabajar llega alrededor fuera podía manuel u.', 'Cerrado', '2019-05-01', 7, '10057945-K', '2019-05-02 00:00:00'),
(173, 'Pesar salir estaba mi sobre g.', 'Móvil', 'Oro gran un algún enfermedad cinco armas.', 'Cerrado', '2017-01-04', 3, '21439044-K', '2017-01-05 00:00:00'),
(174, 'Mirada juego bueno máximo.', 'Web', 'Imágenes recuerdo sola políticos tras dicen pequeña solución pensar.', 'Abierto', '2025-05-28', 2, '24641507-1', NULL),
(175, 'Hicieron fuentes lleva solamente pronto.', 'Web', 'Industria siglo este así estudio la habría generales él fiscal por.', 'Cerrado', '2012-02-03', 3, '10837430-K', '2012-02-04 00:00:00'),
(176, 'Precio capaz igual ciento ir amigos.', 'Móvil', 'Gracias cabeza del ocasiones nosotros fuerte poco juez.', 'Abierto', '2022-06-24', 7, '5682115-1', NULL),
(177, 'Diciembre sistemas podía hospital niños.', 'Móvil', 'Desde tienen tan exterior ver así.', 'Abierto', '2017-12-06', 5, '21439044-K', NULL),
(178, 'Sería sur ocasiones punto ninguna.', 'Móvil', 'Decir escuela reforma durante empresa sociales política habla distintos centro autoridades felipe.', 'Abierto', '2023-06-20', 10, '12294238-1', NULL),
(179, 'Misma investigación región y.', 'Web', 'Cabo pasar semana importancia asunto camino artículo sentido.', 'Cerrado', '2021-05-19', 4, '15076749-3', '2021-05-20 00:00:00'),
(180, 'Iba mientras fondo encima europea obras.', 'Móvil', 'I julio le fecha pie ningún.', 'Abierto', '2012-06-05', 5, '12541238-9', NULL),
(181, 'Profesional sala jorge muestra.', 'Móvil', 'Después meses tiempo ir mercado relación comercio nuevas anterior serán dentro.', 'Abierto', '2022-11-17', 10, '16072954-9', NULL),
(182, 'Finalmente encima prueba.', 'Móvil', 'López nuestro dolor hay ir relación grupo manuel posibilidades concepto meses teoría.', 'Abierto', '2024-10-02', 3, '9214491-2', NULL),
(183, 'Distintos mercado anterior resto por reunión.', 'Móvil', 'Corte cierto aquel española tiempo dio mitad iglesia d cierto carne derecha cultural.', 'Cerrado', '2016-02-17', 6, '9214491-2', '2016-02-18 00:00:00'),
(184, 'Poder ser fecha cabeza este familia.', 'Web', 'Soy líder efectos tierra etc sigue oposición países.', 'Cerrado', '2010-02-20', 2, '7671884-K', '2010-02-21 00:00:00'),
(185, 'Otras central defensa partidos.', 'Web', 'Público sigue miguel pesetas tiempos razones.', 'Abierto', '2013-03-08', 9, '24090883-8', NULL),
(186, 'Ocasión mejor hizo. seguridad', 'Móvil', 'Somos alguien hermano título parte d nuevos sino.', 'Cerrado', '2014-10-29', 6, '16415740-8', '2014-10-30 00:00:00'),
(187, 'Dice u tierra parecía rey supuesto largo.', 'Móvil', 'Una muchos parecía política fuera estaban puesto instituciones pone hacia.', 'Cerrado', '2013-07-13', 10, '9875847-0', '2013-07-14 00:00:00'),
(188, 'Nosotros cine ese ocasión.', 'Web', 'Puso marcha ministerio méxico mesa hoy aspecto torno sistemas al torno lleva.', 'En Progreso', '2023-05-17', 3, '3917183-9', NULL),
(189, 'Último varias viejo contenido población hacia.', 'Web', 'Considera acuerdo chile hacerlo educación tenemos demasiado obstante izquierda.', 'Cerrado', '2023-11-10', 8, '5682115-1', '2023-11-11 00:00:00'),
(190, 'Misma sólo dicho. más', 'Móvil', 'Tras sea médico aquellas acción p llama podía cuarto que función suelo.', 'Cerrado', '2024-11-05', 7, '10837430-K', '2024-11-06 00:00:00'),
(191, 'Tiene seguir popular trabajo valores persona.', 'Web', 'Real noche resulta etc humanos ello toma piel esfuerzo ex.', 'Cerrado', '2016-02-16', 7, '15076749-3', '2016-02-17 00:00:00'),
(192, 'Oro minutos puntos posición.', 'Móvil', 'Doctor e visto formas términos pocos prueba victoria ante aún ojos esfuerzo.', 'Cerrado', '2012-06-27', 1, '6217026-3', '2012-06-28 00:00:00'),
(193, 'Camino sistemas local problema domingo.', 'Web', 'Pequeña pensar boca la acuerdo abril espera.', 'Abierto', '2014-12-12', 4, '5188470-6', NULL),
(194, 'Eran ésta trata. términos', 'Web', 'Españoles éste julio centros minutos puerto.', 'Cerrado', '2016-10-05', 5, '15076749-3', '2016-10-06 00:00:00'),
(195, 'Poner forma conciencia social distintas.', 'Web', 'Mis sueño programa militar más ni sector papel pregunta han.', 'Cerrado', '2017-05-11', 7, '1999828-1', '2017-05-12 00:00:00'),
(196, 'Bien amigos nivel. son', 'Móvil', 'Suficiente p no calle ocasiones dos sabe condiciones grandes ha compañía entrada.', 'En Progreso', '2013-12-10', 9, '8336273-3', NULL),
(197, 'Cine función calidad puntos estoy nombre.', 'Móvil', 'Médico intereses sea resulta pasa hacía ex habría agua sí bastante sur características.', 'Abierto', '2022-07-14', 7, '21439044-K', NULL),
(198, 'Aquella varias don mayor jóvenes bueno.', 'Web', 'Cinco allí atrás interés datos industria cantidad hecho aquella a i especie.', 'Cerrado', '2010-12-13', 2, '10837430-K', '2010-12-14 00:00:00'),
(199, 'Cuya santiago militar.', 'Móvil', 'Europa aquel tampoco trabajo tema felipe difícil.', 'Cerrado', '2017-01-08', 7, '22330030-5', '2017-01-09 00:00:00'),
(200, 'Investigación mi aún.', 'Móvil', 'Podía presencia entrada tratamiento enfermedad figura toda afirmó dejar fuerzas seis bajo.', 'Abierto', '2016-06-29', 6, '1999828-1', NULL),
(213, 'funcionalidad demo prueba', 'Web', 'ayudaaaaa', 'Abierto', '2025-10-06', 2, '12345678-9', NULL),
(215, 'ayuda por favor demo', 'Web', 'ayudaaa lo suplico', 'Abierto', '2025-10-08', 2, '12345678-9', NULL);

--
-- Disparadores `funcionalidad`
--
DELIMITER $$
CREATE TRIGGER `trg_bloqueo_delete_func` BEFORE DELETE ON `funcionalidad` FOR EACH ROW BEGIN
  IF OLD.estado_funcion = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar una funcionalidad en progreso.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_bloqueo_update_func` BEFORE UPDATE ON `funcionalidad` FOR EACH ROW BEGIN
  IF OLD.estado_funcion = 'En Progreso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar una funcionalidad en progreso.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_limite_diario_func` BEFORE INSERT ON `funcionalidad` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad 
  WHERE user_rut = NEW.user_rut AND DATE(fecha_creacion) = CURDATE();
  IF n >= 25 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Has alcanzado el m├íximo de 25 funcionalidades por d├¡a.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_no_titulo_duplicado_func` BEFORE INSERT ON `funcionalidad` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad WHERE titulo_funcion = NEW.titulo_funcion;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una funcionalidad con este t├¡tulo.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_no_titulo_duplicado_func_update` BEFORE UPDATE ON `funcionalidad` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Funcionalidad WHERE titulo_funcion = NEW.titulo_funcion AND id_funcionalidad != NEW.id_funcionalidad;
  IF n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una funcionalidad con este t├¡tulo.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ingeniero`
--

CREATE TABLE `ingeniero` (
  `ing_rut` varchar(12) NOT NULL,
  `nombre_ing` varchar(100) NOT NULL,
  `email_ing` varchar(100) NOT NULL
) ;

--
-- Volcado de datos para la tabla `ingeniero`
--

INSERT INTO `ingeniero` (`ing_rut`, `nombre_ing`, `email_ing`) VALUES
('1019189-9', 'Amarilis Cifuentes Puerta', 'maldonadoana-sofia@example.org'),
('10344146-K', 'Florinda Melero Vigil', 'llorentechus@example.com'),
('11014145-K', 'Pascuala Nicolau', 'spizarro@example.org'),
('11558837-3', 'Andrés Granados Coronado', 'mcisneros@example.com'),
('11584847-6', 'Nicanor Damián Hurtado Santana', 'susanitamate@example.net'),
('11876872-7', 'Íngrid Badía Melero', 'amandaberenguer@example.net'),
('12087340-1', 'Santos López-Prats', 'uvalcarcel@example.com'),
('12345678-0', 'Sofia Avalos', 'sofiaavalos@gmail.com'),
('1241284-1', 'Édgar de Terrón', 'gutierrezvictor@example.org'),
('13146585-3', 'José Antonio Arco Pelayo', 'wpellicer@example.org'),
('13179613-4', 'Asdrubal de Mata', 'bropero@example.com'),
('13546466-2', 'Donato Bravo Guijarro', 'isidoraamigo@example.org'),
('13805018-9', 'Heraclio del Mur', 'hbriones@example.net'),
('1385239-K', 'Remigio Calisto Oliver Molins', 'chicoheliodoro@example.net'),
('14275203-K', 'José Luis Hugo Polo Alcalde', 'ferrerramiro@example.net'),
('14387959-K', 'Lucila Corona Chaparro Sanabria', 'mmarquez@example.com'),
('15165337-9', 'Donato Mulet Calderón', 'baldomerozabaleta@example.com'),
('15198153-3', 'Cosme del Peral', 'garciajuan-antonio@example.com'),
('15212940-6', 'Flor Carla Cuenca Gallego', 'uarranz@example.com'),
('15463677-5', 'Feliciana del Amaya', 'carlitocarranza@example.org'),
('15588301-2', 'Roberto Rozas', 'hgalan@example.net'),
('15700199-8', 'María Ángeles Barco Céspedes', 'teresa07@example.com'),
('16149361-1', 'Mercedes Pont', 'brigidaroyo@example.com'),
('16224441-0', 'Régulo de Portero', 'danielahernandez@example.com'),
('16396513-2', 'Ascensión Almansa Barón', 'manzanoisaac@example.net'),
('1653531-1', 'Inés Cortina Arribas', 'bernardo52@example.org'),
('16705148-8', 'Adelina Cózar Aragón', 'manceboamor@example.net'),
('16860207-3', 'Eladio Antúnez Márquez', 'belencuevas@example.com'),
('16870338-6', 'Paco Manuel Casal Franco', 'victorino81@example.org'),
('16947830-8', 'Encarnita Pagès', 'gtormo@example.org'),
('1705792-9', 'Amada Leal Feliu', 'lledoanacleto@example.org'),
('17287807-3', 'Porfirio Talavera Mena', 'sanchezanabel@example.com'),
('17307133-1', 'José Luis del Robledo', 'cristianlillo@example.com'),
('17559643-1', 'Chuy Jara Jurado', 'luna61@example.com'),
('18034339-9', 'Cesar Camilo Sainz Aguilera', 'nadia72@example.com'),
('18252216-3', 'Margarita de Castilla', 'yusteleandra@example.com'),
('18705794-9', 'Gil del Barbero', 'ajaen@example.com'),
('18874652-2', 'Maristela Gutierrez Cueto', 'checamanu@example.org'),
('19017734-4', 'María Dolores Hierro Naranjo', 'tono18@example.com'),
('19085076-4', 'Ceferino Campillo Ródenas', 'arseniososa@example.net'),
('19093688-2', 'Felicia Poza-Perea', 'itziar02@example.com'),
('19095773-3', 'Celestino Machado Calderón', 'diegorodenas@example.org'),
('19098556-8', 'Salvador de Valenciano', 'catalina87@example.net'),
('19586522-3', 'Luís Torrijos Arana', 'zcamino@example.com'),
('20161026-9', 'Adela Salas Agullo', 'qtome@example.org'),
('20580115-6', 'Carmelita Solís Cañas', 'ucadenas@example.org'),
('20615450-6', 'Cándido Sebastián Bosch Valls', 'telmo21@example.org'),
('20744773-3', 'Consuelo de Perelló', 'ferreraraimundo@example.org'),
('22507109-5', 'Plácido Plaza-Mateo', 'jvalderrama@example.net'),
('22806289-5', 'Alcides Almagro', 'fbarral@example.org'),
('22992872-7', 'Angelino Oller Cardona', 'felix45@example.com'),
('24751200-K', 'Hilario Saavedra Cervantes', 'apoloniaquiroga@example.com'),
('24922597-4', 'Nadia Montaña-Ros', 'consuelobravo@example.net'),
('2580963-1', 'Marco León Fabra', 'uvalverde@example.com'),
('2975475-3', 'Luisina Alcántara Arnaiz', 'doritamorata@example.org'),
('3131636-6', 'Cintia Meléndez Mariño', 'lorenza73@example.com'),
('3148352-5', 'Rosenda Cuesta', 'paloma00@example.org'),
('3261579-0', 'Lorenzo Toño Villa Galindo', 'qbarragan@example.com'),
('3642648-1', 'Valentín Estrada Soriano', 'eutropio31@example.org'),
('4252458-K', 'Amancio Ramis', 'ycamara@example.com'),
('4570554-K', 'Elías Juan Pujol Planas', 'concepcion99@example.net'),
('4743069-4', 'Eutimio de Calatayud', 'sainzreyes@example.net'),
('4843718-K', 'Rosalía Pozo Saura', 'baenamarcelo@example.org'),
('5308102-K', 'Adelia Abad Grande', 'xpol@example.net'),
('5641643-8', 'Guadalupe Morcillo', 'titomillan@example.com'),
('6128503-K', 'Américo Anglada-Alvarado', 'federicoarenas@example.org'),
('6368105-K', 'Edgardo Jordá Sales', 'azconahortensia@example.net'),
('6540741-4', 'Zaira de Fernández', 'boschnayara@example.com'),
('6994562-8', 'Griselda Cánovas Esparza', 'amandoparra@example.net'),
('7389096-1', 'Aitor Álvaro Torrents', 'claudia33@example.org'),
('7674349-2', 'Humberto Valera Sanmiguel', 'riberaadora@example.net'),
('8079409-9', 'Nico de Ávila', 'asensiocurro@example.com'),
('8685577-0', 'Luisa Odalys Campillo Bayo', 'pascuala97@example.com'),
('9034686-0', 'Paulino Rosa-Mínguez', 'lolasantiago@example.org'),
('9082309-9', 'Obdulia Granados Fonseca', 'rita72@example.org'),
('9275445-8', 'Priscila Pozo Galán', 'kferran@example.com'),
('9318332-3', 'Emma Almazán Olmedo', 'valeriogil@example.com'),
('9436057-8', 'Vinicio Mínguez Pineda', 'dvega@example.com'),
('9837869-8', 'Evangelina Jiménez Rosa', 'wbustos@example.net'),
('9887903-2', 'Teófila del Badía', 'eortega@example.net'),
('9983893-1', 'Benita del Bou', 'klosada@example.org');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ingeniero_especialidad`
--

CREATE TABLE `ingeniero_especialidad` (
  `id_topico` int(11) NOT NULL,
  `ing_rut` varchar(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `ingeniero_especialidad`
--

INSERT INTO `ingeniero_especialidad` (`id_topico`, `ing_rut`) VALUES
(1, '15700199-8'),
(1, '16705148-8'),
(1, '16860207-3'),
(1, '17307133-1'),
(1, '18705794-9'),
(1, '22806289-5'),
(1, '2975475-3'),
(1, '3131636-6'),
(1, '5308102-K'),
(1, '5641643-8'),
(1, '6368105-K'),
(1, '8685577-0'),
(2, '11014145-K'),
(2, '12345678-0'),
(2, '13179613-4'),
(2, '14275203-K'),
(2, '15198153-3'),
(2, '16396513-2'),
(2, '1653531-1'),
(2, '16860207-3'),
(2, '19017734-4'),
(2, '24751200-K'),
(2, '6994562-8'),
(2, '7389096-1'),
(2, '8685577-0'),
(2, '9275445-8'),
(2, '9983893-1'),
(3, '11558837-3'),
(3, '13146585-3'),
(3, '1653531-1'),
(3, '16870338-6'),
(3, '16947830-8'),
(3, '1705792-9'),
(3, '19085076-4'),
(3, '19098556-8'),
(3, '20744773-3'),
(3, '24751200-K'),
(3, '3148352-5'),
(3, '7674349-2'),
(3, '9436057-8'),
(3, '9837869-8'),
(4, '10344146-K'),
(4, '12345678-0'),
(4, '1241284-1'),
(4, '13546466-2'),
(4, '14275203-K'),
(4, '15588301-2'),
(4, '16149361-1'),
(4, '16224441-0'),
(4, '18252216-3'),
(4, '19017734-4'),
(4, '3261579-0'),
(4, '3642648-1'),
(4, '4843718-K'),
(4, '6128503-K'),
(4, '6368105-K'),
(4, '8079409-9'),
(4, '9082309-9'),
(4, '9983893-1'),
(5, '1019189-9'),
(5, '12087340-1'),
(5, '15588301-2'),
(5, '16224441-0'),
(5, '16870338-6'),
(5, '16947830-8'),
(5, '17287807-3'),
(5, '17307133-1'),
(5, '17559643-1'),
(5, '19093688-2'),
(5, '19098556-8'),
(5, '22992872-7'),
(5, '3642648-1'),
(5, '9034686-0'),
(5, '9837869-8'),
(6, '12087340-1'),
(6, '15165337-9'),
(6, '15700199-8'),
(6, '17287807-3'),
(6, '24922597-4'),
(6, '4252458-K'),
(6, '6994562-8'),
(6, '7674349-2'),
(6, '9318332-3'),
(7, '11558837-3'),
(7, '11584847-6'),
(7, '1241284-1'),
(7, '14387959-K'),
(7, '15212940-6'),
(7, '18874652-2'),
(7, '19586522-3'),
(7, '20161026-9'),
(7, '20580115-6'),
(7, '4743069-4'),
(7, '5641643-8'),
(8, '17559643-1'),
(8, '20615450-6'),
(8, '2580963-1'),
(8, '2975475-3'),
(8, '4570554-K'),
(8, '6540741-4'),
(9, '1019189-9'),
(9, '11876872-7'),
(9, '13805018-9'),
(9, '15463677-5'),
(9, '16396513-2'),
(9, '18034339-9'),
(9, '18705794-9'),
(9, '19095773-3'),
(9, '20161026-9'),
(9, '2580963-1'),
(9, '9887903-2'),
(10, '13179613-4'),
(10, '13805018-9'),
(10, '1385239-K'),
(10, '15463677-5'),
(10, '16149361-1'),
(10, '20615450-6'),
(10, '22507109-5'),
(10, '3148352-5'),
(10, '4252458-K'),
(10, '5308102-K'),
(10, '9082309-9');

--
-- Disparadores `ingeniero_especialidad`
--
DELIMITER $$
CREATE TRIGGER `trg_max_2_especialidades` BEFORE INSERT ON `ingeniero_especialidad` FOR EACH ROW BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM Ingeniero_Especialidad WHERE ing_rut = NEW.ing_rut;
  IF n >= 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un ingeniero no puede tener m├ís de 2 especialidades.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `resena_error`
--

CREATE TABLE `resena_error` (
  `id_resena` int(11) NOT NULL,
  `id_bug` int(11) NOT NULL,
  `ing_rut` varchar(12) NOT NULL,
  `comentario` text NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `resena_error`
--

INSERT INTO `resena_error` (`id_resena`, `id_bug`, `ing_rut`, `comentario`, `created_at`, `updated_at`) VALUES
(1, 302, '12345678-0', 'reseña demo', '2025-10-08 15:29:00', '2025-10-08 15:29:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `resena_funcionalidad`
--

CREATE TABLE `resena_funcionalidad` (
  `id_resena` int(11) NOT NULL,
  `id_funcionalidad` int(11) NOT NULL,
  `ing_rut` varchar(12) NOT NULL,
  `comentario` text NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `resena_funcionalidad`
--

INSERT INTO `resena_funcionalidad` (`id_resena`, `id_funcionalidad`, `ing_rut`, `comentario`, `created_at`, `updated_at`) VALUES
(1, 213, '12345678-0', 'observaciones demo', '2025-10-06 02:53:42', '2025-10-06 02:53:42');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `topico`
--

CREATE TABLE `topico` (
  `id_topico` int(11) NOT NULL,
  `nombre_topico` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `topico`
--

INSERT INTO `topico` (`id_topico`, `nombre_topico`) VALUES
(1, 'Backend'),
(7, 'Cloud'),
(8, 'Data Science'),
(4, 'DevOps'),
(10, 'Infraestructura'),
(5, 'Machine Learning'),
(9, 'Mobile'),
(2, 'Seguridad'),
(6, 'Testing'),
(3, 'UX/UI');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `user_rut` varchar(12) NOT NULL,
  `user_nombre` varchar(100) NOT NULL,
  `user_email` varchar(100) NOT NULL
) ;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`user_rut`, `user_nombre`, `user_email`) VALUES
('10057945-K', 'Clemente Durán Gascón', 'angeles97@example.org'),
('10327246-7', 'Plácido Colomer-Lamas', 'aangulo@example.com'),
('10334531-0', 'Teodora Fuente Teruel', 'etelvina24@example.org'),
('10837430-K', 'Emelina de Echeverría', 'tomasatur@example.net'),
('11881122-0', 'Dimas Estrada-Campoy', 'domingoirene@example.org'),
('12294238-1', 'Ruperto Borja Pardo Borrell', 'alcaldejuanito@example.net'),
('12345678-9', 'Sofi', 'sofiaavalos@gmail.com'),
('12416912-4', 'Amelia Duran Palacio', 'felix19@example.net'),
('12541238-9', 'Teófilo Espinosa Valenzuela', 'nazariotorrecilla@example.net'),
('12920906-3', 'Remigio Agustí', 'ybarbero@example.com'),
('15076749-3', 'Marta Aragonés Montaña', 'celestino05@example.org'),
('15157347-0', 'Raimundo Bonifacio Rios Milla', 'eulaliatormo@example.net'),
('16072954-9', 'Mario Molins', 'leonciomata@example.com'),
('16415740-8', 'Etelvina Estévez Ferrera', 'antunezcalixta@example.com'),
('16510878-6', 'Severiano Moliner', 'jacinta33@example.org'),
('17956909-9', 'Anastasia Chus Ferrández Puig', 'zoraidarobledo@example.org'),
('1839221-4', 'Úrsula Etelvina Pellicer Amaya', 'nilda43@example.org'),
('1890399-8', 'Ana Pozo', 'manola69@example.com'),
('1999828-1', 'Nilo Palacio Ugarte', 'dgomis@example.com'),
('20372723-3', 'Lourdes Piñeiro-Jover', 'pavila@example.net'),
('21439044-K', 'Sandra Frutos', 'mmorales@example.net'),
('21754078-5', 'Anna Antúnez Zabaleta', 'aliciaramirez@example.com'),
('22330030-5', 'Cirino Balduino Teruel Galindo', 'rdonoso@example.net'),
('22455603-1', 'Nieves de Tello', 'ana-sofia64@example.com'),
('22744459-1', 'Ángela Castejón Zorrilla', 'calvoangelita@example.net'),
('23487347-4', 'Etelvina Folch Perera', 'claudioabril@example.org'),
('23706266-8', 'Andrés Roda', 'jaureguifulgencio@example.net'),
('24090883-8', 'Chema Alarcón', 'hcodina@example.com'),
('24532561-8', 'Griselda Salmerón Sanz', 'salfonso@example.org'),
('24549181-K', 'Dorotea Ariza Sánchez', 'juanita27@example.com'),
('24641507-1', 'Marcia Cándida Vargas Buendía', 'kaliaga@example.org'),
('2537611-K', 'Modesta Galan-Gisbert', 'maria-manuelamate@example.net'),
('3644095-8', 'Adolfo Amor Lucena García', 'feliciajodar@example.org'),
('3677374-3', 'Nicolasa Pedraza Mayol', 'celestinolago@example.org'),
('3917183-9', 'Inés Miró Roman', 'lorena48@example.net'),
('4112034-6', 'Adolfo Elías Pujol Carretero', 'josorio@example.net'),
('4245263-5', 'Lisandro Tapia Linares', 'evaristozabaleta@example.net'),
('4389045-6', 'Julio César Moreno-Juárez', 'carmenescudero@example.org'),
('5188470-6', 'Desiderio Nico Murillo Rozas', 'jose-carlos61@example.net'),
('5682115-1', 'Jesusa Belmonte Cantero', 'encarnacion09@example.net'),
('6217026-3', 'Miriam Codina Moliner', 'leandro42@example.org'),
('6357277-6', 'Kike del Canales', 'petronaabad@example.net'),
('6457765-5', 'Azucena Mayol Perez', 'ygomez@example.org'),
('6742460-8', 'Jessica Mas Lasa', 'patricio15@example.com'),
('7671884-K', 'José Manuel María Leiva Suarez', 'gelabertconsuela@example.com'),
('8336273-3', 'Agustín Abellán-Hervia', 'sebastian43@example.com'),
('8369062-K', 'Soraya Tello Peral', 'fortunatozaragoza@example.org'),
('8646997-4', 'Carina Perez Landa', 'marcio80@example.com'),
('9214491-2', 'Jonatan Cerdá Crespo', 'kroldan@example.com'),
('9217207-3', 'Lázaro Mayol Anglada', 'danielpujadas@example.org'),
('9875847-0', 'Jerónimo Córdoba', 'dgabaldon@example.net');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `v_asignado_a_ingeniero`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `v_asignado_a_ingeniero` (
`tipo` varchar(13)
,`ing_rut` varchar(12)
,`id_solicitud` int(11)
,`titulo` varchar(100)
,`topico` varchar(100)
,`estado` varchar(11)
,`fecha` date
,`resumen_funcion` varchar(200)
,`ambiente_funcion` enum('Web','Móvil')
,`solicitante` varchar(100)
,`solicitante_rut` varchar(12)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `v_asignado_a_ingeniero`
--
DROP TABLE IF EXISTS `v_asignado_a_ingeniero`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_asignado_a_ingeniero`  AS SELECT 'funcionalidad' AS `tipo`, `af`.`ing_rut` AS `ing_rut`, `f`.`id_funcionalidad` AS `id_solicitud`, `f`.`titulo_funcion` AS `titulo`, `t`.`nombre_topico` AS `topico`, `f`.`estado_funcion` AS `estado`, `f`.`fecha_funcion` AS `fecha`, `f`.`resumen_funcion` AS `resumen_funcion`, `f`.`ambiente_funcion` AS `ambiente_funcion`, `u`.`user_nombre` AS `solicitante`, `u`.`user_rut` AS `solicitante_rut` FROM (((`asignacion_funcionalidad` `af` join `funcionalidad` `f` on(`f`.`id_funcionalidad` = `af`.`id_funcionalidad`)) join `topico` `t` on(`t`.`id_topico` = `f`.`id_topico`)) join `usuario` `u` on(`u`.`user_rut` = `f`.`user_rut`))union all select 'error' AS `error`,`ae`.`ing_rut` AS `ing_rut`,`e`.`id_bug` AS `id_bug`,`e`.`titulo_error` AS `titulo_error`,`t`.`nombre_topico` AS `nombre_topico`,`e`.`estado_error` AS `estado_error`,`e`.`fecha_error` AS `fecha_error`,`e`.`descripcion_error` AS `resumen_funcion`,NULL AS `ambiente_funcion`,`u`.`user_nombre` AS `user_nombre`,`u`.`user_rut` AS `user_rut` from (((`asignacion_error` `ae` join `errorbug` `e` on(`e`.`id_bug` = `ae`.`id_bug`)) join `topico` `t` on(`t`.`id_topico` = `e`.`id_topico`)) join `usuario` `u` on(`u`.`user_rut` = `e`.`user_rut`))  ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `asignacion_error`
--
ALTER TABLE `asignacion_error`
  ADD PRIMARY KEY (`id_bug`,`ing_rut`),
  ADD KEY `fk_ae_ing` (`ing_rut`);

--
-- Indices de la tabla `asignacion_funcionalidad`
--
ALTER TABLE `asignacion_funcionalidad`
  ADD PRIMARY KEY (`id_funcionalidad`,`ing_rut`),
  ADD KEY `fk_af_ing` (`ing_rut`);

--
-- Indices de la tabla `auth_user`
--
ALTER TABLE `auth_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rut` (`rut`);

--
-- Indices de la tabla `criterio_aceptacion`
--
ALTER TABLE `criterio_aceptacion`
  ADD PRIMARY KEY (`id_criterio`),
  ADD KEY `fk_crit_func` (`id_funcionalidad`);

--
-- Indices de la tabla `errorbug`
--
ALTER TABLE `errorbug`
  ADD PRIMARY KEY (`id_bug`),
  ADD UNIQUE KEY `uq_titulo_error` (`titulo_error`),
  ADD KEY `fk_bug_topico` (`id_topico`),
  ADD KEY `fk_bug_usuario` (`user_rut`);

--
-- Indices de la tabla `funcionalidad`
--
ALTER TABLE `funcionalidad`
  ADD PRIMARY KEY (`id_funcionalidad`),
  ADD UNIQUE KEY `uq_titulo_func` (`titulo_funcion`),
  ADD KEY `fk_func_topico` (`id_topico`),
  ADD KEY `fk_func_usuario` (`user_rut`);

--
-- Indices de la tabla `ingeniero`
--
ALTER TABLE `ingeniero`
  ADD PRIMARY KEY (`ing_rut`);

--
-- Indices de la tabla `ingeniero_especialidad`
--
ALTER TABLE `ingeniero_especialidad`
  ADD PRIMARY KEY (`id_topico`,`ing_rut`),
  ADD KEY `fk_ie_ingeniero` (`ing_rut`);

--
-- Indices de la tabla `resena_error`
--
ALTER TABLE `resena_error`
  ADD PRIMARY KEY (`id_resena`),
  ADD KEY `fk_resena_error` (`id_bug`),
  ADD KEY `fk_resena_error_ing` (`ing_rut`);

--
-- Indices de la tabla `resena_funcionalidad`
--
ALTER TABLE `resena_funcionalidad`
  ADD PRIMARY KEY (`id_resena`),
  ADD KEY `fk_resena_func` (`id_funcionalidad`),
  ADD KEY `fk_resena_ing` (`ing_rut`);

--
-- Indices de la tabla `topico`
--
ALTER TABLE `topico`
  ADD PRIMARY KEY (`id_topico`),
  ADD UNIQUE KEY `uq_topico_nombre` (`nombre_topico`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`user_rut`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auth_user`
--
ALTER TABLE `auth_user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `criterio_aceptacion`
--
ALTER TABLE `criterio_aceptacion`
  MODIFY `id_criterio` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=624;

--
-- AUTO_INCREMENT de la tabla `errorbug`
--
ALTER TABLE `errorbug`
  MODIFY `id_bug` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=303;

--
-- AUTO_INCREMENT de la tabla `funcionalidad`
--
ALTER TABLE `funcionalidad`
  MODIFY `id_funcionalidad` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `resena_error`
--
ALTER TABLE `resena_error`
  MODIFY `id_resena` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `resena_funcionalidad`
--
ALTER TABLE `resena_funcionalidad`
  MODIFY `id_resena` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `topico`
--
ALTER TABLE `topico`
  MODIFY `id_topico` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `asignacion_error`
--
ALTER TABLE `asignacion_error`
  ADD CONSTRAINT `fk_ae_bug` FOREIGN KEY (`id_bug`) REFERENCES `errorbug` (`id_bug`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ae_ing` FOREIGN KEY (`ing_rut`) REFERENCES `ingeniero` (`ing_rut`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `asignacion_funcionalidad`
--
ALTER TABLE `asignacion_funcionalidad`
  ADD CONSTRAINT `fk_af_func` FOREIGN KEY (`id_funcionalidad`) REFERENCES `funcionalidad` (`id_funcionalidad`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_af_ing` FOREIGN KEY (`ing_rut`) REFERENCES `ingeniero` (`ing_rut`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `criterio_aceptacion`
--
ALTER TABLE `criterio_aceptacion`
  ADD CONSTRAINT `fk_crit_func` FOREIGN KEY (`id_funcionalidad`) REFERENCES `funcionalidad` (`id_funcionalidad`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `errorbug`
--
ALTER TABLE `errorbug`
  ADD CONSTRAINT `fk_bug_topico` FOREIGN KEY (`id_topico`) REFERENCES `topico` (`id_topico`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bug_usuario` FOREIGN KEY (`user_rut`) REFERENCES `usuario` (`user_rut`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `funcionalidad`
--
ALTER TABLE `funcionalidad`
  ADD CONSTRAINT `fk_func_topico` FOREIGN KEY (`id_topico`) REFERENCES `topico` (`id_topico`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_func_usuario` FOREIGN KEY (`user_rut`) REFERENCES `usuario` (`user_rut`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `ingeniero_especialidad`
--
ALTER TABLE `ingeniero_especialidad`
  ADD CONSTRAINT `fk_ie_ingeniero` FOREIGN KEY (`ing_rut`) REFERENCES `ingeniero` (`ing_rut`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ie_topico` FOREIGN KEY (`id_topico`) REFERENCES `topico` (`id_topico`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `resena_error`
--
ALTER TABLE `resena_error`
  ADD CONSTRAINT `fk_resena_error` FOREIGN KEY (`id_bug`) REFERENCES `errorbug` (`id_bug`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_resena_error_ing` FOREIGN KEY (`ing_rut`) REFERENCES `ingeniero` (`ing_rut`) ON DELETE CASCADE;

--
-- Filtros para la tabla `resena_funcionalidad`
--
ALTER TABLE `resena_funcionalidad`
  ADD CONSTRAINT `fk_resena_func` FOREIGN KEY (`id_funcionalidad`) REFERENCES `funcionalidad` (`id_funcionalidad`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_resena_ing` FOREIGN KEY (`ing_rut`) REFERENCES `ingeniero` (`ing_rut`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
