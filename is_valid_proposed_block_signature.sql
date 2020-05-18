#include "gossip.h"

create or replace function GSP.is_valid_proposed_block_signature(pb GSP.proposed_block) returns boolean as
$code$
declare
 hashes bytea[]:=array(select (u.tx).hash from unnest(pb.txs) as u(tx));
 merkle bytea;
 signature bytea;
begin
    CALCULATE_MERKLE_HASH(hashes, merkle);
    if pb.prev_hash!=(select hash from GSP.blockchain bc where bc.height=pb.height-1) and pb.height>0 then
        return false;
    end if;
    return ecdsa_verify_raw(pb.miner_public_key, sha256(merkle||pb.prev_hash), pb.signature, CURVE);
end;
$code$
language plpgsql;