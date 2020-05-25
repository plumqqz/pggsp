#include "gossip.h"

create or replace function GSP.build_tx_hash(tx GSP.mempool_txs) returns bytea as
$code$
begin
 assert tx.sender_public_key is not null, 'Cannot build tx hash: Passed public key is null';
 assert tx.created_at is not null, 'Cannot build tx hash: Passed tx.created_at is null';
 assert tx.payload is not null, 'Cannot build tx hash: Passed tx.payload is null';
 return GSP.int2bytea(extract(epoch from tx.created_at)::int)||sha256(tx.sender_public_key||tx.payload);
end;
$code$
language plpgsql
immutable;