#include "gossip.h"

create or replace function GSP.make_proposed_block_jobs(jid bigint) returns void as
$code$
begin
   begin
       perform GSP.make_proposed_block();
       perform jb.set_next_run_after(jid, make_interval(secs:=10));
   exception
    when sqlstate '57014' then perform jb.set_next_run_after(jid, make_interval(secs:=5)); -- statement timeout
       perform jb.set_next_run_after(jid, make_interval(secs:=8));
       raise notice 'Statement timeout';
   end;
end;
$code$
language plpgsql
set statement_timeout to 10000;

