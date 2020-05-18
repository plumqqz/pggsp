#include "gossip.h"

do $code$
declare
 r record;
 begin
  for r in 
   with gsp as(select * from information_schema.schemata s  where schema_name like 'gsp%')
    select g1.schema_name s1, g2.schema_name s2 from gsp g1, gsp g2 where g1.schema_name<>g2.schema_name
    and g1.schema_name=GSPSTR
    order by 1,2
  loop
    raise notice '% %', r.s1, r.s2;
    execute format('insert into %I.peer(ref, schema_name, cn) values($1,$2,$3)', r.s1)
      using r.s2, r.s2, 'host=localhost dbname=work port=15432 user=postgres password=root';
  end loop;
 end;
$code$;

do $code$
declare
 r record;
 v bytea[];
 pk bytea;
 sk bytea;
 begin
     v=ecdsa_make_key_raw(CURVE);
     pk=v[1];
     sk=v[2];
     raise notice 'SCHEMA=%', GSPSTR;
     execute format('insert into %I.node_keys(pk,sk) values($1,$2) on conflict do nothing', GSPSTR) using pk, sk;
 end;
$code$;