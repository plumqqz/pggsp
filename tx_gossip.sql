#include "gossip.h"

create or replace function GSP.tx_gossip_one(peer_ref text) returns void as
$code$
declare
 r record;
 rd record;
 ok boolean;
 error text;
 sqlst text;
 res text;
 begin
     for r in select * from GSP.peer where peer.ref=peer_ref loop
      CREATE_DBLINK(r.cn);
      begin
      perform dblink_exec(get_connection_name(r.cn),'begin');
      ok=false;
      for rd in select * from GSP.mempool_txs txs where not r.ref =any(txs.seenby) loop
           select dbl.res into res from dblink(get_connection_name(r.cn), format('select %I.accept_mempool_tx(%L)',r.schema_name, to_json(rd))) as dbl(res text);
           if res<>'OK' then
              raise notice '%', format('Cannot send to %s:%s', r.ref, res);  
           end if;
           update GSP.mempool_txs txs set seenby=array(select v from unnest(txs.seenby) as u(v) union select r.ref) where txs.hash=rd.hash;
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
        if error ~ '(?:i)deadlock' then
            raise sqlstate '40P01' using message='Remote deadlock';
        else 
            raise sqlstate 'XY004' using message='Remote:' || error, hint=sqlst;
        end if;
      end if;
     end loop;
 end
$code$
language plpgsql;

create or replace function GSP.tx_gossip() returns void as
$code$
  select GSP.tx_gossip_one(ref) from GSP.peer;
$code$
language sql;
