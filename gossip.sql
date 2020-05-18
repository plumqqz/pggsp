#include "gossip.h"

create or replace function GSP.gossip() returns void as
$code$
declare
 r record;
 rd record;
 begin
     for r in select * from GSP.peer loop
      for rd in select * from GSP.txs where not r.ref =any(data.seenby) loop
           perform dblink_exec(cn, format('insert into gsp.data(tx, payload, seenby) values(%L,%L,%L)',
           rd.tx, rd.payload, rd.seenby||'self'));
           update gsp2.txs set seenby=seenby||case when is_self_seen_set then array[r.ref] else array[r.ref,'self'] end
            where txs.tx=rd.tx;
      end loop;
     end loop;
 end
$code$
language plpgsql;