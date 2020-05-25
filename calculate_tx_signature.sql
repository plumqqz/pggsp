#include "gossip.h"

create or replace function GSP.calculate_tx_signature(sender_private_key bytea, payload bytea) returns bytea as
$code$
declare
 rv bytea;
begin
 assert sender_private_key is not null, 'Sender private key is null';
 assert payload is not null, 'Payload is null';
 return ecdsa_sign_raw(sender_private_key, payload, CURVE);
end;
$code$
language plpgsql
immutable;

create or replace function GSP.calculate_tx_signature(sender_public_key bytea, tx GSP.mempool_txs) returns bytea as
$code$
  select GSP.calculate_tx_signature(sender_public_key, tx.hash);
$code$
language sql
immutable;