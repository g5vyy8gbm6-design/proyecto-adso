-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 25-11-2026 a las 18:28:00
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
-- Base de datos: `fresh_style`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_password` (IN `p_nombre_usuario` VARCHAR(50), IN `p_password_actual` VARCHAR(100), IN `p_password_nueva` VARCHAR(100), OUT `p_resultado` VARCHAR(100))   BEGIN
    DECLARE v_salt CHAR(32);
    DECLARE v_salt_nuevo CHAR(32);

    SELECT salt INTO v_salt
    FROM usuarios
    WHERE nombre_usuario = p_nombre_usuario;

    IF NOT EXISTS (SELECT 1 FROM usuarios
        WHERE nombre_usuario = p_nombre_usuario
        AND password = SHA2(CONCAT(v_salt, p_password_actual), 256)) THEN
        SET p_resultado = 'la contraseña actual no es correcta';
    ELSEIF CHAR_LENGTH(p_password_nueva) < 8
        OR CAST(p_password_nueva AS BINARY) = CAST(LOWER(p_password_nueva) AS BINARY)
        OR p_password_nueva NOT REGEXP '[0-9]' THEN
        SET p_resultado = 'la nueva contraseña no cumple con la politica';
    ELSE
        SET v_salt_nuevo = LEFT(SHA2(CONCAT(UUID(), RAND(), NOW(6)), 256), 32);
        UPDATE usuarios
        SET salt = v_salt_nuevo,
            password = SHA2(CONCAT(v_salt_nuevo, p_password_nueva), 256)
        WHERE nombre_usuario = p_nombre_usuario;
        SET p_resultado = 'contraseña actualizada';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_desbloquear_usuario` (IN `p_nombre_usuario` VARCHAR(50))   BEGIN
    UPDATE usuarios
    SET bloqueado = FALSE,
        intentos_fallidos = 0
    WHERE nombre_usuario = p_nombre_usuario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login` (IN `p_nombre_usuario` VARCHAR(50), IN `p_password` VARCHAR(100), OUT `p_resultado` VARCHAR(100))   BEGIN
    DECLARE v_id INT DEFAULT NULL;
    DECLARE v_hash CHAR(64);
    DECLARE v_salt CHAR(32);
    DECLARE v_bloqueado BOOLEAN;
    DECLARE v_intentos INT;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_id = NULL;

    SELECT id_usuario, password, salt, bloqueado, intentos_fallidos
    INTO v_id, v_hash, v_salt, v_bloqueado, v_intentos
    FROM usuarios
    WHERE nombre_usuario = p_nombre_usuario AND activo = TRUE;

    IF v_id IS NULL THEN

        SET p_resultado = 'usuario o contraseña incorrectos';

    ELSEIF v_bloqueado = TRUE THEN

        SET p_resultado = 'Usuario bloqueado. Contacte al administrador';

    ELSEIF v_hash = SHA2(CONCAT(v_salt, p_password), 256) THEN

        UPDATE usuarios
        SET intentos_fallidos = 0,
        ultimo_acceso = NOW()
        WHERE id_usuario = v_id;

        SET p_resultado = 'Acceso concedido';

    ELSE

        UPDATE usuarios
        SET intentos_fallidos = v_intentos + 1,
        bloqueado = (v_intentos + 1 >= 3)
        WHERE id_usuario = v_id;
        SET p_resultado = 'usuario o contraseña incorrectos';

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_usuario` (IN `p_nombre_usuario` VARCHAR(50), IN `p_email` VARCHAR(100), IN `p_password` VARCHAR(100), IN `p_rol` VARCHAR(20))   BEGIN
    DECLARE v_salt CHAR(32);
    IF CHAR_LENGTH(p_password) < 8
    OR CAST(p_password AS BINARY) = CAST(LOWER(p_password) AS BINARY)
    OR p_password NOT REGEXP '[0-9]' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La contraseña debe tener minimo 8 caracteres, una mayuscula y un numero';
    END IF;

    SET v_salt = LEFT(SHA2(CONCAT(UUID(), RAND(), NOW(6)), 256), 32);

    INSERT INTO usuarios (nombre_usuario, email, password, salt, rol)
    VALUES (
        p_nombre_usuario,
        p_email,
        SHA2(CONCAT(v_salt, p_password), 256),
        v_salt,
        p_rol
    );
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `administrador_establecimiento`
--

