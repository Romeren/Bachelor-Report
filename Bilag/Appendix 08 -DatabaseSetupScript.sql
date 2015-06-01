CREATE TABLE aliascomparison
(
  simmilarity REAL NOT NULL,
  primaryid BIGINT,
  secoundaryid BIGINT
);
CREATE TABLE backupbbr
(
  building_id INT,
  street VARCHAR(100),
  zip_code INT,
  built_area INT,
  building_area INT,
  heated_area INT,
  total_area INT,
  attic INT,
  cellar_area INT,
  total_residence INT,
  site_area INT,
  validatedat TIMESTAMP
);
CREATE TABLE backupobservations
(
  measurement_id INT,
  obs_val REAL,
  obs_type INT
);
CREATE TABLE backupobservationstimes
(
  measurement_serie_id INT,
  start_time TIMESTAMP,
  measurement_id INT,
  end_time TIMESTAMP
);
CREATE TABLE bbr
(
  building_id INT PRIMARY KEY NOT NULL,
  street VARCHAR(100),
  zip_code INT,
  built_area INT,
  building_area INT,
  heated_area INT,
  total_area INT,
  attic INT,
  cellar_area INT,
  total_residence INT,
  site_area INT,
  validatedat TIMESTAMP
);
CREATE TABLE buildings
(
  building_id INT PRIMARY KEY NOT NULL,
  building_subtype VARCHAR(100) NOT NULL,
  building_name VARCHAR(50)
);
CREATE TABLE buildingsubtype
(
  name VARCHAR(100) PRIMARY KEY NOT NULL,
  super_type VARCHAR(50) NOT NULL
);
CREATE TABLE buildingtype
(
  name VARCHAR(50) PRIMARY KEY NOT NULL
);
CREATE TABLE districts
(
  zip_code INT PRIMARY KEY NOT NULL,
  district_name VARCHAR(50) NOT NULL
);
CREATE TABLE log_table
(
  errorid INT NOT NULL,
  description VARCHAR(255)
);
CREATE TABLE measurementseries
(
  measurement_serie_id SERIAL PRIMARY KEY NOT NULL
);
CREATE TABLE measurementseries_measurement_serie_id_seq
(
  sequence_name VARCHAR NOT NULL,
  last_value BIGINT NOT NULL,
  start_value BIGINT NOT NULL,
  increment_by BIGINT NOT NULL,
  max_value BIGINT NOT NULL,
  min_value BIGINT NOT NULL,
  cache_value BIGINT NOT NULL,
  log_cnt BIGINT NOT NULL,
  is_cycled BOOL NOT NULL,
  is_called BOOL NOT NULL
);
CREATE TABLE meter
(
  installation_nbr VARCHAR(50) NOT NULL,
  meter_nbr VARCHAR(50) NOT NULL,
  building INT NOT NULL,
  meter_type VARCHAR(30) NOT NULL,
  isbillingmeter BOOL,
  description VARCHAR(100),
  measurement_serie_id INT,
  PRIMARY KEY (installation_nbr, meter_nbr)
);
CREATE TABLE metertype
(
  name VARCHAR(30) PRIMARY KEY NOT NULL,
  meter_unit VARCHAR(10)
);
CREATE TABLE observationmeasurement
(
  obs_type INT,
  obs_val REAL
);
CREATE TABLE observations
(
  measurement_id INT NOT NULL,
  obs_val REAL NOT NULL,
  obs_type INT NOT NULL,
  PRIMARY KEY (measurement_id, obs_type)
);
CREATE TABLE observationtimes
(
  measurement_serie_id INT NOT NULL,
  start_time TIMESTAMP NOT NULL,
  measurement_id SERIAL PRIMARY KEY NOT NULL,
  end_time TIMESTAMP
);
CREATE TABLE observationtimes_measurement_id_seq
(
  sequence_name VARCHAR NOT NULL,
  last_value BIGINT NOT NULL,
  start_value BIGINT NOT NULL,
  increment_by BIGINT NOT NULL,
  max_value BIGINT NOT NULL,
  min_value BIGINT NOT NULL,
  cache_value BIGINT NOT NULL,
  log_cnt BIGINT NOT NULL,
  is_cycled BOOL NOT NULL,
  is_called BOOL NOT NULL
);
CREATE TABLE observationtypes
(
  type_id SERIAL PRIMARY KEY NOT NULL,
  type_name VARCHAR(30) NOT NULL
);
CREATE TABLE observationtypes_type_id_seq
(
  sequence_name VARCHAR NOT NULL,
  last_value BIGINT NOT NULL,
  start_value BIGINT NOT NULL,
  increment_by BIGINT NOT NULL,
  max_value BIGINT NOT NULL,
  min_value BIGINT NOT NULL,
  cache_value BIGINT NOT NULL,
  log_cnt BIGINT NOT NULL,
  is_cycled BOOL NOT NULL,
  is_called BOOL NOT NULL
);
CREATE TABLE tempfoundedseries
(
  building BIGINT,
  measurement_serie_id INT
);

