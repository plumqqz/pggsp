#include "gossip.h"

create or replace function GSP.ask_peer_height(ref text) returns void as
$code$
declare
 p constant GSP.peer:=(select p from GSP.peer p where p.ref=ask_peer_height.ref);
 hh bigint;
 ok boolean;
 error text;
 sqlst text;
 begin
   begin
      CREATE_DBLINK(p.cn);
      ok=false;
      select dbl.res into hh from dblink(get_connection_name(p.cn), format('select %I.reply_blockchain_height()',p.schema_name)) as dbl(res bigint);
      update GSP.peer set height=hh, last_accessed_at=clock_timestamp() where peer.ref=ask_peer_height.ref;
      ok=true;
      exception
        when others then 
            ok=false;
            error=sqlerrm;
            sqlst = sqlstate;
            raise notice 'Handle error:% %', sqlst, error;
      end;
      if not ok then
        if error ~* 'deadlock' then
            raise sqlstate '40P01' using message='Remote deadlock';
        elsif error ~* 'current transaction is aborted' then
            raise sqlstate '57014' using message='Remote timeout';
        else 
            raise sqlstate 'XY004' using message='Remote:' || error, hint=sqlst;
        end if;
      end if;   
 end;
$code$
language plpgsql;