#include "gossip.h"

create or replace function GSP.accept_tx(tx json) returns text as
$code$
  declare
    tx GSP.txs = row_to_json(null::GSP.tx,tx);
  begin
    if not GSP.self_ref()=any(tx.seenby) then
      tx.seenby = tx.seenby||self_ref();
    end if;
    insert into GSP.tx select tx on conflict 
        do update set seenby=array(select distinct v from unnest(excluded.seenby));
    return 'OK';
  end;
$code$
language plpgsql