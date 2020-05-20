do $code$
declare
 r record;
 begin
   for r in select * from information_schema.schemata s where s.schema_name like 'gsp%' loop
     execute format('select %1$I.ask_peer_height(p.ref) from %1$I.peer p', r.schema_name);
   end loop;
 end;
$code$;
