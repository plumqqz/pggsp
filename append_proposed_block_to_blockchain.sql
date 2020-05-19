#include "gossip.h"

create or replace function GSP.append_proposed_block_to_blockchain(bh bytea) returns void as
$code$
declare
 b GSP.proposed_block=(select pb from GSP.proposed_block pb where pb.hash=bh);
begin
 assert b is not null, format('Cannot find proposed block with hash=%s', bh::text);
 if not GSP.is_valid_proposed_block_signature(b) then
   raise sqlstate 'XY006' using message=format('Cannot validate proposed block with hash=%s', bh::text);
 end if;
 if b.height>0 and not GSP.is_enough_votes(b.voters)then
   raise sqlstate 'XY010' using message=format('There is not enough votes for proposed block with hash=%s', bh::text);
 end if;
 insert into GSP.blockchain(height, hash, prev_hash,
                            miner_public_key, signature, txs,
                            voters)
                         select b.height, b.hash, b.prev_hash,
                                b.miner_public_key, b.signature, b.txs,
                                b.voters;
end;
$code$
language plpgsql;