#include "gossip.h"

do $code$
begin
perform jb.submit('gsp0.ask_peer_jobs','{}'::jsonb);
perform jb.submit('gsp1.ask_peer_jobs','{}'::jsonb);
perform jb.submit('gsp2.ask_peer_jobs','{}'::jsonb);

perform jb.submit('gsp0.sync_blockchain_jobs', '{}'::jsonb);
perform jb.submit('gsp1.sync_blockchain_jobs', '{}'::jsonb);
perform jb.submit('gsp2.sync_blockchain_jobs', '{}'::jsonb);

perform jb.submit('gsp0.make_proposed_block_jobs', '{}'::jsonb);
perform jb.submit('gsp1.make_proposed_block_jobs', '{}'::jsonb);
perform jb.submit('gsp2.make_proposed_block_jobs', '{}'::jsonb);


perform jb.submit('gsp0.tx_gossip_jobs', '{}'::jsonb);
perform jb.submit('gsp1.tx_gossip_jobs', '{}'::jsonb);
perform jb.submit('gsp2.tx_gossip_jobs', '{}'::jsonb);

perform jb.submit('gsp0.block_gossip_jobs', '{}'::jsonb);
perform jb.submit('gsp1.block_gossip_jobs', '{}'::jsonb);
perform jb.submit('gsp2.block_gossip_jobs', '{}'::jsonb);


perform jb.submit('gsp0.find_block_and_vote_for_it_jobs','{}'::jsonb);
perform jb.submit('gsp1.find_block_and_vote_for_it_jobs','{}'::jsonb);
perform jb.submit('gsp2.find_block_and_vote_for_it_jobs','{}'::jsonb);

perform jb.submit('gsp0.cleanup','{}'::jsonb);
perform jb.submit('gsp1.cleanup','{}'::jsonb);
perform jb.submit('gsp2.cleanup','{}'::jsonb);

end;
$code$;