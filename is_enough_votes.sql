#include "gossip.h"

create or replace function GSP.is_enough_votes(voters GSP.blockchain_tx[]) returns boolean as
$code$
     select sum(voter.votes_cnt)filter(where u.k is not null)/sum(voter.votes_cnt)::decimal(18,4)>=0.66 
        from GSP.voter 
                left outer join (select * from unnest(voters) as u(k)) u on voter.public_key=u.k;
$code$
language sql
stable;