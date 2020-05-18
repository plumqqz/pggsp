do $code$
declare
 payload text:='call add_doc(1,2) at '||now();
begin
    perform gsp0.accept_mempool_tx(to_json((md5(payload||'/'||n),payload||'/'||n,array[]::text[])::gsp0.txs)) from generate_series(1,5000) as gs(n);
end;
$code$;
