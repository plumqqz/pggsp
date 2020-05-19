#include "gossip.h"

create or replace function GSP.reply_blockchain_block(bt bigint) returns json as
$code$
    select to_json(b) from GSP.blockchain b where b.height=bt;
$code$
language sql;