CREATE TABLE `administrador_establecimiento` (
  `id_usuario` int(11) NOT NULL,
  `id_establecimiento` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `administrador_establecimiento`
--

INSERT INTO `administrador_establecimiento` (`id_usuario`, `id_establecimiento`) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4);

--
-- Disparadores `administrador_establecimiento`
--
DELIMITER $$
CREATE TRIGGER `tgr_validar_administrador_establecimiento` BEFORE INSERT ON `administrador_establecimiento` FOR EACH ROW BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'admin'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario administrador debe tener el rol admin';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tgr_validar_administrador_establecimiento_update` BEFORE UPDATE ON `administrador_establecimiento` FOR EACH ROW BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'admin'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario administrador debe tener el rol admin';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria_establecimiento`
--

CREATE TABLE `categoria_establecimiento` (
  `id_categoria` int(11) NOT NULL,
  `categoria` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `categoria_establecimiento`
--

INSERT INTO `categoria_establecimiento` (`id_categoria`, `categoria`) VALUES
(1, 'Barberia'),
(3, 'Manicure'),
(4, 'Peluqueria'),
(2, 'Spa');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `id_cliente` int(11) NOT NULL,
  `nom_cli` varchar(150) NOT NULL,
  `ape_cli` varchar(150) NOT NULL,
  `tel_cli` varchar(20) NOT NULL,
  `cor_cli` varchar(150) NOT NULL,
  `tipo_documento` varchar(20) NOT NULL,
  `doc_cli` varchar(25) NOT NULL,
  `id_usuario` int(11) NOT NULL
) ;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`id_cliente`, `nom_cli`, `ape_cli`, `tel_cli`, `cor_cli`, `tipo_documento`, `doc_cli`, `id_usuario`) VALUES
(1, 'Kylian', 'Gonzalez', '3001234567', 'kylian@gmail.com', 'CC', '1002001001', 9),
(2, 'Juan', 'Perez', '3012345678', 'juan.perez@gmail.com', 'CC', '1002001002', 10),
(3, 'Carlos', 'Martinez', '3034567890', 'carlos.martinez@gmail.com', 'CC', '1002001003', 11),
(4, 'Andres', 'Garcia', '3056789012', 'andres.garcia@gmail.com', 'CC', '1002001004', 12),
(5, 'Diego', 'Ramirez', '3078901234', 'diego.ramirez@gmail.com', 'CC', '1002001005', 13),
(6, 'Miguel', 'Castro', '3090123456', 'miguel.castro@gmail.com', 'CC', '1002001006', 14),
(7, 'Laura', 'Lopez', '3045678901', 'laura.lopez@gmail.com', 'CC', '1002001007', 15),
(8, 'Maria', 'Lopez', '3101234567', 'maria@gmail.com', 'CC', '1002001008', 16),
(9, 'Camila', 'Torres', '3067890123', 'camila.torres@gmail.com', 'CC', '1002001009', 17),
(10, 'Maria', 'Rodriguez', '3023456789', 'maria.rodriguez@gmail.com', 'CC', '1002001010', 18),
(11, 'Sofia', 'Herrera', '3089012345', 'sofia.herrera@gmail.com', 'CC', '1002001011', 19);

--
-- Disparadores `cliente`
--
DELIMITER $$
CREATE TRIGGER `tgr_validar_cliente` BEFORE INSERT ON `cliente` FOR EACH ROW BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'cliente'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente debe tener el rol cliente';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tgr_validar_cliente_update` BEFORE UPDATE ON `cliente` FOR EACH ROW BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'cliente'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente debe tener el rol cliente';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleado`
--

