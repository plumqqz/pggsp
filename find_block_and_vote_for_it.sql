#include "gossip.h"

create or replace function GSP.find_block_and_vote_for_it() returns void as
$code$
<<code>>
declare
 r record;
 pbr GSP.proposed_block;
 mh bigint;
 voted_block_found boolean;
 signature bytea;
 total_votes_cnt bigint;
begin
  if not GSP.is_node_ready() then
    return;
  end if;

  select max(bc.height) into mh from GSP.blockchain bc;
  
  -- проверяем, не голосовали ли уже за этот блок
  if exists(select * from GSP.proposed_block pb
   where pb.height=mh+1
     and array[GSP.get_node_pk()] && GSP.get_public_key_array(pb.votes))
  then
    return;
  end if;
  
  
  if not found then
      raise sqlstate 'XY014' using message='Blockchain is empty';
  end if;
  
  select sum(votes_cnt) into total_votes_cnt from GSP.voter;
  if not found then
      raise sqlstate 'XY015' using message='No voters has been found';
  end if;
  
  voted_block_found = false;
  for r in select p.hash
              from GSP.proposed_block p, 
                   unnest(p.voters) as vt
                   join GSP.voter v on vt.public_key=v.public_key
              where ecdsa_verify_raw(v.public_key, p.hash, vt.signature, CURVE)
              and p.height=mh+1
             group by 1
             having sum(v.votes_cnt) >= total_votes_cnt*0.6600
  loop
  -- если вдруг у нас окажется два блока одинаковой высоты с 
  -- достаточным числом голосов,то это фатальная ошибка и быть
  -- такого не может, так что тут все свалится
     perform GSP.append_proposed_block_to_blockchain(r.hash);
     voted_block_found=true;
  end loop;
  
  if voted_block_found then
     return;
  end if;
  
  select pb.* into pbr from GSP.proposed_block pb, GSP.voter v
  where pb.miner_public_key=v.public_key 
    and pb.height=mh+1
    order by v.votes_cnt desc, v.public_key
    limit 1;
  signature = ecdsa_sign_raw(GSP.get_node_sk(), pb.hash, CURVE);
  
  update GSP.proposed_block set
    voters=voters||(GSP.get_node_pk(), signature)::GSP.vote,
    seenby=array[]::text[]
   where pb.hash=pbr.hash;
  
  
end;
$code$
language plpgsql;