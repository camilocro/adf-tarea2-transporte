/* =====================================================================
   CONSULTAS UTILIZADAS - TAREA 2 (ejecutar en el Query editor)
   Basadas en Consultas_Utilizadas.txt del docente, ampliadas a las 7 tablas.
   ===================================================================== */

/* ---------- A) ERP (conectado a erp_transporte_db) ---------- */
SELECT 'RutasAzure' AS tabla, COUNT(*) AS filas FROM dbo.RutasAzure
UNION ALL SELECT 'ParadasAzure', COUNT(*) FROM dbo.ParadasAzure
UNION ALL SELECT 'VehiculosAzure', COUNT(*) FROM dbo.VehiculosAzure
UNION ALL SELECT 'ViajesAzure', COUNT(*) FROM dbo.ViajesAzure
UNION ALL SELECT 'DemandaParadasAzure', COUNT(*) FROM dbo.DemandaParadasAzure
UNION ALL SELECT 'IncidentesAzure', COUNT(*) FROM dbo.IncidentesAzure
UNION ALL SELECT 'IncidenteRutaAzure', COUNT(*) FROM dbo.IncidenteRutaAzure;
-- Esperado: 98, 438, 240, 8400, 18400, 440, 548

/* ---------- B) BRONZE (conectado a dw_transporte) ---------- */
select * from bronze.Paradas;
select * from bronze.Vehiculos;
select * from bronze.Viajes;

SELECT 'Rutas' AS tabla, COUNT(*) AS filas FROM bronze.Rutas
UNION ALL SELECT 'Paradas', COUNT(*) FROM bronze.Paradas
UNION ALL SELECT 'Vehiculos', COUNT(*) FROM bronze.Vehiculos
UNION ALL SELECT 'Viajes', COUNT(*) FROM bronze.Viajes
UNION ALL SELECT 'DemandaParadas', COUNT(*) FROM bronze.DemandaParadas
UNION ALL SELECT 'Incidentes', COUNT(*) FROM bronze.Incidentes
UNION ALL SELECT 'IncidenteRuta', COUNT(*) FROM bronze.IncidenteRuta;
-- Esperado: 289, 1315, 720, 25117, 55200, 1320, 1648

/* ---------- C) SILVER (conectado a dw_transporte) ---------- */
SELECT 'Rutas' AS tabla, COUNT(*) AS filas FROM silver.Rutas
UNION ALL SELECT 'Paradas', COUNT(*) FROM silver.Paradas
UNION ALL SELECT 'Vehiculos', COUNT(*) FROM silver.Vehiculos
UNION ALL SELECT 'Viajes', COUNT(*) FROM silver.Viajes
UNION ALL SELECT 'DemandaParadas', COUNT(*) FROM silver.DemandaParadas
UNION ALL SELECT 'Incidentes', COUNT(*) FROM silver.Incidentes
UNION ALL SELECT 'IncidenteRuta', COUNT(*) FROM silver.IncidenteRuta;
-- Esperado: 51, 220, 120, 25112, 55200, 1320, 1647

/* ---------- D) Verificacion de correcciones en SILVER ---------- */
-- Rutas historicas (R-07 retirada y R-12 dividida)
SELECT * FROM silver.Rutas WHERE RutaHistoricaId LIKE 'RH-07%' OR RutaHistoricaId LIKE 'RH-12%';
-- Mercado Central antes y despues de la reubicacion
SELECT * FROM silver.Paradas WHERE ParadaHistoricaId LIKE 'P220%';
-- Vehiculos con codigos unificados (antes 001 y V-001)
SELECT TOP 10 * FROM silver.Vehiculos ORDER BY VehiculoId;
-- Viajes por anio (2020 a 2025) y formato de ID unificado
SELECT YEAR(FechaServicio) AS anio, COUNT(*) AS viajes, MIN(ViajeId) AS primer_id
FROM silver.Viajes GROUP BY YEAR(FechaServicio) ORDER BY anio;
-- Demanda por anio y metodo de medicion
SELECT YEAR(FechaServicio) AS anio, Metodo, COUNT(*) AS filas
FROM silver.DemandaParadas GROUP BY YEAR(FechaServicio), Metodo ORDER BY anio, Metodo;
-- Incidentes por anio
SELECT YEAR(FechaHoraInicio) AS anio, COUNT(*) AS incidentes FROM silver.Incidentes
GROUP BY YEAR(FechaHoraInicio) ORDER BY anio;
-- Registros rechazados: el viaje duplicado 00322-A y las filas TOTAL de los Excel no deben estar
SELECT * FROM silver.Viajes WHERE ViajeId LIKE '%00322%' OR ViajeId LIKE 'TOTAL%';
