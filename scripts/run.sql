do $code$
declare
 payload text:='call add_doc(1,2)';
begin
insert into gsp0.txs(tx,payload,seenby)values(md5(payload),payload,array[]::text[]);
$code$