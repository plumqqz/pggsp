#include "gossip.h"

create or replace function GSP.make_proposed_block() returns void as
$code$
declare
 pb GSP.proposed_block;
 hashes bytea[];
 merkle_hash bytea;
 begin
  select array_agg((tx,payload,sender_public_key,signature)::gsp0.blockchain_tx) into pb.txs from (select * from GSP0.mempool_txs limit 1000) mp;
  if pb.txs is null then
     pb.txs:=array[]::gsp0.blockchain_tx[];
  end if;
  hashes=array(select tx from unnest(pb.txs) as u(tx));
  CALCULATE_MERKLE_HASH(hashes, pb.tx);
  if pb.tx is null then
     pb.tx=sha256('');
  end if;
  select height, tx into pb.height, pb.tx_prev from GSP.blockchain order by height desc limit 1;
  if not found then
    pb.height=0;
    pb.tx_prev=''::bytea;
  end if;
  pb.signature = ecdsa_sign_raw(GSP.get_node_sk(), sha256(pb.tx||pb.tx_prev), CURVE);
  pb.miner_public_key=GSP.get_node_pk();
  pb.voters=array[]::GSP.voter[];
  pb.seenby=array[GSP.self_ref()];
  insert into GSP.proposed_block select pb.*;
 end;
$code$
language plpgsql