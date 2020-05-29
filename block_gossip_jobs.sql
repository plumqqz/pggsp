#include "gossip.h"

create or replace function GSP.block_gossip_jobs(jid bigint) returns void as
$code$
declare
 r record;
 begin
   for r in select * from GSP.peer loop
     if not exists(select * 
                     from jb.job j 
                    where j.function_name=GSPSTR||'.block_gossip_job' 
                      and params->>'ref'=r.ref                    
                      and not j.is_done and not j.is_failed) 
     then
       perform jb.submit(GSPSTR||'.block_gossip_job', jsonb_build_object('ref', r.ref, 'src', GSPSTR));
     end if;
   end loop;
   perform jb.set_next_run_after(jid, make_interval(secs:=5));
 end;
$code$
language plpgsql;

create or replace function GSP.block_gossip_job(jid bigint) returns void as
$code$
   begin
      perform GSP.block_gossip_one((select params->>'ref' from jb.job j where id=jid));
   exception
    when sqlstate '08000' then perform jb.set_next_run_after(jid, make_interval(secs:=30)); -- client errpr
    when sqlstate '40P01' then perform jb.set_next_run_after(jid, make_interval(secs:=5)); -- deadlock
    when sqlstate '57014' then 
        perform jb.set_next_run_after(jid, make_interval(secs:=5)); -- statement timeout
        raise notice 'block_gossip_job:Statement timeout';
end;
$code$
language plpgsql
set statement_timeout to 10000;