CREATE TABLE v_lastesmeasure
(
  end_time TIMESTAMP,
  obs_val REAL,
  obs_type INT,
  meter_nbr VARCHAR(50),
  installation_nbr VARCHAR(50)
);
CREATE TABLE w_alarms_odd_consumption
(
  obstype INT NOT NULL,
  building INT NOT NULL,
  raiseddate TIMESTAMP,
  handleddate TIMESTAMP,
  odddate TIMESTAMP NOT NULL,
  expectedvalues _NUMERIC,
  observedvalues _NUMERIC,
  sds _NUMERIC,
  oddfeatures _NUMERIC,
  likelihood NUMERIC(131089),
  PRIMARY KEY (obstype, building, odddate)
);
CREATE TABLE w_building_profiles
(
  building INT,
  consumption_type INT,
  dataquality INT,
  mean _NUMERIC,
  sd _NUMERIC
);
CREATE TABLE w_consumption_profiles
(
  building INT,
  consumption_type INT,
  profilenbr INT,
  mean _NUMERIC,
  sd _NUMERIC,
  daycount _INT4
);
CREATE TABLE w_consumptions
(
  building_id INT NOT NULL,
  consumption_type INT NOT NULL,
  consumption _NUMERIC,
  PRIMARY KEY (building_id, consumption_type)
);
CREATE TABLE w_feature
(
  feature_type INT,
  consumption_type INT,
  building INT,
  feature_data _NUMERIC
);
CREATE TABLE w_feature_type
(
  id INT PRIMARY KEY NOT NULL,
  name VARCHAR(50)
);
CREATE TABLE w_lookup_building
(
  building_id INT,
  building_name VARCHAR(50),
  sub_type VARCHAR(100),
  super_type VARCHAR(50),
  street VARCHAR(100),
  zip_code INT,
  built_area INT,
  building_area INT,
  heated_area INT,
  total_area INT,
  attic INT,
  cellar_area INT,
  total_residence INT,
  site_area INT,
  validatedat TIMESTAMP,
  district_name VARCHAR(50),
  ranking INT,
  data_quality BIGINT
);
CREATE TABLE w_lookup_consumptions
(
  building_id INT,
  consumption_type VARCHAR(20),
  consumption _NUMERIC,
  start_time TIMESTAMP,
  end_time TIMESTAMP
);
CREATE TABLE w_settings
(
  settingkey CHAR(50),
  settingvalue VARCHAR(1023)
);
CREATE TABLE w_simmilar
(
  building INT NOT NULL,
  consumption_type INT NOT NULL,
  simmilar _INT4,
  PRIMARY KEY (building, consumption_type)
);
CREATE TABLE w_subtype_profiles
(
  subtype VARCHAR(50),
  consumption_type INT,
  mean _NUMERIC,
  sd _NUMERIC
);
ALTER TABLE bbr ADD FOREIGN KEY (building_id) REFERENCES buildings (building_id);
ALTER TABLE bbr ADD FOREIGN KEY (zip_code) REFERENCES districts (zip_code);
CREATE UNIQUE INDEX bbr_building_id_key ON bbr (building_id);
ALTER TABLE buildings ADD FOREIGN KEY (building_subtype) REFERENCES buildingsubtype (name);
ALTER TABLE buildings ADD FOREIGN KEY (building_subtype) REFERENCES buildingsubtype (name);
ALTER TABLE buildingsubtype ADD FOREIGN KEY (super_type) REFERENCES buildingtype (name);
ALTER TABLE meter ADD FOREIGN KEY (building) REFERENCES buildings (building_id);
ALTER TABLE meter ADD FOREIGN KEY (measurement_serie_id) REFERENCES measurementseries (measurement_serie_id);
ALTER TABLE meter ADD FOREIGN KEY (meter_type) REFERENCES metertype (name);
ALTER TABLE observations ADD FOREIGN KEY (measurement_id) REFERENCES observationtimes (measurement_id);
ALTER TABLE observations ADD FOREIGN KEY (obs_type) REFERENCES observationtypes (type_id);
CREATE INDEX observations_id ON observations (measurement_id);
CREATE INDEX observations_idtypeval ON observations (measurement_id, obs_type, obs_val);
CREATE INDEX observations_obstype ON observations (obs_type);
ALTER TABLE observationtimes ADD FOREIGN KEY (measurement_serie_id) REFERENCES measurementseries (measurement_serie_id);
CREATE INDEX observationstimes_id ON observationtimes (measurement_serie_id, start_time, end_time);
CREATE INDEX observationtimes_endtime ON observationtimes (end_time);
CREATE INDEX observationtimes_start ON observationtimes (start_time);
CREATE INDEX observationtimes_start_nulllast ON observationtimes (start_time);
ALTER TABLE w_alarms_odd_consumption ADD FOREIGN KEY (building) REFERENCES buildings (building_id);
ALTER TABLE w_alarms_odd_consumption ADD FOREIGN KEY (obstype) REFERENCES observationtypes (type_id);
ALTER TABLE w_building_profiles ADD FOREIGN KEY (building) REFERENCES buildings (building_id);
ALTER TABLE w_building_profiles ADD FOREIGN KEY (consumption_type) REFERENCES observationtypes (type_id);
ALTER TABLE w_consumption_profiles ADD FOREIGN KEY (building) REFERENCES buildings (building_id);
ALTER TABLE w_consumption_profiles ADD FOREIGN KEY (consumption_type) REFERENCES observationtypes (type_id);
ALTER TABLE w_consumptions ADD FOREIGN KEY (building_id) REFERENCES buildings (building_id);
ALTER TABLE w_consumptions ADD FOREIGN KEY (consumption_type) REFERENCES observationtypes (type_id);
ALTER TABLE w_feature ADD FOREIGN KEY (building) REFERENCES buildings (building_id);
ALTER TABLE w_feature ADD FOREIGN KEY (consumption_type) REFERENCES observationtypes (type_id);
ALTER TABLE w_feature ADD FOREIGN KEY (feature_type) REFERENCES w_feature_type (id);
ALTER TABLE w_lookup_consumptions ADD FOREIGN KEY (building_id) REFERENCES buildings (building_id);
ALTER TABLE w_simmilar ADD FOREIGN KEY (building) REFERENCES buildings (building_id);
ALTER TABLE w_simmilar ADD FOREIGN KEY (consumption_type) REFERENCES observationtypes (type_id);
ALTER TABLE w_subtype_profiles ADD FOREIGN KEY (subtype) REFERENCES buildingsubtype (name);
ALTER TABLE w_subtype_profiles ADD FOREIGN KEY (consumption_type) REFERENCES observationtypes (type_id);

