#include "gossip.h"

create or replace function GSP.is_enough_votes(voters GSP.vote[]) returns boolean as
$code$
     select coalesce(sum(voter.votes_cnt)filter(where u.pk is not null)/sum(voter.votes_cnt)::decimal(18,4),0)>=0.66 
        from GSP.voter 
                left outer join (select distinct * from unnest(voters) as u(pk,s)) u on voter.public_key=u.pk;
$code$
language sql
stable;