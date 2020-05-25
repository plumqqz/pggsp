#include "gossip.h"

create or replace function GSP.ask_peer_jobs(jid bigint) returns void as
$code$
declare
 r record;
 begin
   for r in select * from GSP.peer loop
     if not exists(select * 
                     from jb.job j 
                    where j.function_name=GSPSTR||'.ask_peer_job' 
                      and not j.is_done and not j.is_failed) 
     then
       perform jb.submit(GSPSTR||'.ask_peer_job', jsonb_build_object('ref', r.ref));
     end if;
   end loop;
   perform jb.set_next_run_after(jid, make_interval(secs:=25));
 end;
$code$
language plpgsql;

create or replace function GSP.ask_peer_job(jid bigint) returns void as
$code$
   begin
      perform GSP.ask_peer_height((select params->>'ref' from jb.job j where id=jid));
   exception
    when sqlstate '08000' then perform jb.set_next_run_after(jid, make_interval(secs:=25));
    when sqlstate '40P01' then perform jb.set_next_run_after(jid, make_interval(secs:=5));
end;
$code$
language plpgsql;