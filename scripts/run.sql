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
  
  for r in select n from generate_series(1,200) as gs(n) loop
    tx.payload=format('{"action":"add_doc","param":{"doc_id":%s,"content":"Allow user to do something","created_at":"%s"}}', r.n, now())::bytea;
    tx.created_at = clock_timestamp();
    tx.sender_public_key=pk;
    tx.hash=GSP0.build_tx_hash(tx);
    tx.signature=GSP0.calculate_tx_signature(sk,tx);
    tx.tx_type_id=0;
    perform GSP0.accept_mempool_tx(to_json(tx));
  end loop;
  
  v=ecdsa_make_key_raw(CURVE);
  pk=v[1];
  sk=v[2];
  
  for r in select n from generate_series(1,200) as gs(n) loop
    tx.payload=format('{"action":"add_doc","param":{"doc_id":%s,"content":"Allow user to do something","created_at":"%s"}}', r.n, now())::bytea;
    tx.created_at = clock_timestamp();
    tx.sender_public_key=pk;
    tx.hash=GSP0.build_tx_hash(tx);
    tx.signature=GSP0.calculate_tx_signature(sk,tx);
    tx.tx_type_id=0;
    perform GSP1.accept_mempool_tx(to_json(tx));
  end loop;

  v=ecdsa_make_key_raw(CURVE);
  pk=v[1];
  sk=v[2];
  
  for r in select n from generate_series(1,200) as gs(n) loop
    tx.payload=format('{"action":"add_doc","param":{"doc_id":%s,"content":"Allow user to do something","created_at":"%s"}}', r.n, now())::bytea;
    tx.created_at = clock_timestamp();
    tx.sender_public_key=pk;
    tx.hash=GSP0.build_tx_hash(tx);
    tx.signature=GSP0.calculate_tx_signature(sk,tx);
    tx.tx_type_id=0;
    perform GSP2.accept_mempool_tx(to_json(tx));
  end loop;

end;
$code$;