CREATE TABLE `empleado` (
  `id_empleado` int(11) NOT NULL,
  `nom_empleado` varchar(150) NOT NULL,
  `ape_empleado` varchar(150) NOT NULL,
  `tipo_documento` varchar(20) NOT NULL,
  `doc_emp` varchar(25) NOT NULL,
  `cor_emp` varchar(150) NOT NULL,
  `tel_emp` varchar(20) NOT NULL,
  `ser_emp` varchar(100) NOT NULL,
  `id_establecimiento` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL
) ;

--
-- Volcado de datos para la tabla `empleado`
--

INSERT INTO `empleado` (`id_empleado`, `nom_empleado`, `ape_empleado`, `tipo_documento`, `doc_emp`, `cor_emp`, `tel_emp`, `ser_emp`, `id_establecimiento`, `id_usuario`) VALUES
(1, 'Juan', 'Rabelo', 'CC', '1001001001', 'juan.rabelo@freshstyle.com', '3012345678', 'Barbero', 1, 5),
(2, 'Camilo', 'Vargas', 'CC', '1001001002', 'camilo.vargas@freshstyle.com', '3034523456', 'Masajista', 2, 6),
(3, 'Lucia', 'Gomez', 'CC', '1001001003', 'lucia.gomez@freshstyle.com', '3028765432', 'Manicurista', 3, 7),
(4, 'Ana', 'Martinez', 'CC', '1001001004', 'ana.martinez@freshstyle.com', '3023456891', 'Peluquera', 4, 8);

--
-- Disparadores `empleado`
--
DELIMITER $$
CREATE TRIGGER `tgr_validar_empleado` BEFORE INSERT ON `empleado` FOR EACH ROW BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'empleado'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado debe tener el rol empleado';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tgr_validar_empleado_update` BEFORE UPDATE ON `empleado` FOR EACH ROW BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM usuarios
        WHERE id_usuario = NEW.id_usuario AND rol = 'empleado'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado debe tener el rol empleado';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `establecimiento`
--

CREATE TABLE `establecimiento` (
  `id_establecimiento` int(11) NOT NULL,
  `nom_est` varchar(150) NOT NULL,
  `direccion` varchar(100) NOT NULL,
  `latitud` decimal(9,6) DEFAULT NULL,
  `longitud` decimal(9,6) DEFAULT NULL,
  `tel` varchar(20) NOT NULL,
  `descri` varchar(300) DEFAULT NULL,
  `id_categoria` int(11) NOT NULL,
  `estado` int(11) NOT NULL DEFAULT 1
) ;

--
-- Volcado de datos para la tabla `establecimiento`
--

