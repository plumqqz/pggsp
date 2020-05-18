#include "gossip.h"

create or replace function GSP.is_valid_tx_signature(tx GSP.mempool_txs) returns boolean as
$code$
 select ecdsa_verify_raw(tx.sender_public_key,tx.hash, tx.signature, CURVE);
$code$
language sql
immutable;