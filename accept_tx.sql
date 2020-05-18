#include "gossip.h"
drop function if exists GSP.accept_tx(json);
create or replace function GSP.accept_tx(jtx json) returns text as
$code$
  declare
    vtx GSP.txs = json_populate_record(null::GSP.txs,jtx);
  begin
    if not GSP.self_ref()=any(vtx.seenby) then
      vtx.seenby = vtx.seenby||GSP.self_ref();
    end if;
    insert into GSP.txs select vtx.* on conflict(tx)
        do update set seenby=array(select distinct v from unnest(excluded.seenby) as u(v));
    return 'OK';
  end;
$code$
language plpgsql