#include "gossip.h"

create or replace function GSP.make_proposed_block() returns void as
$code$
declare
 pb GSP.proposed_block;
 hashes bytea[];
 merkle_hash bytea;
 begin
  select array_agg((hash,0,payload,sender_public_key,added_at,signature)::gsp0.blockchain_tx) into pb.txs from (select * from GSP.mempool_txs order by added_at, sender_public_key limit 1000) mp;

  if array_length(pb.txs,1)=0 then
     pb.txs:=array[]::gsp0.blockchain_tx[];
  end if;

  hashes=array(select (u.tx).hash from unnest(pb.txs) as u(tx));

  pb.hash = GSP.calculate_merkle_hash(hashes);

  if pb.hash is null then
     pb.hash=sha256('');
  end if;
  select height, hash into pb.height, pb.prev_hash from GSP.blockchain order by height desc limit 1;
  if not found then
    pb.height=0;
    pb.prev_hash=sha256('\x'::bytea);
  end if;
  pb.signature = ecdsa_sign_raw(GSP.get_node_sk(), sha256(pb.hash||pb.prev_hash), CURVE);
  pb.miner_public_key=GSP.get_node_pk();
  pb.voters=array[]::GSP.voter[];
  pb.seenby=array[GSP.self_ref()];
  pb.created_at=clock_timestamp();
  pb.added_at=clock_timestamp();
  insert into GSP.proposed_block select pb.*;
 end;
$code$
language plpgsql