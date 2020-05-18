#include "gossip.h"

create or replace function GSP.tx_gossip() returns void as
$code$
declare
 r record;
 rd record;
 ok boolean;
 begin
     for r in select * from GSP.peer loop
      CREATE_DBLINK(r.cn);
      begin
      perform dblink_exec(get_connection_name(r.cn),'begin');
      ok=false;
      for rd in select * from GSP.mempool_txs where not r.ref =any(txs.seenby) loop
           perform * from dblink(get_connection_name(r.cn), format('select %I.accept_mempool_tx(%L)',r.schema_name, to_json(rd))) as dbl(res text);
           update GSP.mempool_txs txs set seenby=array(select v from unnest(txs.seenby) as u(v) union select r.ref) where txs.tx=rd.tx;
           ok=true;
      end loop;
      exception
        when others then ok=false;
      end;
      if ok then
        perform dblink_exec(get_connection_name(r.cn),'commit');
      else
        perform dblink_exec(get_connection_name(r.cn),'rollback');
      end if;
     end loop;
 end
$code$
language plpgsql;