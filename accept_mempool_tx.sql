#include "gossip.h"

create or replace function GSP.accept_mempool_tx(jtx json) returns text as
$code$
  declare
    vtx GSP.mempool_txs = json_populate_record(null::GSP.mempool_txs,jtx);
  begin
    if not GSP.is_valid_tx_signature(vtx) then
       raise sqlstate 'XY005' using message='Invalid signature';
       return 'INVALID-SIGNATURE';
    end if;
    if not GSP.self_ref()=any(vtx.seenby) then
      vtx.seenby = vtx.seenby||GSP.self_ref();
    end if;
    insert into GSP.mempool_txs select vtx.* on conflict(tx)
        do update set seenby=array(select v from unnest(excluded.seenby) as u(v) union select v from unnest(mempool_txs.seenby) u(v));
    return 'OK';
  end;
$code$
language plpgsql