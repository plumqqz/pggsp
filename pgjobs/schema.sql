#include "jb.h"

drop schema if exists JB cascade;
create schema JB;
create table JB.job(
 id bigint generated always as identity,
 function_name text not null,
 params jsonb not null default '{}'::jsonb check(jsonb_typeof(params)='object'),
 ctx jsonb not null default '{}'::jsonb check(jsonb_typeof(ctx)='object'),
 action text,
 next_action text,
 is_done boolean not null default false,
 is_failed boolean not null default false,
 next_run_at timestamptz not null default now(),
 depends_on bigint[],
 last_error text
);

create index on JB.job using gin(depends_on);
create index on JB.job(next_run_at) where not is_done and not is_failed;
create unique index on JB.job(function_name,(md5(params::text)));
