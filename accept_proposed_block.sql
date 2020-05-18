#include "gossip.h"

create or replace function GSP.accept_proposed_block(jpb json) returns text as
$code$
  declare
    pb GSP.proposed_block = json_populate_record(null::GSP.proposed_block,jpb);
  begin
    assert jpb is not null, 'Passed block json is null';
    if not GSP.is_valid_proposed_block_signature(pb) then
       raise sqlstate 'XY005' using message='Invalid signature';
    end if;
    if pb.seenby is null then
       pb.seenby=array[GSP.self_ref()]::text[];
    elsif not GSP.self_ref()=any(pb.seenby) then
      pb.seenby = pb.seenby||GSP.self_ref();
    end if;
    insert into GSP.proposed_block select pb.* on conflict(hash)
        do update set seenby=array(select v from unnest(excluded.seenby) as u(v) union select v from unnest(pb.seenby) u(v));
    return 'OK';
  end;
$code$
language plpgsql