#include "gossip.h"

create or replace function GSP.find_block_and_vote_for_it_jobs(jid bigint) returns void as
$code$
 begin
   begin
        perform GSP.find_block_and_vote_for_it();
   exception
        when sqlstate '57014' then 
           perform jb.set_next_run_after(jid, make_interval(secs:=5)); -- statement timeout
           raise notice 'Statement timeout';
           return;
   end; 
   perform jb.set_next_run_after(jid, make_interval(secs:=10));
end;
$code$
language plpgsql
set statement_timeout to 10000;

