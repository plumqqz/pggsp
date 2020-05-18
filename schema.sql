#include "gossip.h"

drop schema if exists GSP cascade;
create schema GSP;

create table GSP.txs(
    tx text primary key,
    payload text not null,
    seenby text[]
);

create table GSP.peer(
 ref text primary key,
 schema_name text not null,
 cn text not null
);

