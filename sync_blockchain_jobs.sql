#include "gossip.h"

create or replace function GSP.sync_blockchain_jobs(jid bigint) returns void as
$code$
 begin
   begin
        perform GSP.sync_blockchain();
   exception
    when sqlstate '08000' then 
      raise notice '%', format('Get client error, sqlstate=%s error=%s', sqlstate, sqlerrm);
    when sqlstate '40P01' then 
        perform jb.set_next_run_after(jid, make_interval(secs:=5));
        return;
   end; 
   perform jb.set_next_run_after(jid, make_interval(secs:=7));
end;
$code$
language plpgsql;

