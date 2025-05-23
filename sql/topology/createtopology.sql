/*PGR-GNU*****************************************************************

Copyright (c) 2015 pgRouting developers
Author: Christian Gonzalez
Author: Stephen Woodbridge <woodbri@imaptools.com>
Author: Vicky Vergara <vicky_vergara@hotmail,com>
Mail: project@pgrouting.org

------

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

 ********************************************************************PGR-GNU*/

/*
.. function:: _pgr_createtopology(edge_table, tolerance,the_geom,id,source,target,rows_where)

Based on the geometry:
Fill the source and target column for all lines.
All line end points within a distance less than tolerance, are assigned the same id

Author: Christian Gonzalez <christian.gonzalez@sigis.com.ve>
Author: Stephen Woodbridge <woodbri@imaptools.com>
Modified by: Vicky Vergara <vicky_vergara@hotmail,com>

HISTORY
Last changes: 2013-03-22
2013-08-19:  handling schemas
2014-july: fixes issue 211
*/

---------------
---------------
-- topology
---------------
---------------


-----------------------
-- pgr_createtopology
-----------------------


--v2.6
CREATE FUNCTION pgr_createTopology(
    TEXT, -- edge table (required)
    double precision, -- tolerance (required)
    the_geom TEXT default 'the_geom',
    id TEXT default 'id',
    source TEXT default 'source',
    target TEXT default 'target',
    rows_where TEXT default 'true',
    clean boolean default FALSE)
RETURNS VARCHAR AS
$BODY$

DECLARE
    edge_table TEXT := $1;
    tolerance FLOAT := $2;
    points record;
    sridinfo record;
    source_id BIGINT;
    target_id BIGINT;
    totcount BIGINT;
    rowcount BIGINT;
    srid INTEGER;
    sql TEXT;
    sname TEXT;
    tname TEXT;
    tabname TEXT;
    vname TEXT;
    vertname TEXT;
    gname TEXT;
    idname TEXT;
    sourcename TEXT;
    targetname TEXT;
    notincluded INTEGER;
    i INTEGER;
    naming record;
    info record;
    flag boolean;
    query TEXT;
    idtype TEXT;
    gtype TEXT;
    sourcetype TEXT;
    targettype TEXT;
    debuglevel TEXT;
    dummyRec record;
    fnName TEXT;
    err bool;
    msgKind int;
    emptied BOOLEAN;