CREATE OR REPLACE VIEW V_BuildingData as (
  SELECT a.address, c.name as superType, b.name as subType , a.id  
  FROM building a 
    LEFT OUTER JOIN buildingsubtype b 
      on a.type = b.name 
    LEFT OUTER JOIN buildingtype c
      on b.super_type = c.name
);


CREATE or REPLACE VIEW V_v_MeterData AS(
  Select m.description, m.meter_nbr, m.installation_nbr, mt.name as type, b.building_id as building from meter m
    LEFT OUTER JOIN metertype mt on m.meter_type = mt.name
    LEFT OUTER JOIN buildings b on m.building=b.building_id
);

CREATE OR REPLACE VIEW V_MeterMeasurements as(
  SELECT m.installation_nbr, m.meter_nbr, mm.observationtime, mm.measurement
  from
    measurementseries ms LEFT JOIN
    meter m on ms.v_MeterDataid = m.v_MeterDataid LEFT JOIN
    metermeasurements mm on ms.v_MeterDataid = mm.v_MeterDataid
);

CREATE or REPLACE VIEW v_bbrInformation as (
    select 
      br.building_id, 
      br.street, 
      br.zip_code,
      d.district_name,
      br.built_area,
      br.building_area,
      br.heated_area, 
      br.total_area, 
      br.attic, 
      br.cellar_area, 
      br.total_residence,
      br.site_area 
    from bbr br LEFT OUTER JOIN 
        districts d on br.zip_code = d.zip_code
);


