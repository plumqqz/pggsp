#include "gossip.h"

create or replace function GSP.reply_blockchain_height() returns bigint as
$code$
  select max(height) from GSP.blockchain;
$code$
language sql;