BEGIN
    msgKind = 1; -- notice
    RAISE WARNING 'pgr_createtopology(text,double precision,text,text,text,text,text,boolean) deprecated function on v3.8.0';
    fnName = 'pgr_createTopology';
    RAISE notice 'PROCESSING:';
    RAISE notice 'pgr_createTopology(''%'', %, ''%'', ''%'', ''%'', ''%'', rows_where := ''%'', clean := %)',edge_table,tolerance,the_geom,id,source,target,rows_where, clean;
    EXECUTE 'show client_min_messages' INTO debuglevel;


    RAISE notice 'Performing checks, please wait .....';

        EXECUTE 'SELECT sname, tname FROM _pgr_getTableName('|| quote_literal(edge_table)
                                                  || ',2,' || quote_literal(fnName) ||' )' INTO naming;
        sname=naming.sname;
        tname=naming.tname;
        tabname=sname||'.'||tname;
        vname=tname||'_vertices_pgr';
        vertname= sname||'.'||vname;
        rows_where = ' AND ('||rows_where||')';
      RAISE DEBUG '     --> OK';


      RAISE debug 'Checking column names in edge table';
        SELECT _pgr_getColumnName INTO idname     FROM _pgr_getColumnName(sname, tname,id,2,fnName);
        SELECT _pgr_getColumnName INTO sourcename FROM _pgr_getColumnName(sname, tname,source,2,fnName);
        SELECT _pgr_getColumnName INTO targetname FROM _pgr_getColumnName(sname, tname,target,2,fnName);
        SELECT _pgr_getColumnName INTO gname      FROM _pgr_getColumnName(sname, tname,the_geom,2,fnName);


        err = sourcename in (targetname,idname,gname) OR  targetname in (idname,gname) OR idname=gname;
        perform _pgr_onError( err, 2, fnName,
               'Two columns share the same name', 'Parameter names for id,the_geom,source and target  must be different',
	       'Column names are OK');

      RAISE DEBUG '     --> OK';

      RAISE debug 'Checking column types in edge table';
        SELECT _pgr_getColumnType INTO sourcetype FROM _pgr_getColumnType(sname,tname,sourcename,1, fnName);
        SELECT _pgr_getColumnType INTO targettype FROM _pgr_getColumnType(sname,tname,targetname,1, fnName);
        SELECT _pgr_getColumnType INTO idtype FROM _pgr_getColumnType(sname,tname,idname,1, fnName);

        err = idtype NOT in('integer','smallint','bigint');
        perform _pgr_onError(err, 2, fnName,
	       'Wrong type of Column id:'|| idname, ' Expected type of '|| idname || ' is integer,smallint or bigint but '||idtype||' was found');

        err = sourcetype NOT in('integer','smallint','bigint');
        perform _pgr_onError(err, 2, fnName,
	       'Wrong type of Column source:'|| sourcename, ' Expected type of '|| sourcename || ' is integer,smallint or bigint but '||sourcetype||' was found');

        err = targettype NOT in('integer','smallint','bigint');
        perform _pgr_onError(err, 2, fnName,
	       'Wrong type of Column target:'|| targetname, ' Expected type of '|| targetname || ' is integer,smallint or bigint but '||targettype||' was found');

      RAISE DEBUG '     --> OK';

      RAISE debug 'Checking SRID of geometry column';
         query= 'SELECT ST_SRID(' || quote_ident(gname) || ') AS srid '
            || ' FROM ' || _pgr_quote_ident(tabname)
            || ' WHERE ' || quote_ident(gname)
            || ' IS NOT NULL LIMIT 1';
         RAISE debug '%',query;
         EXECUTE query INTO sridinfo;

         err =  sridinfo IS NULL OR sridinfo.srid IS NULL;
         perform _pgr_onError(err, 2, fnName,
	     'Can not determine the srid of the geometry '|| gname ||' in table '||tabname, 'Check the geometry of column '||gname);

         srid := sridinfo.srid;
      RAISE DEBUG '     --> OK';

      RAISE debug 'Checking and creating indices in edge table';
        perform _pgr_createIndex(sname, tname , idname , 'btree'::TEXT);
        perform _pgr_createIndex(sname, tname , sourcename , 'btree'::TEXT);
        perform _pgr_createIndex(sname, tname , targetname , 'btree'::TEXT);
        perform _pgr_createIndex(sname, tname , gname , 'gist'::TEXT);

        gname=quote_ident(gname);
        idname=quote_ident(idname);
        sourcename=quote_ident(sourcename);
        targetname=quote_ident(targetname);
      RAISE DEBUG '     --> OK';





    BEGIN
        -- issue #193 & issue #210 & #213
        -- this sql is for trying out the where clause
        -- the select * is to avoid any column name conflicts
        -- limit 1, just try on first record
        -- if the where clasuse is ill formed it will be caught in the exception
        sql = 'SELECT '||idname ||','|| sourcename ||','|| targetname ||','|| gname || ' FROM '||_pgr_quote_ident(tabname)||' WHERE true'||rows_where ||' limit 1';
        EXECUTE sql INTO dummyRec;
        -- end

        -- if above where clasue works this one should work
        -- any error will be caught by the exception also
        sql = 'SELECT count(*) FROM '||_pgr_quote_ident(tabname)||' WHERE (' || gname || ' IS NOT NULL AND '||
	    idname||' IS NOT NULL)=false '||rows_where;
        EXECUTE SQL  INTO notincluded;

        if clean then
            RAISE debug 'Cleaning previous Topology ';
               EXECUTE 'UPDATE ' || _pgr_quote_ident(tabname) ||
               ' SET '||sourcename||' = NULL,'||targetname||' = NULL';
        else
            RAISE debug 'Creating topology for edges with non assigned topology';
            if rows_where=' AND (true)' then
                rows_where=  ' AND ('||quote_ident(sourcename)||' is NULL OR '||quote_ident(targetname)||' is  NULL)';
            end if;
        end if;
        -- my thoery is that the select Count(*) will never go through here
        EXCEPTION WHEN OTHERS THEN
             RAISE NOTICE 'Got %', SQLERRM; -- issue 210,211
             RAISE NOTICE 'ERROR: Condition is not correct, please execute the following query to test your condition';
             RAISE NOTICE '%',sql;
             RETURN 'FAIL';
    END;

    BEGIN
         RAISE DEBUG 'initializing %',vertname;
         EXECUTE 'SELECT sname, tname FROM _pgr_getTableName('||quote_literal(vertname)
                                                  || ',0,' || quote_literal(fnName) ||' )' INTO naming;
         emptied = false;
         set client_min_messages  to warning;
         IF sname=naming.sname AND vname=naming.tname  THEN
            if clean then
                EXECUTE 'TRUNCATE TABLE '||_pgr_quote_ident(vertname)||' RESTART IDENTITY';
                EXECUTE 'SELECT DROPGEOMETRYCOLUMN('||quote_literal(sname)||','||quote_literal(vname)||','||quote_literal('the_geom')||')';
                emptied = true;
            end if;
         ELSE -- table doesn't exist
            EXECUTE 'CREATE TABLE '||_pgr_quote_ident(vertname)||' (id bigserial PRIMARY KEY,cnt integer,chk integer,ein integer,eout integer)';
            emptied = true;
         END IF;
         IF (emptied) THEN
             EXECUTE 'SELECT addGeometryColumn('||quote_literal(sname)||','||quote_literal(vname)||','||
	         quote_literal('the_geom')||','|| srid||', '||quote_literal('POINT')||', 2)';
             perform _pgr_createIndex(vertname , 'the_geom'::TEXT , 'gist'::TEXT);
         END IF;
         EXECUTE 'SELECT _pgr_checkVertTab FROM  _pgr_checkVertTab('||quote_literal(vertname) ||', ''{"id"}''::TEXT[])' INTO naming;
         EXECUTE 'set client_min_messages  to '|| debuglevel;
         RAISE DEBUG  '  ------>OK';
         EXCEPTION WHEN OTHERS THEN
             RAISE NOTICE 'Got %', SQLERRM; -- issue 210,211
             RAISE NOTICE 'ERROR: something went wrong when initializing the verties table';
             RETURN 'FAIL';
    END;



    RAISE notice 'Creating Topology, Please wait...';
        rowcount := 0;
        FOR points IN EXECUTE 'SELECT ' || idname || '::BIGINT AS id,'
            || ' _pgr_StartPoint(' || gname || ') AS source,'
            || ' _pgr_EndPoint('   || gname || ') AS target'
            || ' FROM '  || _pgr_quote_ident(tabname)
            || ' WHERE ' || gname || ' IS NOT NULL AND ' || idname||' IS NOT NULL '||rows_where
        LOOP

            rowcount := rowcount + 1;
            IF rowcount % 1000 = 0 THEN
                RAISE NOTICE '% edges processed', rowcount;
            END IF;


            source_id := _pgr_pointToId(points.source, tolerance,vertname,srid);
            target_id := _pgr_pointToId(points.target, tolerance,vertname,srid);
            BEGIN
                sql := 'UPDATE ' || _pgr_quote_ident(tabname) ||
                    ' SET '||sourcename||' = '|| source_id::TEXT || ','||targetname||' = ' || target_id::TEXT ||
                    ' WHERE ' || idname || ' =  ' || points.id::TEXT;

                IF sql IS NULL THEN
                    RAISE NOTICE 'WARNING: UPDATE % SET source = %, target = % WHERE % = % ', tabname, source_id::TEXT, target_id::TEXT, idname,  points.id::TEXT;
                ELSE
                    EXECUTE sql;
                END IF;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE '%', SQLERRM;
                    RAISE NOTICE '%',sql;
                    RETURN 'FAIL';
            end;
        END LOOP;
        RAISE notice '-------------> TOPOLOGY CREATED FOR  % edges', rowcount;
        RAISE NOTICE 'Rows with NULL geometry or NULL id: %',notincluded;
        RAISE notice 'Vertices table for table % is: %',_pgr_quote_ident(tabname), _pgr_quote_ident(vertname);
        RAISE notice '----------------------------------------------';

    RETURN 'OK';
 EXCEPTION WHEN OTHERS THEN
   RAISE NOTICE 'Unexpected error %', SQLERRM; -- issue 210,211
   RETURN 'FAIL';
END;


$BODY$
LANGUAGE plpgsql VOLATILE STRICT;


-- COMMENTS


COMMENT ON FUNCTION pgr_createTopology(TEXT, FLOAT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN)
IS 'pgr_createTopology deprecated function on v3.8.0';
