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
    if vtx.added_at is null then
       vtx.added_at = clock_timestamp();
    end if;
    
    if exists(select * from GSP.blockchain bc where array[vtx.hash] && GSP.get_hash_array(bc.txs)) then
       raise notice 'accept_mempool_tx:%:Tx % already in blockchain, skip it', GSPSTR, encode(vtx.hash,'hex');
    end if;

    if vtx.hash<>GSP.build_tx_hash(vtx) then
      raise notice 'passed hash=%', vtx.hash;
      raise notice 'calculated hash=%', int2bytea(extract(epoch from vtx.created_at)::int)||sha256(vtx.sender_public_key||vtx.payload);
      raise sqlstate 'XY020' using message='Tx hash is invalid';
    end if;
    insert into GSP.mempool_txs select vtx.* on conflict(hash)
        do update set seenby=array(select v from unnest(excluded.seenby) as u(v) union select v from unnest(mempool_txs.seenby) u(v));
    return 'OK';
  end;
$code$
language plpgsql
set enable_seqscan to off;