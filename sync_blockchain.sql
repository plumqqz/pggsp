#include "gossip.h"

create or replace function GSP.sync_blockchain() returns void as
$code$
<<code>>
declare
  mh bigint;
  p GSP.peer;
  i bigint;
  bb GSP.blockchain;
  reply json;
begin
    if GSP.is_node_ready() then
        return;
    end if;
    select max(height) into mh from GSP.blockchain;
    select peer into p from GSP.peer order by height desc limit 1;
    CREATE_DBLINK(p.cn);

    for i in mh+1..p.height loop
        select dbl.res into reply from dblink(get_connection_name(p.cn), format('select %I.reply_blockchain_block(%L)',p.schema_name,i)) as dbl(res json);
        bb:=json_populate_record(null::GSP.blockchain, reply);
        perform GSP.accept_proposed_block_to_blockchain(bb);
    end loop;
end;
$code$
language plpgsql;