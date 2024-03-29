#include "gossip.h"

create or replace function GSP.block_gossip_one(peer_ref text) returns void as
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
          ok=false;
          for rd in select * from GSP.proposed_block pbs where not r.ref=any(pbs.seenby) loop
               select dbl.res into res from dblink(get_connection_name(r.cn), format('select %I.accept_proposed_block(%L)',r.schema_name, to_json(rd))) as dbl(res text);
               if res<>'OK' then
                  raise notice '%', format('Cannot send to %s:%s', r.ref, res);
                  continue;
               end if;
               update GSP.proposed_block pbs set seenby=array(select v from unnest(pbs.seenby) as u(v) union select r.ref) where pbs.hash=rd.hash;
          end loop;
          ok=true;
      exception
        when sqlstate '08000' then raise;
        when others then 
            ok=false;
            error=sqlerrm;
            sqlst = sqlstate;
            raise notice '%', format(GSPSTR||':block_gossip:Handle error:%s %s', sqlst, error);
      end;
      if not ok then
        if error ~* 'deadlock' then
            raise sqlstate '40P01' using message=GSPSTR||':block_gossip:Remote deadlock';
        elsif error ~* 'current transaction is aborted'
              or error ~* 'statement timeout'
        then
            raise sqlstate '57014' using message=GSPSTR||':block_gossip:Remote timeout';
        else
            raise sqlstate 'XY004' using message=GSPSTR||':block_gossip:Remote:' || error, hint=sqlst;
        end if;
      end if;
     end loop;
 end
$code$
language plpgsql
set enable_seqscan to off;

create or replace function GSP.block_gossip() returns void as
$code$
 select GSP.block_gossip_one(ref) from GSP.peer;
$code$
language sql;