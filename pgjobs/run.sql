#include "jb.h"
create or replace procedure JB.run() as
$code$
declare
 r record;
 result integer;
begin
  perform set_config('application_name', trim($s$ JB $s$) ||' job executor', false);
  while true loop
  	select jb.*, md5(jb::text) as md5sum into r 
  	  from JB.job jb 
  	 where not jb.is_done and not jb.is_failed
  	   and jb.next_run_at<=now()
  	   and not exists(select * 
  	                    from JB.job j1 
  	                   where j1.id=any(jb.depends_on)
  	                     and not j1.is_done)
  	   for update skip locked limit 1;
  	if not found then
  	    commit;
  	    perform pg_sleep(1);
        continue;
  	end if;
  	begin
  	  execute format('select %s($1)', r.function_name) using r.id;
  	  -- if function executed and not changed job row, it is considerated as done
  	  if(select md5(j::text)=r.md5sum from JB.job j where j.id=r.id) then
  	    perform JB.set_job_done(r.id);
  	  else
  	    update JB.job set action=next_action, next_action=null where id=r.id;
  	  end if;
  	exception
  	 when others then
  	   update JB.job set is_failed=true, last_error=sqlerrm where job.id=r.id;
  	end;
  	commit;
  end loop;
end;
$code$
language plpgsql;

create or replace function JB.submit(function_name text, params jsonb, next_run_at timestamptz default now(), depends_on bigint[] default array[]::bigint[]) returns bigint as
$code$
declare
 rv bigint;
 begin
   insert into JB.job(function_name, params, next_run_at, depends_on) values(function_name, params, next_run_at, depends_on)
    on conflict do nothing
    returning id into rv;
   return rv;
 end;
$code$
language plpgsql;

create or replace function JB.set_next_run_after(job_id bigint, itv interval) returns void as
$code$
   update JB.job set next_run_at=clock_timestamp()+itv where id=job_id;
$code$
language sql;

create or replace function JB.set_next_run_after(job_id bigint, itv interval, ctx jsonb) returns void as
$code$
   update JB.job set next_run_at=clock_timestamp()+itv, ctx=set_next_run_after.ctx where id=job_id;
$code$
language sql;

create or replace function JB.set_job_done(job_id bigint) returns void as
$code$
  update JB.job set is_done=true where id=job_id;
$code$
language sql;

create or replace function JB.push_to_depends_on(job_id int, depends_on_job_ids bigint[]) returns void as
$code$
  update JB.job set depends_on=depends_on||depends_on_job_ids where id=job_id;
$code$
language sql;

create or replace function JB.push_to_depends_on(job_id bigint, dependend_on_job_id bigint) returns void as
$code$
  update JB.job set depends_on=depends_on||dependend_on_job_id where id=job_id;
$code$
language sql;


create or replace function JB.cleanup() returns void as
$code$
begin
  delete from JB.job where is_done and next_run_at<now()-make_interval(hours:=1);
end;
$code$
language plpgsql;

create or replace function JB.runtest(job_id bigint) returns void as
$code$
declare
 ctx jsonb:=(select ctx from jb.job where id=job_id);
 pass constant int = coalesce((ctx->>'pass')::int,0)::int;
begin
  raise notice '%', format('%s: time is %s', job_id, now());
  if pass<5 then
    update JB.job set next_run_at=now()+make_interval(secs:=3), ctx=job.ctx||jsonb_build_object('pass',pass+1)
     where id=job_id;
  else
  update JB.job set is_done=true where id=job_id;
  end if;
end;
$code$
language plpgsql
