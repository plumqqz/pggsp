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
  ok boolean;
  error text;
  sqlst text;
  pr record;
begin
    if GSP.is_node_ready() then
        return;
    end if;
    
    select max(height) into mh from GSP.blockchain;
    --select * into p from GSP.peer order by height desc nulls last limit 1;
    -- find first live peer
    for pr in select * from GSP.peer order by height desc nulls last limit 20 loop
      begin
        CREATE_DBLINK(pr.cn);
        perform dblink(get_connection_name(p.cn),'select 1');
        p=pr;
        exit;
      exception
       when sqlstate '08000' then continue;
      end; 
    end loop;
    
    if not found then
      raise sqlstate 'XY011' using message='No peers found';
    end if;

    if p.height is null then
      return;
    end if;
    
    begin
        ok=false;
        CREATE_DBLINK(p.cn);
        for i in coalesce(mh,-1)+1..p.height loop
            select dbl.res into reply from dblink(get_connection_name(p.cn), format('select %I.reply_blockchain_block(%L)',p.schema_name,i)) as dbl(res json);
            bb:=json_populate_record(null::GSP.blockchain, reply);
            perform GSP.accept_proposed_block(reply);
            -- note stripping 0x for bytea value in json below
            perform GSP.append_proposed_block_to_blockchain(decode(substring(reply->>'hash' from 3), 'hex')); 
        end loop;
        ok=true;
    exception
        when sqlstate '08000' then raise;
        when others then 
            ok=false;
            error=sqlerrm;
            sqlst = sqlstate;
            raise notice 'Handle error:% %', sqlst, error;
      end;
      if not ok then
        if error ~* 'deadlock' then
            raise sqlstate '40P01' using message='sync_blockchain:Remote deadlock';
        elsif error ~* 'current transaction is aborted' 
              or error ~* 'statement timeout'
        then
            raise sqlstate '57014' using message='sync_blockchain:Remote timeout';
        else 
            raise sqlstate 'XY004' using message='sync_blockchain:Remote:' || error, hint=sqlst;
        end if;
      end if;   
    
end;
$code$
language plpgsql;