#include "gossip.h"

drop schema if exists GSP cascade;
create schema GSP;

create table GSP.mempool_txs(
    tx bytea primary key,
    payload bytea not null,
    seenby text[],
    seenby_signatures bytea[]
);

create table GSP.peer(
 ref text primary key,
 schema_name text not null,
 cn text not null
);

create table GSP.voter(
 public_key bytea primary key,
 votes_cnt int not null check(votes_cnt>0) default 0
);

create type GSP.

create table GSP.proposed_block(
 hash text,
 txs GSP.
)