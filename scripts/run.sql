#include "gossip.h"

do $code$
declare
 payload text; 
 pk bytea;
 sk bytea;
 tx gsp0.mempool_txs;
 r record;
 v bytea[];
begin
  v=ecdsa_make_key_raw(CURVE);
  pk=v[1];
  sk=v[2];
  
  for r in select n from generate_series(1,10) as gs(n) loop
    tx.payload=format('call add_doc(%s,%L)', r.n, now())::bytea;
    tx.hash=sha256(tx.payload);
    tx.signature=GSP0.calculate_tx_signature(sk,tx.payload);
    tx.sender_public_key=pk;
    tx.tx_type_id=0;
    perform GSP0.accept_mempool_tx(to_json(tx));
  end loop;
end;
$code$;
