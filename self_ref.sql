#include "gossip.h"

create or replace function GSP.self_ref() returns text as
$code$
  select GSPSTR::text;
$code$
language sql
immutable;