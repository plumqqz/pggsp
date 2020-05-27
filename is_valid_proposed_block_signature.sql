#include "gossip.h"

create or replace function GSP.is_valid_proposed_block_signature(pb GSP.proposed_block) returns boolean as
$code$
declare
 hashes bytea[]:=array(select u.tx from unnest(pb.txs) as u(tx));
 merkle bytea;
 signature bytea;
 r record;
begin
    merkle = GSP.calculate_merkle_hash(hashes);
    if pb.prev_hash!=(select hash from GSP.blockchain bc where bc.height=pb.height-1) and pb.height>0 then
        return false;
    end if;

    for r in select * from unnest(pb.txs) as u loop
      if not ecdsa_verify_raw(r.sender_public_key, r.hash, r.signature, CURVE) then
        return false;
      end if;
    end loop;
    if pb.height>0 and 
      not exists(select * from GSP.blockchain bc where bc.hash=pb.prev_hash and bc.height=pb.height-1)
    then
       raise notice 'Block has no predcessor';
       return false;
    end if;
    return ecdsa_verify_raw(pb.miner_public_key, sha256(GSP.int2bytea(extract(epoch from pb.created_at)::int)||sha256(merkle||pb.miner_public_key)||pb.prev_hash), pb.signature, CURVE);
end;
$code$
language plpgsql;