#include "gossip.h"

drop schema if exists GSP cascade;
create schema GSP;

create table GSP.tx_type(
  id smallint primary key,
  name text not null
);

create table GSP.mempool_txs(
    hash bytea primary key,
    tx_type_id smallint not null default(0) references GSP.tx_type(id),
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

create table GSP.account(
  public_key bytea primary key,
  balance bigint not null default(0) check(balance>=0)
);

create table GSP.magic_key(
 public_key bytea primary key
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

create or replace function GSP.int_increase_limit(pk bytea, lim bigint) returns void as
$code$
begin
  insert into GSP.account(pubic_key, balance) values(pk, lim) 
    on conflict(public_key) do update set balance=balance+excluded.balance;
end;
$code$
language plpgsql;

create or replace function GSP.int_decrease_limit(pk bytea, lim bigint) returns void as
$code$
declare
 rv bigint;
begin
   update GSP.account set balance=greatest(balance-lim,0) where public_key=pk
     returning balance into rv;
   if rv=0 then
     delete from GSP.account where public_key=pk;
   end if;
end;
$code$
language plpgsql;

create or replace function GSP.int_add_magic_key(pk bytea) returns void as
$code$
begin
  insert into GSP.magic_key(public_key) values(pk) on conflict do nothing;
end;
$code$
language plpgsql;

create or replace function GSP.int_remove_magic_key(pk bytea) returns void as
$code$
begin
  delete from GSP.magic_key where public_key=pk;
end;
$code$
language plpgsql;
