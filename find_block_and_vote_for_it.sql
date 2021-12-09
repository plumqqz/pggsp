#include "gossip.h"

create or replace function GSP.find_block_and_vote_for_it() returns void as
$code$
<<code>>
declare
 r record;
 pbr GSP.proposed_block;
 mh bigint;
 mts timestamptz;
 voted_block_found boolean;
 signature bytea;
 total_votes_cnt bigint;
begin

  select bc.height, bc.added_at into mh, mts from GSP.blockchain bc order by bc.height desc limit 1;
  if not found then
      raise sqlstate 'XY014' using message='Blockchain is empty';
  end if;
  if not found or clock_timestamp()-mts<make_interval(secs:=3) then
    return;
  end if;
      
  select sum(votes_cnt) into total_votes_cnt from GSP.voter;
  if not found then
      raise sqlstate 'XY015' using message='No voters has been found';
  end if;
  
  -- проверяем, есть ли вообще за что голосовать - если каждый увидит только свой
  -- блок и проголосует за него, то голосование может остановиться
  if (select sum(v.votes_cnt)*1.0000/total_votes_cnt
              from GSP.proposed_block p
                   join GSP.voter v on p.miner_public_key=v.public_key
                   where p.height=mh+1)<0.6 then
     -- мало блоков от майнеров, надо ждать еще кандидатов
     -- raise notice 'Too low voter nodes send next tx candidates';
     return;
   end if;
  
  voted_block_found = false;
  for r in select p.hash, p.height
              from GSP.proposed_block p, 
                   unnest(p.voters) as vt
                   join GSP.voter v on vt.public_key=v.public_key
              where ecdsa_verify_raw(v.public_key, p.hash, vt.signature, CURVE)
              and p.height=mh+1
             group by 1,2
             having sum(v.votes_cnt) >= total_votes_cnt*0.6000
             order by 1
  loop
  -- если вдруг у нас окажется два блока одинаковой высоты с 
  -- достаточным числом голосов,то это фатальная ошибка и быть
  -- такого не может, так что тут все свалится
     perform GSP.append_proposed_block_to_blockchain(r.hash);
     voted_block_found=true;
     exit;
  end loop;  

  if voted_block_found then
     return;
  end if;

    -- проверяем, не голосовали ли уже за этот блок
  if exists(select * from GSP.proposed_block pb
   where pb.height=mh+1
     and array[GSP.get_node_pk()] && GSP.get_public_key_array(pb.voters))
  then
    return;
  end if;  

  select pb.* into pbr from GSP.proposed_block pb, GSP.voter v
  where pb.miner_public_key=v.public_key 
    and pb.height=mh+1
    order by v.votes_cnt desc, v.public_key
    limit 1;

  if not found then
    return;
  end if;
  signature = ecdsa_sign_raw(GSP.get_node_sk(), pbr.hash, CURVE);
  
  update GSP.proposed_block pb set
    seenby=case when array_length(voters,1) is null then array[GSP.self_ref()]::text[] else array(select v from unnest(seenby) v union select GSP.self_ref()) end,    
    voters=array(select v from unnest(voters) as v union select (GSP.get_node_pk(), code.signature)::GSP.vote)
   where pb.hash=pbr.hash and not exists(select * from unnest(pb.voters) v where v.public_key=GSP.get_node_pk());
  
  
end;
$code$
language plpgsql;
