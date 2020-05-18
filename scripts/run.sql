#include "gossip.h"

do $code$
declare
 payload text; 
 pk bytea;
 sk bytea;
 tx gsp0.mempool_txs;
 r record;
begin
  select ecdsa_make_key(CURVE) into pk, sk;
  for r in select n from generate_series(1,1000) as gs(n) loop
    tx.payload=format('call add_doc(%s)', r.n)::bytea;
    tx.tx=sha256(tx.payload);
    tx.signature=GSP0.calculate_tx_signature(sk,tx.payload);
    raise notice 'signature=%', tx.signature;
    tx.sender_public_key=pk;
    raise notice '%', to_json(tx);
    perform GSP0.accept_mempool_tx(to_json(tx));
  end loop;
end;
$code$;
