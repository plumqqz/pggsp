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
    created_at timestamptz not null,
    added_at timestamptz default(clock_timestamp()) check(added_at>=created_at),
    signature bytea,
    seenby text[]
);
create index on GSP.mempool_txs(added_at, sender_public_key);

create table GSP.peer(
 ref text primary key,
 schema_name text not null,
 cn text not null,
 height bigint,
 last_accessed_at timestamptz
);

create table GSP.voter(
 public_key bytea primary key,
 votes_cnt bigint not null check(votes_cnt>0) default 0
);

create type GSP.vote as(
 public_key bytea,
 signature bytea 
);

create type GSP.blockchain_tx as(
    hash bytea,
    tx_type_id smallint,
    payload bytea,
    sender_public_key bytea,
    added_at timestamptz,
    signature bytea
); 

create table GSP.proposed_block(
 height bigint not null,
 hash bytea not null unique,
 prev_hash bytea not null,
 miner_public_key bytea not null,
 created_at timestamptz not null,
 added_at timestamptz not null default(clock_timestamp()),
 signature bytea not null,
 txs GSP.blockchain_tx[] not null,
 voters GSP.vote[] not null,
 seenby text[] not null
);

create table GSP.blockchain(
 height bigint not null check(height>0 or prev_hash=sha256('') and height=0) unique,
 hash bytea not null unique,
 prev_hash bytea not null,
 miner_public_key bytea not null,
 created_at timestamptz not null,
 added_at timestamptz not null check(added_at>=created_at),
 signature bytea not null,
 txs GSP.blockchain_tx[] not null,
 voters GSP.vote[] not null
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
  insert into GSP.account(public_key, balance) values(pk, lim) 
    on conflict(public_key) do update set balance=excluded.balance+lim;
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

#votes
create or replace function GSP.int_increase_votes(pk bytea, lim bigint) returns void as
$code$
begin
  insert into GSP.voter(public_key, votes_cnt) values(pk, lim) 
    on conflict(public_key) do update set votes_cnt=excluded.votes_cnt+lim;
end;
$code$
language plpgsql;

create or replace function GSP.int_decrease_votes(pk bytea, lim bigint) returns void as
$code$
declare
 rv bigint;
begin
   update GSP.voter set votes_cnt=greatest(votes_cnt-lim,0) where public_key=pk
     returning votes_cnt into rv;
   if rv=0 then
     delete from GSP.voter where public_key=pk;
   end if;
end;
$code$
language plpgsql;

create or replace function GSP.get_hash_array(a anyarray) returns bytea[] as 
$code$
  select array_agg(r.hash) from unnest(a) as r;
$code$
language sql immutable ;

create index on GSP.blockchain using gin((GSP.get_hash_array(txs)));

create or replace function GSP.get_public_key_array(a anyarray) returns bytea[] as 
$code$
  select array_agg(r.public_key) from unnest(a) as r;
$code$
language sql immutable ;