create or REPLACE view V_ObservationsOnBuilding as
select m.building as "Building Id", m.installation_nbr || ' : ' || m.meter_nbr as "Meter Id", m.meter_type as "Meter type", 
  m.isbillingmeter as "Is billing meter", 
  ot.start_time as "Start Time", 
  ot.end_time as "End Time", 
  obs_val as "Observation Value", 
  obst.type_name as "Observation Type"
from meter m LEFT JOIN 
     observationtimes ot ON m.measurement_serie_id= ot.measurement_serie_id  LEFT JOIN 
     observations obs on ot.measurement_id = obs.measurement_id LEFT JOIN 
     observationtypes obst on obst.type_id = obs.obs_type;


CREATE or REPLACE FUNCTION insert_buildingdata() RETURNS TRIGGER AS
  $BuildingData_ins$
    BEGIN
      INSERT INTO BuildingType (name) SELECT new.superType where not EXISTS(
          SELECT 1 FROM BuildingType where name = new.superType);

      INSERT INTO BuildingSubType (name, super_type) SELECT new.subType, new.superType where not exists(
          select 1 from BuildingSubType where name=new.subType
      );
      update buildingsubtype set super_type = new.subType where name = new.subType;
      
      INSERT INTO  building (id, address, building_type) select new.id, new.address, new.subType where not exists(
          select 1 from building where id=new.id
      );
      update building set address = new.address, building_type = new.super_type where id = new.id;

      RETURN null;
    END;
