-- MODELO RELACIONAL: Complejo Deportivo
-- Basado en el diagrama de clases v1.3 (18/11/2026).
-- Compatible con MySQL 8.0 / MySQL Workbench 8.0.
-- Se omiten las clases de control/acceso a datos:
-- controllerTurno, turnoBD y verificadorDisponibilidad.
-- Las enumeraciones UML se implementan como ENUM de MySQL.
-- Los identificadores (id...) se agregan como claves primarias técnicas.

CREATE DATABASE IF NOT EXISTS complejo_deportivo
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE complejo_deportivo;

-- ENTIDADES INDEPENDIENTES

CREATE TABLE Localidad (
    idLocalidad INT AUTO_INCREMENT PRIMARY KEY,
    codigoPostal INT NOT NULL,
    nombre VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Categoria (
    idCategoria INT AUTO_INCREMENT PRIMARY KEY,
    nivel INT NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Administrador (
    idAdministrador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    contrasena VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Jugador (
    idJugador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    foto VARCHAR(500),
    ausencias INT NOT NULL DEFAULT 0,
    partidosGanados INT NOT NULL DEFAULT 0,
    partidosPerdidos INT NOT NULL DEFAULT 0,
    reputacion INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- COMPLEJOS, CANCHAS Y DISPONIBILIDAD

CREATE TABLE Complejo (
    idComplejo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    calle VARCHAR(120) NOT NULL,
    altura INT NOT NULL,
    celular VARCHAR(30),
    correo VARCHAR(150),
    idLocalidad INT NOT NULL,
    CONSTRAINT fk_complejo_localidad
        FOREIGN KEY (idLocalidad) REFERENCES Localidad(idLocalidad)
) ENGINE=InnoDB;

CREATE TABLE Cancha (
    idCancha INT AUTO_INCREMENT PRIMARY KEY,
    numero INT NOT NULL,
    tipo ENUM('CEMENTO', 'CESPED', 'SINTETICO') NOT NULL,
    idComplejo INT NOT NULL,
    CONSTRAINT fk_cancha_complejo
        FOREIGN KEY (idComplejo) REFERENCES Complejo(idComplejo)
) ENGINE=InnoDB;

CREATE TABLE FranjaDisponible (
    idFranjaDisponible INT AUTO_INCREMENT PRIMARY KEY,
    diaSemana ENUM('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES',
                   'VIERNES', 'SABADO', 'DOMINGO') NOT NULL,
    horaInicio TIME NOT NULL,
    horaFin TIME NOT NULL,
    idCancha INT NOT NULL,
    CONSTRAINT fk_franja_cancha
        FOREIGN KEY (idCancha) REFERENCES Cancha(idCancha),
    CONSTRAINT chk_franja_horario CHECK (horaFin > horaInicio)
) ENGINE=InnoDB;

CREATE TABLE Excepcion (
    idExcepcion INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL,
    horaInicio TIME NOT NULL,
    horaFin TIME NOT NULL,
    motivo VARCHAR(255),
    idFranjaDisponible INT NOT NULL,
    CONSTRAINT fk_excepcion_franja
        FOREIGN KEY (idFranjaDisponible)
        REFERENCES FranjaDisponible(idFranjaDisponible),
    CONSTRAINT chk_excepcion_horario CHECK (horaFin > horaInicio)
) ENGINE=InnoDB;

-- CERTIFICADOS Y BUSQUEDAS DE COMPANEROS

CREATE TABLE Certificado (
    idCertificado INT AUTO_INCREMENT PRIMARY KEY,
    estado ENUM('PENDIENTE', 'APROBADO', 'RECHAZADO') NOT NULL,
    fechaEnvio DATETIME NOT NULL,
    motivoRechazo VARCHAR(255),
    url VARCHAR(500) NOT NULL,
    idJugador INT NOT NULL,
    idCategoria INT NOT NULL,
    idAdministrador INT NULL,
    CONSTRAINT fk_certificado_jugador
        FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),
    CONSTRAINT fk_certificado_categoria
        FOREIGN KEY (idCategoria) REFERENCES Categoria(idCategoria),
    CONSTRAINT fk_certificado_administrador
        FOREIGN KEY (idAdministrador) REFERENCES Administrador(idAdministrador)
) ENGINE=InnoDB;

CREATE TABLE BusquedaCompanero (
    idBusquedaCompanero INT AUTO_INCREMENT PRIMARY KEY,
    estado ENUM('ACTIVA', 'COMPLETADA', 'CANCELADA') NOT NULL,
    fechaHoraDesde DATETIME NOT NULL,
    fechaHoraHasta DATETIME NOT NULL,
    idJugador INT NOT NULL,
    idCategoria INT NOT NULL,
    idLocalidad INT NOT NULL,
    CONSTRAINT fk_busqueda_companero_jugador
        FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),
    CONSTRAINT fk_busqueda_companero_categoria
        FOREIGN KEY (idCategoria) REFERENCES Categoria(idCategoria),
    CONSTRAINT fk_busqueda_companero_localidad
        FOREIGN KEY (idLocalidad) REFERENCES Localidad(idLocalidad),
    CONSTRAINT chk_busqueda_companero_fechas
        CHECK (fechaHoraHasta >= fechaHoraDesde)
) ENGINE=InnoDB;

-- PAREJAS Y PARTIDOS

CREATE TABLE Pareja (
    idPareja INT AUTO_INCREMENT PRIMARY KEY,
    sumaCategorias INT NOT NULL
) ENGINE=InnoDB;

-- Jugador (0..*) <-> Pareja (2 jugadores por pareja).
-- La tabla intermedia representa la asociacion muchos-a-muchos.
-- La regla de EXACTAMENTE 2 jugadores por pareja debe comprobarse
-- en la logica de negocio o mediante una validacion transaccional.
CREATE TABLE ParejaJugador (
    idPareja INT NOT NULL,
    idJugador INT NOT NULL,
    PRIMARY KEY (idPareja, idJugador),
    CONSTRAINT fk_pareja_jugador_pareja
        FOREIGN KEY (idPareja) REFERENCES Pareja(idPareja),
    CONSTRAINT fk_pareja_jugador_jugador
        FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador)
) ENGINE=InnoDB;

CREATE TABLE BusquedaMatch (
    idBusquedaMatch INT AUTO_INCREMENT PRIMARY KEY,
    estado ENUM('ACTIVA', 'COMPLETADA', 'CANCELADA') NOT NULL,
    fechaHoraDesde DATETIME NOT NULL,
    fechaHoraHasta DATETIME NOT NULL,
    sumaDeCategorias INT NOT NULL,
    idPareja INT NOT NULL,
    idCancha INT NULL,
    CONSTRAINT fk_busqueda_match_pareja
        FOREIGN KEY (idPareja) REFERENCES Pareja(idPareja),
    CONSTRAINT fk_busqueda_match_cancha
        FOREIGN KEY (idCancha) REFERENCES Cancha(idCancha),
    CONSTRAINT chk_busqueda_match_fechas
        CHECK (fechaHoraHasta >= fechaHoraDesde)
) ENGINE=InnoDB;

CREATE TABLE Partido (
    idPartido INT AUTO_INCREMENT PRIMARY KEY,
    estado ENUM('PENDIENTE', 'CANCELADO', 'CONFIRMADO', 'FINALIZADO') NOT NULL,
    idParejaLocal INT NOT NULL,
    idParejaVisitante INT NOT NULL,
    CONSTRAINT fk_partido_pareja_local
        FOREIGN KEY (idParejaLocal) REFERENCES Pareja(idPareja),
    CONSTRAINT fk_partido_pareja_visitante
        FOREIGN KEY (idParejaVisitante) REFERENCES Pareja(idPareja),
    CONSTRAINT chk_partido_parejas_distintas
        CHECK (idParejaLocal <> idParejaVisitante)
) ENGINE=InnoDB;

-- Se utiliza SetPartido porque SET es una palabra reservada en MySQL.
-- El numero solo puede ser 1, 2 o 3: maximo tres sets por partido.
CREATE TABLE SetPartido (
    idSet INT AUTO_INCREMENT PRIMARY KEY,
    numero INT NOT NULL,
    gamesLocal INT NOT NULL,
    gamesVisitante INT NOT NULL,
    idPartido INT NOT NULL,
    UNIQUE KEY uq_set_partido_numero (idPartido, numero),
    CONSTRAINT fk_set_partido
        FOREIGN KEY (idPartido) REFERENCES Partido(idPartido),
    CONSTRAINT chk_set_numero CHECK (numero BETWEEN 1 AND 3)
) ENGINE=InnoDB;

CREATE TABLE Calificacion (
    idCalificacion INT AUTO_INCREMENT PRIMARY KEY,
    calificacion INT NOT NULL,
    idJugadorPone INT NOT NULL,
    idJugadorRecibe INT NOT NULL,
    idPartido INT NOT NULL,
    CONSTRAINT fk_calificacion_jugador_pone
        FOREIGN KEY (idJugadorPone) REFERENCES Jugador(idJugador),
    CONSTRAINT fk_calificacion_jugador_recibe
        FOREIGN KEY (idJugadorRecibe) REFERENCES Jugador(idJugador),
    CONSTRAINT fk_calificacion_partido
        FOREIGN KEY (idPartido) REFERENCES Partido(idPartido)
) ENGINE=InnoDB;

-- TURNOS Y CANCELACIONES

CREATE TABLE Turno (
    idTurno INT AUTO_INCREMENT PRIMARY KEY,
    fechaHoraInicio DATETIME NOT NULL,
    fechaHoraFin DATETIME NOT NULL,
    idJugador INT NOT NULL,
    idCancha INT NOT NULL,
    idPartido INT NOT NULL,
    -- UML: un partido tiene como maximo un turno.
    UNIQUE KEY uq_turno_partido (idPartido),
    CONSTRAINT fk_turno_jugador
        FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),
    CONSTRAINT fk_turno_cancha
        FOREIGN KEY (idCancha) REFERENCES Cancha(idCancha),
    CONSTRAINT fk_turno_partido
        FOREIGN KEY (idPartido) REFERENCES Partido(idPartido),
    CONSTRAINT chk_turno_fechas
        CHECK (fechaHoraFin > fechaHoraInicio)
) ENGINE=InnoDB;

CREATE TABLE Cancelacion (
    idCancelacion INT AUTO_INCREMENT PRIMARY KEY,
    fechaHora DATETIME NOT NULL,
    idJugador INT NOT NULL,
    idTurno INT NOT NULL,
    -- UML: un turno puede tener 0 o 1 cancelacion.
    UNIQUE KEY uq_cancelacion_turno (idTurno),
    CONSTRAINT fk_cancelacion_jugador
        FOREIGN KEY (idJugador) REFERENCES Jugador(idJugador),
    CONSTRAINT fk_cancelacion_turno
        FOREIGN KEY (idTurno) REFERENCES Turno(idTurno)
) ENGINE=InnoDB;

-- OTRAS REGLAS UML A VALIDAR FUERA DE ESTE DDL:
-- - Cada pareja debe contener exactamente 2 jugadores.
-- - Cada complejo debe tener al menos 10 canchas segun la figura UML
--   (el reporte de asociaciones consigna 0..*; se debe confirmar).
-- - La disponibilidad, los solapamientos de turnos y la cancelacion
--   con 24 horas de anticipacion son reglas de negocio.
