#include "gossip.h"

create or replace function GSP.accept_proposed_block(jpb json) returns text as
$code$
  declare
    pb GSP.proposed_block = json_populate_record(null::GSP.proposed_block,jpb);
    r record;
  begin
    assert jpb is not null, 'Passed block json is null';
    if not GSP.is_valid_proposed_block_signature(pb) then
       raise sqlstate 'XY006' using message='Invalid signature';
    end if;
    for r in select * from unnest(pb.txs) as u loop
        if exists(select * from GSP.blockchain bc where array[r.hash] && GSP.get_hash_array(bc.txs)) then
            raise notice 'Proposed tx has txs are already in blockchain';
            return 'ERR';           
        end if;
        if not ecdsa_verify_raw(r.sender_public_key, r.hash, r.signature, CURVE) then
            raise sqlstate 'XY005' using message=format('Invalid tx signature with hash=%s', r.hash::text);
        end if;
    end loop;
    if pb.seenby is null then
       pb.seenby=array[GSP.self_ref()]::text[];
    elsif not GSP.self_ref()=any(pb.seenby) then
      pb.seenby = pb.seenby||GSP.self_ref();
    end if;
    perform pg_advisory_xact_lock(pb.height);
    insert into GSP.proposed_block select pb.* on conflict(hash)
        do update set seenby=case when array_length(proposed_block.voters,1) is null then array(select v from unnest(excluded.seenby) as u(v) union select GSP.self_ref()) else array[GSP.self_ref()] end,
                      voters=array(select v from unnest(proposed_block.voters) v union select v from unnest(excluded.voters) v);
    return 'OK';
  end;
$code$
language plpgsql
set enable_seqscan to false;