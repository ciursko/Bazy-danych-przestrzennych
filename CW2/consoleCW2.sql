CREATE EXTENSION IF NOT EXISTS postgis;
SELECT postgis_version();

CREATE TABLE buildings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    geom GEOMETRY(POLYGON)
);

CREATE TABLE roads (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    geom GEOMETRY(LINESTRING)
);

CREATE TABLE points (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    geom GEOMETRY(POINT)
);


INSERT INTO buildings (name, geom)
VALUES
('BuildingA', ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))')),
('BuildingB', ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))')),
('BuildingC', ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))')),
('BuildingD', ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))')),
('BuildingF', ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))'));


INSERT INTO roads (name, geom)
VALUES
('RoadX', ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)')),
('RoadY', ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)'));


INSERT INTO points (name, geom)
VALUES
('G', ST_GeomFromText('POINT(1 3.5)')),
('H', ST_GeomFromText('POINT(5.5 1.5)')),
('I', ST_GeomFromText('POINT(9.5 6)')),
('J', ST_GeomFromText('POINT(6.5 6)')),
('K', ST_GeomFromText('POINT(6 9.5)'));


/* A */
SELECT SUM(ST_Length(geom)) AS total_road_length
FROM roads;


/* B */
SELECT ST_AsText(geom) AS wkt, ST_Area(geom) AS area, ST_Perimeter(geom) AS perimeter
FROM buildings
WHERE name = 'BuildingA';


/* C */
SELECT name, ST_Area(geom) AS area
FROM buildings
ORDER BY name;


/* D */
SELECT name, ST_Perimeter(geom) AS perimeter
FROM buildings
ORDER BY ST_Area(geom) DESC
LIMIT 2;


/* E */
SELECT ST_Distance(b.geom, p.geom) AS distance
FROM buildings b, points p
WHERE b.name = 'BuildingC' AND p.name = 'K';


/* F */
SELECT ST_Area(ST_Difference(bC.geom, ST_Buffer(bB.geom, 0.5))) AS area
FROM buildings bC, buildings bB
WHERE bC.name = 'BuildingC' AND bB.name = 'BuildingB';


/* G */
SELECT b.name
FROM buildings b, roads r
WHERE r.name = 'RoadX' AND ST_Y(ST_Centroid(b.geom)) > ST_Y(r.geom);


/* H */
SELECT ST_Area(ST_SymDifference(b.geom, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) AS non_common_area
FROM buildings b
WHERE b.name = 'BuildingC';