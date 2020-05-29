#include "gossip.h"

create or replace function GSP.make_proposed_block() returns void as
$code$
declare
 pb GSP.proposed_block;
 hashes bytea[];
begin
 perform GSP.find_block_and_vote_for_it();
 if exists(select * 
             from GSP.proposed_block ppb 
            where ppb.height=(select max(bc.height)+1 from GSP.blockchain bc) 
              and ppb.miner_public_key=GSP.get_node_pk()) then
   -- previous block has not been appended
   return;
 end if;
  select array_agg((hash,0,payload,sender_public_key,added_at,signature)::GSP.blockchain_tx) 
        into pb.txs 
   from (select * 
           from GSP.mempool_txs 
          where not exists(select * from GSP.blockchain b where array[mempool_txs.hash] && GSP.get_hash_array(b.txs))
   order by added_at, sender_public_key limit 1000) mp;
  if pb.txs is null or array_length(pb.txs,1)=0 then -- no tx found
     -- raise notice 'No tx found';
     return;
  end if;


  hashes=array(select u.tx from unnest(pb.txs) as u(tx));

  pb.miner_public_key=GSP.get_node_pk();
  pb.created_at=clock_timestamp();
  pb.hash = GSP.int2bytea(extract(epoch from pb.created_at)::int)||sha256(GSP.calculate_merkle_hash(hashes)||pb.miner_public_key);

  if pb.hash is null then
     pb.hash=sha256('');
  end if;
  select height+1, hash into pb.height, pb.prev_hash from GSP.blockchain order by height desc limit 1;
  if not found then
    pb.height=0;
    pb.prev_hash=sha256('\x'::bytea);
  end if;
  pb.signature = ecdsa_sign_raw(GSP.get_node_sk(), sha256(pb.hash||pb.prev_hash), CURVE);
  pb.voters=array[]::GSP.voter[];
  pb.seenby=array[GSP.self_ref()];
  pb.added_at=clock_timestamp();
  insert into GSP.proposed_block select pb.* on conflict do nothing;
 end;
$code$
language plpgsql
set enable_seqscan to off;