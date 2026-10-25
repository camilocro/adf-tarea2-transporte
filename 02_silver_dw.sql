/*
  VERSION 2 - CAPA SILVER (ajustada segun la clase, video 5.3.4)
  Ejecutar despues de 01_bronze_dw.sql, conectado a dw_transporte.

  Cambios respecto a 02_silver_v2.sql del docente (los mismos que hizo en clase):
    1. Se quita la palabra "Azure" del nombre de las tablas (silver.Paradas, silver.Rutas, ...).
    2. Se elimina la columna AnioFuente. Los CSV (2020-2021) y Excel (2022-2023) no traen ese
       dato y el campo es NOT NULL y parte de la llave primaria, por eso el sink fallaba.
       Las llaves pasan a ser solo el identificador (los ID de hechos ya llevan el anio:
       VJ-2020-00001, IN-2022-0001, DM-2024-00001).
    3. HoraProgramada, HoraSalida y HoraLlegada se guardan como NVARCHAR(8) (HH:mm:ss)
       porque Data Factory no convierte texto al tipo TIME (error NULL en el receptor).
  Todo lo demas (tipos, NOT NULL, llaves foraneas e indices) se mantiene igual.
*/
SET NOCOUNT ON;
GO

IF DB_NAME() <> N'dw_transporte'
    THROW 51100, 'Conectese a la base de datos dw_transporte antes de ejecutar este script.', 1;
GO

IF SCHEMA_ID(N'silver') IS NULL EXEC(N'CREATE SCHEMA silver');
GO

IF OBJECT_ID(N'silver.Rutas', N'U') IS NOT NULL
    THROW 51101, 'silver.Rutas ya existe. Version 2 requiere una base limpia.', 1;
IF OBJECT_ID(N'silver.Paradas', N'U') IS NOT NULL
    THROW 51102, 'silver.Paradas ya existe. Version 2 requiere una base limpia.', 1;
IF OBJECT_ID(N'silver.Vehiculos', N'U') IS NOT NULL
    THROW 51103, 'silver.Vehiculos ya existe. Version 2 requiere una base limpia.', 1;
IF OBJECT_ID(N'silver.Viajes', N'U') IS NOT NULL
    THROW 51104, 'silver.Viajes ya existe. Version 2 requiere una base limpia.', 1;
IF OBJECT_ID(N'silver.DemandaParadas', N'U') IS NOT NULL
    THROW 51105, 'silver.DemandaParadas ya existe. Version 2 requiere una base limpia.', 1;
IF OBJECT_ID(N'silver.Incidentes', N'U') IS NOT NULL
    THROW 51106, 'silver.Incidentes ya existe. Version 2 requiere una base limpia.', 1;
IF OBJECT_ID(N'silver.IncidenteRuta', N'U') IS NOT NULL
    THROW 51107, 'silver.IncidenteRuta ya existe. Version 2 requiere una base limpia.', 1;
GO

CREATE TABLE silver.Rutas (
    RutaHistoricaId    NVARCHAR(30)  NOT NULL,
    CodigoRuta         NVARCHAR(20)  NOT NULL,
    NombreRuta         NVARCHAR(120) NOT NULL,
    Origen             NVARCHAR(80)  NOT NULL,
    Destino            NVARCHAR(80)  NOT NULL,
    VigenciaDesde      DATE          NOT NULL,
    VigenciaHasta      DATE          NOT NULL,
    Estado             NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK_silver_Rutas PRIMARY KEY (RutaHistoricaId)
);
GO

CREATE TABLE silver.Paradas (
    ParadaHistoricaId  NVARCHAR(30)  NOT NULL,
    CodigoPublicado    NVARCHAR(20)  NOT NULL,
    NombreParada       NVARCHAR(120) NOT NULL,
    Zona               NVARCHAR(40)  NOT NULL,
    Latitud            DECIMAL(9,6)  NOT NULL,
    Longitud           DECIMAL(9,6)  NOT NULL,
    VigenciaDesde      DATE          NOT NULL,
    VigenciaHasta      DATE          NOT NULL,
    Estado             NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK_silver_Paradas PRIMARY KEY (ParadaHistoricaId)
);
GO