$BuildingData_ins$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION v_MeterData_insert() RETURNS TRIGGER AS
  $v_MeterData_ins_trigger$
  BEGIN 
    INSERT INTO MeterType (name, meter_unit) select new.type, NULL WHERE not exists(
        select 1 from MeterType where name = new.type);
    
    UPDATE Meter SET building = new.building, meter_type = new.type, description = new.description
    WHERE installation_nbr = new.installation_nbr and meter_nbr = new.meter_nbr;
    
    INSERT INTO Meter (installation_nbr, meter_nbr, building, meter_type, description) 
      SELECT new.installation_nbr, new.meter_nbr, new.building, new.type,  new.description WHERE NOT exists(
          SELECT 1 FROM Meter WHERE installation_nbr = new.installation_nbr and meter_nbr = new.meter_nbr
        );
    
    RETURN null;
    EXCEPTION 
      WHEN SQLSTATE '23503' THEN 
        INSERT into log_table (ErrorId, description) VALUES(23503, new.description || ', ' || new.meter_nbr || ', ' || new.installation_nbr|| ', ' || new.type|| ', ' || new.building); 
        RETURN null;
  END; 
  $v_MeterData_ins_trigger$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION MeterMeasurement_insert() RETURNS TRIGGER AS
  $MeterMeasurement_ins_trigger$
  DECLARE 
    existingSeries integer;
    tempId INTEGER;
  BEGIN 
    SELECT v_MeterDataId INTO existingSeries from meter WHERE installation_nbr=new.installation_nbr and meter_nbr=new.meter_nbr;
    
    if existingSeries IS NOT NULL 
    THEN
      INSERT INTO MeterMeasurements (v_MeterDataid, observationtime, measurement) 
        VALUES(existingSeries, new.observationTime, new.measurement);
    ELSE 
      INSERT INTO measurementSeries (v_MeterDataName) VALUES (new.installation_nbr||','||new.meter_nbr) RETURNING v_MeterDataId INTO tempId;
      
      UPDATE Meter SET v_MeterDataId = tempId WHERE installation_nbr=new.installation_nbr and meter_nbr=new.meter_nbr;
      
      INSERT INTO MeterMeasurements (v_MeterDataId, observationTime, measurement) VALUES (tempId, new.observationTime, new.measurement);
    END IF;
    
    RETURN null;
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
    RETURN null;
  END; 
  $MeterMeasurement_ins_trigger$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION BBR_insert() RETURNS TRIGGER AS
  $BBR_ins_trigger$
  DECLARE
    existingDist VARCHAR(50);
  BEGIN 
    SELECT district_name INTO existingDist from districts WHERE zip_code=new.zip_code;
    
    IF (existingDist IS NULL)
    THEN
      INSERT INTO districts (zip_code, district_name) VALUES (new.zip_code, new.district_name);
      INSERT INTO BBR (building_id, street, zip_code, built_area, cellar_area, heated_area, attic, total_area, total_residence, site_area)
      VALUES(new.building_id, new.street, new.zip_code, new.built_area, new.cellar_area, new.heated_area, new.attic, new.total_area, new.total_residence, new.site_area);
    ELSE
      UPDATE districts set district_name = new.district_name where zip_code = new.zip_code;
      INSERT INTO BBR (building_id, street, zip_code, built_area, cellar_area, heated_area, attic, total_area, total_residence, site_area)
      VALUES(new.building_id, new.street, new.zip_code, new.built_area, new.cellar_area, new.heated_area, new.attic, new.total_area, new.total_residence, new.site_area);
    END IF;
    
    RETURN null;
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
      INSERT INTO districts (zip_code, district_name) VALUES (new.zip_code, new.district_name);
      INSERT INTO BBR (building_id, street, zip_code, built_area, cellar_area, heated_area, attic, total_area, total_residence, site_area)
      VALUES(new.building_id, new.street, new.zip_code, new.built_area, new.cellar_area, new.heated_area, new.attic, new.total_area, new.total_residence, new.site_area);
      RETURN null;
    WHEN SQLSTATE = '23503' THEN
      RETURN NULL;
  END; 
  $BBR_ins_trigger$
LANGUAGE plpgsql;


CREATE TRIGGER BuildingData_ins INSTEAD OF INSERT ON V_BuildingData
FOR EACH ROW
EXECUTE PROCEDURE insert_buildingdata();

CREATE TRIGGER v_MeterData_ins_trigger INSTEAD OF INSERT ON V_v_MeterData
FOR EACH ROW 
  EXECUTE PROCEDURE v_MeterData_insert();
;

CREATE TRIGGER MeterMeasurement_ins INSTEAD OF INSERT ON V_MeterMeasurements
  FOR EACH ROW 
  EXECUTE PROCEDURE MeterMeasurement_insert();
  ;


CREATE TRIGGER bbr_ins INSTEAD OF INSERT ON v_bbrinformation
FOR EACH ROW
EXECUTE PROCEDURE bbr_insert();
;



insert into observationtypes (type_name) VALUES ('energy');
insert into observationtypes (type_name) VALUES ('energy_meter');
insert into observationtypes (type_name) VALUES ('in_temp');
insert into observationtypes (type_name) VALUES ('out_temp');
insert into observationtypes (type_name) VALUES ('flow');
insert into observationtypes (type_name) VALUES ('flow_meter');
insert into observationtypes (type_name) VALUES ('electricity');
insert into observationtypes (type_name) VALUES ('water');



---------------------TESTING:
create type observationmeasurement as (obs_type int, obs_val real );


CREATE OR REPLACE FUNCTION observationCleanUp() RETURNS VOID AS 
$cleanup$ 
DECLARE 
  rec RECORD; 
  previous INT; 
  mod2 int; 
  deleteIds int[]; 
