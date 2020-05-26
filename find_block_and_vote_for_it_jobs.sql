#include "gossip.h"

create or replace function GSP.find_block_and_vote_for_it_jobs(jid bigint) returns void as
$code$
 begin
   begin
        perform GSP.find_block_and_vote_for_it();
   end; 
   perform jb.set_next_run_after(jid, make_interval(secs:=2));
end;
$code$
language plpgsql;

