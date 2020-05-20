#include "gossip.h"

create or replace function GSP.is_node_ready() returns boolean as 
$code$
  select
    coalesce((select max(height) from GSP.blockchain),-1)>=coalesce((select max(height) from GSP.peer),0);
$code$
language sql;