CREATE TABLE silver.Vehiculos (
    VehiculoId          NVARCHAR(20) NOT NULL,
    Placa               NVARCHAR(20) NOT NULL,
    TipoVehiculo        NVARCHAR(30) NOT NULL,
    CapacidadEfectiva   INT          NOT NULL,
    VigenciaDesde       DATE         NOT NULL,
    VigenciaHasta       DATE         NOT NULL,
    Estado              NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_silver_Vehiculos PRIMARY KEY (VehiculoId)
);
GO

CREATE TABLE silver.Viajes (
    ViajeId               NVARCHAR(30)  NOT NULL,
    RutaHistoricaId       NVARCHAR(30)  NOT NULL,
    VehiculoId            NVARCHAR(20)  NOT NULL,
    FechaServicio         DATE          NOT NULL,
    HoraProgramada        NVARCHAR(8)   NOT NULL,
    HoraSalida            NVARCHAR(8)   NOT NULL,
    HoraLlegada           NVARCHAR(8)   NOT NULL,
    ValidacionesTarjeta   INT           NOT NULL,
    KmRecorridos          DECIMAL(8,1)  NOT NULL,
    EstadoViaje           NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK_silver_Viajes PRIMARY KEY (ViajeId),
    CONSTRAINT FK_silver_Viajes_Rutas FOREIGN KEY (RutaHistoricaId)
        REFERENCES silver.Rutas (RutaHistoricaId),
    CONSTRAINT FK_silver_Viajes_Vehiculos FOREIGN KEY (VehiculoId)
        REFERENCES silver.Vehiculos (VehiculoId)
);
GO

CREATE TABLE silver.DemandaParadas (
    DemandaId              NVARCHAR(30)  NOT NULL,
    FechaServicio          DATE          NOT NULL,
    RutaHistoricaId        NVARCHAR(30)  NOT NULL,
    ParadaHistoricaId      NVARCHAR(30)  NOT NULL,
    Franja                 NVARCHAR(20)  NOT NULL,
    ValidacionesTarjeta    INT           NOT NULL,
    Descensos              INT           NOT NULL,
    DemandaNoAtendida      INT           NOT NULL,
    Metodo                 NVARCHAR(30)  NOT NULL,
    CONSTRAINT PK_silver_DemandaParadas PRIMARY KEY (DemandaId),
    CONSTRAINT FK_silver_Demanda_Rutas FOREIGN KEY (RutaHistoricaId)
        REFERENCES silver.Rutas (RutaHistoricaId),
    CONSTRAINT FK_silver_Demanda_Paradas FOREIGN KEY (ParadaHistoricaId)
        REFERENCES silver.Paradas (ParadaHistoricaId)
);
GO

CREATE TABLE silver.Incidentes (
    IncidenteId         NVARCHAR(30)   NOT NULL,
    TipoIncidente       NVARCHAR(30)   NOT NULL,
    Severidad           NVARCHAR(15)   NOT NULL,
    FechaHoraInicio     DATETIME2(0)   NOT NULL,
    FechaHoraFin        DATETIME2(0)   NOT NULL,
    FechaHoraRegistro   DATETIME2(0)   NOT NULL,
    VehiculoId          NVARCHAR(20)   NULL,
    Descripcion         NVARCHAR(200)  NOT NULL,
    CONSTRAINT PK_silver_Incidentes PRIMARY KEY (IncidenteId),
    CONSTRAINT FK_silver_Incidentes_Vehiculos FOREIGN KEY (VehiculoId)
        REFERENCES silver.Vehiculos (VehiculoId)
);
GO

CREATE TABLE silver.IncidenteRuta (
    IncidenteId       NVARCHAR(30)  NOT NULL,
    RutaHistoricaId   NVARCHAR(30)  NOT NULL,
    EsPrincipal       BIT           NOT NULL,
    CONSTRAINT PK_silver_IncidenteRuta PRIMARY KEY (IncidenteId, RutaHistoricaId),
    CONSTRAINT FK_silver_IncidenteRuta_Incidente FOREIGN KEY (IncidenteId)
        REFERENCES silver.Incidentes (IncidenteId),
    CONSTRAINT FK_silver_IncidenteRuta_Ruta FOREIGN KEY (RutaHistoricaId)
        REFERENCES silver.Rutas (RutaHistoricaId)
);
GO

CREATE INDEX IX_silver_Viajes_FechaRuta
    ON silver.Viajes (FechaServicio, RutaHistoricaId);
CREATE INDEX IX_silver_Demanda_FechaFranja
    ON silver.DemandaParadas (FechaServicio, Franja);
GO
