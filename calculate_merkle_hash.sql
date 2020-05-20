#include "gossip.h"

create or replace function GSP.calculate_merkle_hash(hashes bytea[]) returns bytea as
$code$
  declare
    temp_hashes bytea[]=array[]::bytea[];
    i int;
  begin
     if hashes is null or array_length(hashes,1)=0 then
        return sha256('');
     end if;
  <<main>>
     while true loop
       for i in 1..array_length(hashes,1) by 2 loop
         temp_hashes = temp_hashes || digest(hashes[i]||coalesce(hashes[i+1],hashes[i]),'sha256');
       end loop;
       if array_length(hashes,1)=1 then
         exit main;
       end if;
       hashes = temp_hashes;
       temp_hashes=array[]::bytea[];
     end loop;
   assert temp_hashes[1] is not null, 'Calculated Merkle hash is null';
   return temp_hashes[1];
   end;
$code$
language plpgsql;