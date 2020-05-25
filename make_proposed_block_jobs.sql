#include "gossip.h"

create or replace function GSP.make_proposed_block_jobs(jid bigint) returns void as
$code$
 begin
   perform GSP.make_proposed_block();
   perform jb.set_next_run_after(jid, make_interval(secs:=20));
end;
$code$
language plpgsql;

