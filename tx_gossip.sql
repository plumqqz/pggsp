#include "gossip.h"

create or replace function GSP.tx_gossip() returns void as
$code$
declare
 r record;
 rd record;
 ok boolean;
 error text;
 sqlst text;
 begin
     for r in select * from GSP.peer loop
      CREATE_DBLINK(r.cn);
      begin
      perform dblink_exec(get_connection_name(r.cn),'begin');
      ok=false;
      for rd in select * from GSP.mempool_txs txs where not r.ref =any(txs.seenby) loop
           perform * from dblink(get_connection_name(r.cn), format('select %I.accept_mempool_tx(%L)',r.schema_name, to_json(rd))) as dbl(res text);
           update GSP.mempool_txs txs set seenby=array(select v from unnest(txs.seenby) as u(v) union select r.ref) where txs.tx=rd.tx;
      end loop;
      ok=true;
      exception
        when others then 
            ok=false;
            error=sqlerrm;
            sqlst = sqlstate;
            raise notice 'Handle error:% %', sqlst, error;
      end;
      if ok then
        perform dblink_exec(get_connection_name(r.cn),'commit');
      else
        perform dblink_exec(get_connection_name(r.cn),'rollback');
        raise sqlstate 'XY004' using message='Remote:' || error, hint=sqlst;
      end if;
     end loop;
 end
$code$
language plpgsql;