#include "gossip.h"

drop schema if exists GSP cascade;
create schema GSP;

create table GSP.mempool_txs(
    hash bytea primary key,
    payload bytea not null,
    sender_public_key bytea,
    signature bytea,
    seenby text[]
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
    hash bytea,
    payload bytea,
    sender_public_key bytea,
    signature bytea
); 

create table GSP.proposed_block(
 height bigint not null,
 hash bytea not null unique,
 prev_hash bytea not null,
 miner_public_key bytea not null,
 signature bytea not null,
 txs GSP.blockchain_tx[] not null,
 voters bytea[] not null,
 seenby text[] not null
);

create table GSP.blockchain(
 height bigint not null check(height>0 or prev_hash is null) unique,
 hash bytea not null unique,
 prev_hash bytea not null,
 miner_public_key bytea not null,
 signature bytea not null,
 txs GSP.blockchain_tx[] not null,
 voters GSP.voter[] not null
);

create table GSP.node_keys(
 id int primary key check(id=1) default(1),
 pk bytea not null,
 sk bytea not null
);

create or replace function GSP.get_node_pk() returns bytea as
$code$
select pk from GSP.node_keys;
$code$
language sql stable;

create or replace function GSP.get_node_sk() returns bytea as
$code$
select sk from GSP.node_keys;
$code$
language sql stable;

