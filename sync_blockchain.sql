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
begin
    if GSP.is_node_ready() then
        return;
    end if;
    select max(height) into mh from GSP.blockchain;
    select * into p from GSP.peer order by height desc nulls last limit 1;
    if not found then
      raise sqlstate 'XY011' using message='No peers found';
    end if;

    if p.height is null then
      return;
    end if;
    
    begin
        ok=false;
        CREATE_DBLINK(p.cn);
        perform dblink_exec(get_connection_name(p.cn),'begin transaction');
        for i in coalesce(mh,-1)+1..p.height loop
            select dbl.res into reply from dblink(get_connection_name(p.cn), format('select %I.reply_blockchain_block(%L)',p.schema_name,i)) as dbl(res json);
            bb:=json_populate_record(null::GSP.blockchain, reply);
            perform GSP.accept_proposed_block(reply);
            perform GSP.append_proposed_block_to_blockchain(decode(substring(reply->>'hash' from 3), 'hex'));
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
        perform dblink_exec(get_connection_name(p.cn),'commit');
      else
        perform dblink_exec(get_connection_name(p.cn),'rollback');
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