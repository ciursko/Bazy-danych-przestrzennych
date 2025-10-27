CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
SELECT postgis_full_version();

/*"E:\postgresql\bin\shp2pgsql.exe" -I -s 4326 "E:\DeadByDaylight\Datagrip\DataGrip 2025.2.4\projects\CW3\T2018_KAR_GERMANY\T2018_KAR_BUILDINGS.shp" public.T2018_KAR_BUILDINGS | "E:\postgresql\bin\psql.exe" -h localhost -p 5432 -U postgres -d here*/

DROP TABLE "BUILDINGS_CHANGED";
/* 1 */
CREATE TABLE "BUILDINGS_CHANGED" AS
SELECT b2019.*
FROM "t2019_kar_buildings" b2019
LEFT JOIN "t2018_kar_buildings" b2018
ON b2019.polygon_id = b2018.polygon_id
WHERE b2018.polygon_id IS NULL
   OR ST_Equals(b2019.geom, b2018.geom) IS FALSE;

/* 2 */
CREATE TABLE "NEW_POI_NEAR_BUILDINGS" AS
SELECT p2019.type, COUNT(*) AS poi_count
FROM "t2019_kar_poi_table" p2019
LEFT JOIN "t2018_kar_poi_table" p2018
ON p2019.poi_id = p2018.poi_id
WHERE p2018.poi_id IS NULL
AND EXISTS (
    SELECT 1
    FROM "BUILDINGS_CHANGED" b
    WHERE ST_DWithin(p2019.geom::geography, b.geom::geography, 500)
)
GROUP BY p2019.type;

/* 3 */
CREATE TABLE "STREETS_REPROJECTED" AS
SELECT *, ST_Transform(geom, 3068) AS geom_dhdn
FROM "t2019_kar_streets";

/* 4 */
CREATE TABLE "INPUT_POINTS" (
    id SERIAL PRIMARY KEY,
    geom geometry(Point, 4326)
);

INSERT INTO "INPUT_POINTS" (geom)
VALUES
(ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326)),
(ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326));

/* 5 */
ALTER TABLE "INPUT_POINTS" ADD COLUMN geom_dhdn geometry(Point, 3068);

UPDATE "INPUT_POINTS"
SET geom_dhdn = ST_Transform(geom, 3068);

/* 6 */
CREATE TABLE "INPUT_LINE" AS
SELECT ST_MakeLine(geom_dhdn ORDER BY id) AS geom
FROM "INPUT_POINTS";

-- znalezienie skrzyżowań w promieniu 200 m
CREATE TABLE "NEARBY_INTERSECTIONS" AS
SELECT n.*
FROM "t2019_kar_street_node" n
WHERE ST_DWithin(
    ST_Transform(n.geom, 3068),
    (SELECT geom FROM "INPUT_LINE"),
    200);

/* 7 */
CREATE TABLE "SPORT_STORES_NEAR_PARKS" AS
SELECT COUNT(*) AS store_count
FROM "t2019_kar_poi_table" poi
JOIN "t2019_kar_land_use_a" park
  ON ST_DWithin(
      poi.geom::geography,
      park.geom::geography,
      300
  )
WHERE poi.type = 'Sporting Goods Store';

/* 8 */
CREATE TABLE "T2019_KAR_BRIDGES" AS
SELECT ST_Intersection(r.geom, w.geom) AS geom
FROM "t2019_kar_railways" r
JOIN "t2019_kar_water_lines" w
  ON ST_Intersects(r.geom, w.geom);