do $code$
declare
 tx gsp0.mempool_txs;
begin
 if exists(select * from gsp0.blockchain) then
    return;
 end if;
 
 tx.payload=''::bytea;
 tx.created_at=clock_timestamp();
 tx.sender_public_key=gsp0.get_node_pk();
 tx.hash=gsp0.build_tx_hash(tx);
 tx.signature=GSP0.calculate_tx_signature(gsp0.get_node_sk(),tx);
 tx.tx_type_id=0;
 perform GSP0.accept_mempool_tx(to_json(tx));
 perform gsp0.make_proposed_block();
 perform gsp0.append_proposed_block_to_blockchain((select hash from gsp0.proposed_block));
end; 
$code$;

