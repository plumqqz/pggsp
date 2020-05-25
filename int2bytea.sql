#include "gossip.h"

create or replace function  GSP.int2bytea(n int) RETURNS BYTEA AS 
$code$
declare
    rv bytea := '\x';
    i INTEGER;
begin
    while n > 0 loop
        i := n % 256;
        rv := set_byte(('\x00' || rv),0,i);
        n := (n-i)/256;
    end loop;
    return rv;
end;
$code$ 
language plpgsql immutable;
