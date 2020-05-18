#include "gossip.h"

drop schema if exists GSP cascade;
create schema GSP;

create table GSP.mempool_txs(
    tx bytea primary key,
    payload bytea not null,
    sender_public_key bytea,
    signature bytea,
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

create type GSP.blockchain_tx as(
    tx bytea,
    payload bytea,
    sender_public_key bytea,
    signature bytea
); 

create table GSP.proposed_block(
 hash text,
 miner_public_key bytea,
 signature bytea,
 txs GSP.blockchain_tx[],
 voters bytea[]
);