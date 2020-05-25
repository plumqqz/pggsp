#include "gossip.h"

create or replace function GSP.cleanup(jid bigint) returns void as
$code$
begin
    perform jb.cleanup();
    perform jb.set_next_run_after(jid, make_interval(secs:=5));
end;    
$code$
language plpgsql;