INSERT INTO `establecimiento` (`id_establecimiento`, `nom_est`, `direccion`, `latitud`, `longitud`, `tel`, `descri`, `id_categoria`, `estado`) VALUES
(1, 'Barberia Elite', 'calle 100', NULL, NULL, '3001234567', 'Servicios de barberia', 1, 1),
(2, 'Spa Relax', 'Calle 57', NULL, NULL, '3002222222', 'Servicios de spa', 2, 1),
(3, 'Arte en las Manos', 'calle 22', NULL, NULL, '3137895439', 'Servicios de manicure', 3, 1),
(4, 'La Tijera Urbana', 'calle 41', NULL, NULL, '3206778891', 'Servicios de peluqueria', 4, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `horarios`
--

CREATE TABLE `horarios` (
  `id_horario` int(11) NOT NULL,
  `id_empleado` int(11) NOT NULL,
  `dia_semana` varchar(15) NOT NULL,
  `hora_inicio` time NOT NULL,
  `hora_fin` time NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT 1
) ;

--
-- Volcado de datos para la tabla `horarios`
--

INSERT INTO `horarios` (`id_horario`, `id_empleado`, `dia_semana`, `hora_inicio`, `hora_fin`, `estado`) VALUES
(1, 1, 'Lunes', '08:00:00', '17:00:00', 1),
(2, 1, 'Miercoles', '08:00:00', '17:00:00', 1),
(3, 1, 'Viernes', '08:00:00', '17:00:00', 1),
(4, 2, 'Martes', '09:00:00', '18:00:00', 1),
(5, 2, 'Jueves', '09:00:00', '18:00:00', 1),
(6, 2, 'Sabado', '09:00:00', '14:00:00', 1),
(7, 3, 'Lunes', '10:00:00', '18:00:00', 1),
(8, 3, 'Miercoles', '10:00:00', '18:00:00', 1),
(9, 3, 'Viernes', '10:00:00', '18:00:00', 1),
(10, 4, 'Martes', '08:00:00', '17:00:00', 1),
(11, 4, 'Jueves', '08:00:00', '17:00:00', 1),
(12, 4, 'Sabado', '08:00:00', '15:00:00', 1);

--
-- Disparadores `horarios`
--
DELIMITER $$
CREATE TRIGGER `tgr_validar_horario_insert` BEFORE INSERT ON `horarios` FOR EACH ROW BEGIN
    IF EXISTS (
        SELECT 1
        FROM horarios h
        WHERE h.id_empleado = NEW.id_empleado
          AND h.dia_semana = NEW.dia_semana
          AND h.estado = 1
          AND NEW.estado = 1
          AND NEW.hora_inicio < h.hora_fin
          AND NEW.hora_fin > h.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El horario se superpone con otro horario del empleado';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tgr_validar_horario_update` BEFORE UPDATE ON `horarios` FOR EACH ROW BEGIN
    IF EXISTS (
        SELECT 1
        FROM horarios h
        WHERE h.id_horario <> NEW.id_horario
          AND h.id_empleado = NEW.id_empleado
          AND h.dia_semana = NEW.dia_semana
          AND h.estado = 1
          AND NEW.estado = 1
          AND NEW.hora_inicio < h.hora_fin
          AND NEW.hora_fin > h.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El horario se superpone con otro horario del empleado';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reserva`
--

CREATE TABLE `reserva` (
  `id_reserva` int(11) NOT NULL,
  `cos_total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `f_res` date NOT NULL,
  `hora_inicio` time NOT NULL,
  `hora_fin` time NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `id_servicio` int(11) NOT NULL,
  `est_res` varchar(20) NOT NULL DEFAULT 'pendiente'
) ;

--
-- Volcado de datos para la tabla `reserva`
--

INSERT INTO `reserva` (`id_reserva`, `cos_total`, `f_res`, `hora_inicio`, `hora_fin`, `id_cliente`, `id_servicio`, `est_res`) VALUES
(1, 20000.00, '2026-11-25', '09:00:00', '10:00:00', 1, 1, 'pendiente'),
(2, 65000.00, '2026-11-26', '10:00:00', '11:30:00', 2, 6, 'confirmada'),
(3, 35000.00, '2026-11-27', '11:00:00', '12:00:00', 3, 2, 'completada'),
(4, 45000.00, '2026-11-28', '14:00:00', '15:00:00', 4, 14, 'pendiente'),
(5, 55000.00, '2026-11-28', '10:00:00', '11:30:00', 5, 7, 'confirmada'),
(6, 80000.00, '2026-11-28', '09:00:00', '11:00:00', 6, 15, 'cancelada'),
(7, 18000.00, '2026-11-27', '10:00:00', '10:30:00', 7, 3, 'confirmada'),
(8, 55000.00, '2026-11-28', '12:00:00', '13:30:00', 8, 8, 'pendiente'),
(9, 55000.00, '2026-11-30', '10:00:00', '11:30:00', 9, 12, 'completada'),
(10, 80000.00, '2026-12-01', '10:00:00', '12:00:00', 10, 15, 'confirmada'),
(11, 45000.00, '2026-12-01', '14:00:00', '15:00:00', 11, 14, 'cancelada');

--
-- Disparadores `reserva`
--
DELIMITER $$
CREATE TRIGGER `tgr_validar_reserva_insert` BEFORE INSERT ON `reserva` FOR EACH ROW BEGIN
    DECLARE v_id_empleado INT;
    DECLARE v_dia VARCHAR(15);
    DECLARE v_precio DECIMAL(10,2);

    SELECT id_empleado, precio INTO v_id_empleado, v_precio
    FROM servicio
    WHERE id_servicio = NEW.id_servicio;

    SET v_dia = CASE DAYOFWEEK(NEW.f_res)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miercoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sabado'
    END;

    SET NEW.cos_total = v_precio;

    IF NOT EXISTS (
        SELECT 1
        FROM horarios
        WHERE id_empleado = v_id_empleado
          AND dia_semana = v_dia
          AND estado = 1
          AND NEW.hora_inicio >= hora_inicio
          AND NEW.hora_fin <= hora_fin
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva esta fuera del horario del empleado';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reserva r
        INNER JOIN servicio s ON s.id_servicio = r.id_servicio
        WHERE s.id_empleado = v_id_empleado
          AND r.f_res = NEW.f_res
          AND r.est_res IN ('pendiente', 'confirmada')
          AND NEW.hora_inicio < r.hora_fin
          AND NEW.hora_fin > r.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado ya tiene una reserva en ese horario';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tgr_validar_reserva_update` BEFORE UPDATE ON `reserva` FOR EACH ROW BEGIN
    DECLARE v_id_empleado INT;
    DECLARE v_dia VARCHAR(15);
    DECLARE v_precio DECIMAL(10,2);

    SELECT id_empleado, precio INTO v_id_empleado, v_precio
    FROM servicio
    WHERE id_servicio = NEW.id_servicio;

    SET v_dia = CASE DAYOFWEEK(NEW.f_res)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miercoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sabado'
    END;

    SET NEW.cos_total = v_precio;

    IF NOT EXISTS (
        SELECT 1
        FROM horarios
        WHERE id_empleado = v_id_empleado
          AND dia_semana = v_dia
          AND estado = 1
          AND NEW.hora_inicio >= hora_inicio
          AND NEW.hora_fin <= hora_fin
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La reserva esta fuera del horario del empleado';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reserva r
        INNER JOIN servicio s ON s.id_servicio = r.id_servicio
        WHERE r.id_reserva <> NEW.id_reserva
          AND s.id_empleado = v_id_empleado
          AND r.f_res = NEW.f_res
          AND r.est_res IN ('pendiente', 'confirmada')
          AND NEW.hora_inicio < r.hora_fin
          AND NEW.hora_fin > r.hora_inicio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El empleado ya tiene una reserva en ese horario';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `servicio`
--

CREATE TABLE `servicio` (
  `id_servicio` int(11) NOT NULL,
  `servicio` varchar(60) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `id_empleado` int(11) NOT NULL
) ;

--
-- Volcado de datos para la tabla `servicio`
--

INSERT INTO `servicio` (`id_servicio`, `servicio`, `precio`, `id_empleado`) VALUES
(1, 'Corte de cabello', 20000.00, 1),
(2, 'Corte y barba', 35000.00, 1),
(3, 'Arreglo de barba', 18000.00, 1),
(4, 'Corte y cejas', 25000.00, 1),
(5, 'Masaje relajante', 60000.00, 2),
(6, 'Masaje descontracturante', 65000.00, 2),
(7, 'Facial hidratante', 55000.00, 2),
(8, 'Exfoliacion corporal', 55000.00, 2),
(9, 'Manicure clasico', 30000.00, 3),
(10, 'Manicure semipermanente', 45000.00, 3),
(11, 'Pedicure', 40000.00, 3),
(12, 'Pedicure spa', 55000.00, 3),
(13, 'Corte de cabello', 45000.00, 4),
(14, 'Corte y cepillado', 45000.00, 4),
(15, 'Tintura', 80000.00, 4),
(16, 'Mechas', 80000.00, 4);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `salt` varchar(32) NOT NULL,
  `rol` varchar(20) NOT NULL DEFAULT 'cliente',
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `intentos_fallidos` int(11) NOT NULL DEFAULT 0,
  `bloqueado` tinyint(1) NOT NULL DEFAULT 0,
  `ultimo_acceso` datetime DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp()
) ;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `email`, `password`, `salt`, `rol`, `activo`, `intentos_fallidos`, `bloqueado`, `ultimo_acceso`, `fecha_creacion`) VALUES
(1, 'admin_elite', 'admin.elite@freshstyle.com', 'f9d7ad4e0ab059d300251cb4efe34bd8c33e7c91ccbf0589c656fa7fe1806ff7', 'f0e56da0011d9486368a0d0e97c1ad65', 'admin', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(2, 'admin_relax', 'admin.relax@freshstyle.com', '3199a724ee6d1721706424d382f8ccf52d522de57a9713c194889c777fc506d6', 'fef2a2aef0faa26276932795f542813c', 'admin', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(3, 'admin_manos', 'admin.manos@freshstyle.com', '1bd17950d2eb34f0736dbeb5cbfb91fbfccd4c6ad155fd0c914f6fa0fabb035d', 'd26145b26b9859a398901d056a7ffd74', 'admin', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(4, 'admin_tijera', 'admin.tijera@freshstyle.com', '701d0171107b36a8bd36609d908fca29a55ad6efaf5ec592cb1a6753d3901864', '91ac693b42661309bb3959e23114ca58', 'admin', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(5, 'juan_rabelo', 'juan.rabelo@freshstyle.com', '92affd1919d70eade23e7844116439abed54782677b18dd94458ebb620e831ea', 'fb2789fd6de53f193dc303dae8ef0b07', 'empleado', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(6, 'camilo_vargas', 'camilo.vargas@freshstyle.com', '3721a7fa760d6b447af3462373f98cb4799b57fe0b9736ee8b4be9c826382153', 'a5dd6ef71180ecfb21dd643b1b5aa037', 'empleado', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(7, 'lucia_gomez', 'lucia.gomez@freshstyle.com', '9c690a4a114bef8291e38c737304460a84a7daf4c359290ef4ce0f1020e33a75', 'a9d63dbf6e7c6b33a92324909b548035', 'empleado', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(8, 'ana_martinez', 'ana.martinez@freshstyle.com', '82570156123141e16cd8d9e13db97e5c04276ecdb397bfc68e4a21ca759e8408', 'bc7cf2f5240cb00387edd3160b68c2af', 'empleado', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(9, 'kylian_gonzalez', 'kylian@gmail.com', 'c712d10adc77c484cfbd7b96ab7f308d92fd19d28ee01707bc2a8fc8b8bb86dc', '2c5061a1a28dcb58c8bb532681cf4b0b', 'cliente', 1, 0, 0, '2026-11-25 12:24:54', '2026-11-25 12:19:45'),
(10, 'juan_perez', 'juan.perez@gmail.com', 'a744b0959058f5732c5a77d17e5ca30c5ec9fe9afc1dc9968f4cf25f617dd476', '6596bcda9f0559e31e0b7a6a404e0e92', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(11, 'carlos_martinez', 'carlos.martinez@gmail.com', 'cb42647a94b22e9fad6a9e54e52476ca98e2da7c38abce87371b0ac5087870e9', '858dbb1ecd9ace8590825216b405efaa', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(12, 'andres_garcia', 'andres.garcia@gmail.com', 'ac9efded50547ca7140550ef7a0c8c4722b0b2febc382ae553acfa2c0681f34b', 'af4837b4ccb9bc61007ce778624cb5b8', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(13, 'diego_ramirez', 'diego.ramirez@gmail.com', '5270016702c958649d1f743d189e30771a92536cb844c88b2c15dd8d50e30b45', 'ff15d3f30dd1380d8c7786f37f82e570', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(14, 'miguel_castro', 'miguel.castro@gmail.com', '81d0dc24fa8ef9b1432755f9356eca8b08576a81c4072d7352a111d221047a4f', 'f06f6d7bbed6dd2f380bd4577705eb46', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(15, 'laura_lopez', 'laura.lopez@gmail.com', 'ad3170e1fdcdee7838c56e64f8544e9acbde0dc186776ead386384b20fdec0fc', '7540a12bec3b23fdd3b11c4f714944b3', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(16, 'maria_lopez', 'maria@gmail.com', '0df7d9511f30946e0b10c12e4d596a590c44c043deac77aab06d8800f707bee2', 'a53dbb80af20e1fb387d1813573d4c58', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(17, 'camila_torres', 'camila.torres@gmail.com', '51067f7b8c4e782a0cb025a2b7712fbf0af5362595d61c627b310434c82eff8b', '387fa6429ad5f630bc871f5fea233c0a', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(18, 'maria_rodriguez', 'maria.rodriguez@gmail.com', '7873949bfda00f55c11848404d3603718976a6910b74a41add47bc8ad5fcddb8', 'd79a68c228d70c0adfcc4da1fba7b2c0', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45'),
(19, 'sofia_herrera', 'sofia.herrera@gmail.com', '6304a62486e5b5b70b41d14fa6ecb664efdf3db25180356e62f5572a015d7cba', '8c4d3bffb67966d233b244c9f806e5fa', 'cliente', 1, 0, 0, NULL, '2026-11-25 12:19:45');

--
-- Disparadores `usuarios`
--
DELIMITER $$
CREATE TRIGGER `tgr_usuarios_auditoria` AFTER UPDATE ON `usuarios` FOR EACH ROW BEGIN
    IF NEW.password <> OLD.password THEN
        INSERT INTO usuarios_auditoria (id_usuario, accion, detalle, usuario_bd)
        VALUES (NEW.id_usuario, 'CAMBIO_PASSWORD', 'se cambio la contraseña', CURRENT_USER());
    END IF;

    IF NEW.bloqueado = TRUE AND OLD.bloqueado = FALSE THEN
        INSERT INTO usuarios_auditoria (id_usuario, accion, detalle, usuario_bd)
        VALUES (NEW.id_usuario, 'BLOQUEO', 'bloqueado por 3 intentos fallidos', CURRENT_USER());
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tgr_validar_rol_usuario_insert` BEFORE INSERT ON `usuarios` FOR EACH ROW BEGIN
    IF NEW.rol NOT IN ('admin', 'cliente', 'empleado') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rol de usuario no valido';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tgr_validar_rol_usuario_update` BEFORE UPDATE ON `usuarios` FOR EACH ROW BEGIN
    IF NEW.rol NOT IN ('admin', 'cliente', 'empleado') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rol de usuario no valido';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios_auditoria`
--

CREATE TABLE `usuarios_auditoria` (
  `id_auditoria` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `accion` varchar(30) NOT NULL,
  `detalle` varchar(255) DEFAULT NULL,
  `usuario_bd` varchar(100) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios_auditoria`
--

INSERT INTO `usuarios_auditoria` (`id_auditoria`, `id_usuario`, `accion`, `detalle`, `usuario_bd`, `fecha`) VALUES
(1, 10, 'BLOQUEO', 'bloqueado por 3 intentos fallidos', 'root@localhost', '2026-11-25 12:25:09'),
(2, 16, 'CAMBIO_PASSWORD', 'se cambio la contraseña', 'root@localhost', '2026-11-25 12:26:10');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `administrador_establecimiento`
--
ALTER TABLE `administrador_establecimiento`
  ADD PRIMARY KEY (`id_usuario`,`id_establecimiento`),
  ADD KEY `fk_admin_est_establecimiento` (`id_establecimiento`);

--
-- Indices de la tabla `categoria_establecimiento`
--
ALTER TABLE `categoria_establecimiento`
  ADD PRIMARY KEY (`id_categoria`),
  ADD UNIQUE KEY `uq_categoria_establecimiento_nom` (`categoria`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`id_cliente`),
  ADD UNIQUE KEY `uq_cliente_cor_cli` (`cor_cli`),
  ADD UNIQUE KEY `uq_cliente_doc_cli` (`doc_cli`),
  ADD UNIQUE KEY `uq_cliente_usuario` (`id_usuario`),
  ADD KEY `idx_cliente_usuario` (`id_usuario`);

--
-- Indices de la tabla `empleado`
--
ALTER TABLE `empleado`
  ADD PRIMARY KEY (`id_empleado`),
  ADD UNIQUE KEY `uq_empleado_doc_emp` (`doc_emp`),
  ADD UNIQUE KEY `uq_empleado_cor_emp` (`cor_emp`),
  ADD UNIQUE KEY `uq_empleado_usuario` (`id_usuario`),
  ADD KEY `fk_empleado_establecimiento` (`id_establecimiento`),
  ADD KEY `idx_empleado_usuario` (`id_usuario`);

--
-- Indices de la tabla `establecimiento`
--
ALTER TABLE `establecimiento`
  ADD PRIMARY KEY (`id_establecimiento`),
  ADD KEY `fk_establecimiento_categoria` (`id_categoria`);

--
-- Indices de la tabla `horarios`
--
ALTER TABLE `horarios`
  ADD PRIMARY KEY (`id_horario`),
  ADD KEY `idx_horarios_empleado_dia` (`id_empleado`,`dia_semana`,`estado`);

--
-- Indices de la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD PRIMARY KEY (`id_reserva`),
  ADD KEY `idx_reserva_fecha_estado` (`f_res`,`est_res`),
  ADD KEY `idx_reserva_cliente` (`id_cliente`),
  ADD KEY `idx_reserva_servicio` (`id_servicio`);

--
-- Indices de la tabla `servicio`
--
ALTER TABLE `servicio`
  ADD PRIMARY KEY (`id_servicio`),
  ADD UNIQUE KEY `uq_servicio_empleado` (`servicio`,`id_empleado`),
  ADD KEY `fk_servicio_empleado` (`id_empleado`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `uq_usuarios_nombre` (`nombre_usuario`),
  ADD UNIQUE KEY `uq_usuarios_email` (`email`);

--
-- Indices de la tabla `usuarios_auditoria`
--
ALTER TABLE `usuarios_auditoria`
  ADD PRIMARY KEY (`id_auditoria`),
  ADD KEY `fk_auditoria_usuario` (`id_usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categoria_establecimiento`
--
ALTER TABLE `categoria_establecimiento`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `empleado`
--
ALTER TABLE `empleado`
  MODIFY `id_empleado` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `establecimiento`
--
ALTER TABLE `establecimiento`
  MODIFY `id_establecimiento` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `horarios`
--
ALTER TABLE `horarios`
  MODIFY `id_horario` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `reserva`
--
ALTER TABLE `reserva`
  MODIFY `id_reserva` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `servicio`
--
ALTER TABLE `servicio`
  MODIFY `id_servicio` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios_auditoria`
--
ALTER TABLE `usuarios_auditoria`
  MODIFY `id_auditoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `administrador_establecimiento`
--
ALTER TABLE `administrador_establecimiento`
  ADD CONSTRAINT `fk_admin_est_establecimiento` FOREIGN KEY (`id_establecimiento`) REFERENCES `establecimiento` (`id_establecimiento`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_admin_est_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `fk_cliente_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `empleado`
--
ALTER TABLE `empleado`
  ADD CONSTRAINT `fk_empleado_establecimiento` FOREIGN KEY (`id_establecimiento`) REFERENCES `establecimiento` (`id_establecimiento`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_empleado_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `establecimiento`
--
ALTER TABLE `establecimiento`
  ADD CONSTRAINT `fk_establecimiento_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categoria_establecimiento` (`id_categoria`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `horarios`
--
ALTER TABLE `horarios`
  ADD CONSTRAINT `fk_horarios_empleado` FOREIGN KEY (`id_empleado`) REFERENCES `empleado` (`id_empleado`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD CONSTRAINT `fk_reserva_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_reserva_servicio` FOREIGN KEY (`id_servicio`) REFERENCES `servicio` (`id_servicio`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `servicio`
--
ALTER TABLE `servicio`
  ADD CONSTRAINT `fk_servicio_empleado` FOREIGN KEY (`id_empleado`) REFERENCES `empleado` (`id_empleado`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuarios_auditoria`
--
ALTER TABLE `usuarios_auditoria`
  ADD CONSTRAINT `fk_auditoria_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
