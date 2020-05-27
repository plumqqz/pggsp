#include "gossip.h"

create or replace function GSP.append_proposed_block_to_blockchain(bh bytea) returns void as
$code$
declare
 b GSP.proposed_block=(select pb from GSP.proposed_block pb where pb.hash=bh);
 r record;
begin

if b.height is null then
   raise notice '%', format('Cannot find proposed block with hash=%s', bh::text);
   return;
 end if;

 perform pg_advisory_xact_lock(b.height);

 if not GSP.is_valid_proposed_block_signature(b) then
   raise sqlstate 'XY006' using message=format('Cannot validate proposed block with hash=%s', bh::text);
 end if;

 if b.height>0 and not GSP.is_enough_votes(b.voters)then
   raise notice '%', format('There is not enough votes for proposed block %s', b.voters);
   return;
 end if;
 
 if exists(select * 
             from unnest(b.txs) t 
            where exists(select * 
                           from GSP.blockchain bc 
                          where array[t.hash] && GSP.get_hash_array(bc.txs))) 
 then
   raise notice '%', format('Proposed block has transactions are already with hash=%s', bh::text);
   return;
 end if;

 
 delete from GSP.mempool_txs where hash in(select hash from unnest(b.txs) t);
 delete from GSP.proposed_block where height<=b.height;
 
 insert into GSP.blockchain(height, hash, prev_hash,
                            miner_public_key, signature, created_at,
                            added_at, txs, voters)
                         values(b.height, b.hash, b.prev_hash,
                                b.miner_public_key, b.signature, b.created_at, 
                                clock_timestamp(), b.txs, b.voters)
     on conflict do nothing;
 
end;
$code$
language plpgsql
set enable_seqscan to off;