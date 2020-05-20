#include "gossip.h"

create or replace function GSP.accept_mempool_tx(jtx json) returns text as
$code$
  declare
    vtx GSP.mempool_txs = json_populate_record(null::GSP.mempool_txs,jtx);
  begin
    assert jtx is not null, 'Passed tx json is null';
    if not GSP.is_valid_tx_signature(vtx) then
       raise sqlstate 'XY005' using message='Invalid signature';
    end if;
    if vtx.seenby is null then
       vtx.seenby=array[GSP.self_ref()]::text[];
    elsif not GSP.self_ref()=any(vtx.seenby) then
      vtx.seenby = vtx.seenby||GSP.self_ref();
    end if;
    if vtx.created_at is null then
      vtx.created_at=now();
    end if;
    insert into GSP.mempool_txs select vtx.* on conflict(hash)
        do update set seenby=array(select v from unnest(excluded.seenby) as u(v) union select v from unnest(mempool_txs.seenby) u(v));
    return 'OK';
  end;
$code$
language plpgsql