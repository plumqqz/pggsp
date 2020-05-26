#include "gossip.h"

create or replace function GSP.is_node_ready() returns boolean as 
$code$
  select
    coalesce((select max(height) from GSP.blockchain),-1)>=coalesce((select max(height) from GSP.peer),0)
    and (clock_timestamp()-coalesce((select max(last_accessed_at) from GSP.peer),'1970-01-01'::timestamptz))
     <
    make_interval(secs:=30);
$code$
language sql;