BEGIN
  mod2 := 0; 
  deleteIds[1] := 0;
  
  FOR rec in SELECT ot.measurement_id 
        FROM observationtimes ot INNER JOIN 
          (SELECT measurement_serie_id, start_time, end_time 
            FROM observationtimes 
            GROUP BY measurement_serie_id, start_time, end_time 
            HAVING (COUNT(measurement_serie_id) > 1)) 
          AS duplets ON ot.measurement_serie_id=duplets.measurement_serie_id and 
                  ot.start_time = duplets.start_time and 
                  ot.end_time= duplets.end_time 
        order by ot.measurement_serie_id, 
             ot.start_time, 
             ot.end_time 
  
  LOOP
      IF mod2 = 1 THEN 
        IF previous> rec.measurement_id THEN
  
          update observations o1 
          set obs_val= ( select o2.obs_val 
                  from observations o2 
                  where o2.measurement_id = previous and 
                      o2.obs_type=o1.obs_type) 
          where o1.measurement_id = rec.measurement_id and 
              o1.obs_type = (select o2.obs_type 
                        from observations o2 
                        where o2.measurement_id = previous and 
                            o2.obs_type = o1.obs_type);
          deleteIds := array_append(deleteIds, previous); 
        ELSE 
          update observations o1 
          set obs_val= ( select o2.obs_val 
                  from observations o2 
                  where o2.measurement_id = rec.measurement_id and 
                      o2.obs_type=o1.obs_type) 
          where o1.measurement_id = previous and 
              o1.obs_type = (select o2.obs_type 
                        from observations o2 
                        where o2.measurement_id = rec.measurement_id and 
                            o2.obs_type = o1.obs_type);
        deleteIds := array_append(deleteIds, rec.measurement_id); 
      END IF; 
    END IF;
    previous:= rec.measurement_id; mod2:= (mod2 + 1) % 2; END LOOP;
  
      DELETE FROM observations where measurement_id = ANY (deleteIds); 
      DELETE FROM observationtimes WHERE measurement_id = ANY (deleteIds); 
  END; 
$cleanup$ 
LANGUAGE PLPGSQL;


--

drop view w_building_lookup;
create or REPLACE view w_lookup_building as
  select b.building_id,
    b.building_name ,
    bs.name as sub_type,
    bs.super_type,
    bbr.street,
    bbr.zip_code,
    bbr.built_area,
    bbr.building_area,
    bbr.heated_area,
    bbr.total_area,
    bbr.attic,
    bbr.cellar_area,
    bbr.total_residence,
    bbr.site_area,
    bbr.validatedAt,
    dist.district_name,
    (random()*100)::INT as ranking,
    wbp.dataquality as data_quality
  from buildings b
    INNER JOIN
    buildingsubtype bs on b.building_subtype = bs.name
    INNER JOIN
    bbr bbr ON b.building_id = bbr.building_id
    INNER JOIN
    districts dist on bbr.zip_code = dist.zip_code
    LEFT OUTER JOIN 
    (select 
      (sum(wb.dataquality)/count(wb.consumption_type)) as dataquality,
       wb.building 
    from w_building_profiles wb 
    GROUP BY wb.building) wbp
    on b.building_id=wbp.building;




create table w_lookup_consumptions(
  building_id integer NOT NULL,
  consumption_type VARCHAR(20) not null,
  consumption real[] not NULL 
);
alter TABLE w_lookup_consumptions add PRIMARY KEY(building_id, consumption_type);
ALTER TABLE w_lookup_consumptions add FOREIGN KEY (building_id) REFERENCES buildings(building_id);
alter table w_consumptions add PRIMARY KEY (building_id, consumption_type);


create INDEX observationtimes_start on observationtimes USING BTREE (start_time);
CREATE INDEX observationtimes_start_nullLast ON observationtimes (start_time NULLS first);
create INDEX observationtimes_endtime on observationtimes USING BTREE (end_time);
create INDEX observations_obstype on observations USING BTREE (obs_type);
CREATE index observations_id on observations USING BTREE (measurement_id);
CREATE index observations_idtypeval on observations USING BTREE (measurement_id, obs_type, obs_val);
create index observationstimes_id on observationtimes USING BTREE (measurement_serie_id, start_time, end_time);



