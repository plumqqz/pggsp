#include "gossip.h"

create or replace function GSP.ask_peer_height(ref text) returns void as
$code$
declare
 p constant GSP.peer:=(select p from GSP.peer p where p.ref=ask_peer_height.ref);
 hh bigint;
 begin
   CREATE_DBLINK(p.cn);
   select dbl.res into hh from dblink(get_connection_name(p.cn), format('select %I.reply_blockchain_height()',p.schema_name)) as dbl(res bigint);
   update GSP.peer set height=hh, last_accessed_at=clock_timestamp() where peer.ref=ask_peer_height.ref;
 end;
$code$
language plpgsql;