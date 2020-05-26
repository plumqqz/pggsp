#ifndef GSP
#define GSP gsp
#endif
#define CURVE ('secp160r1'::text)
#define GSPSTR trim($s$ GSP $s$)

#define CALCULATE_MERKLE_HASH(hashes, result) \
  declare\
    temp_hashes bytea[]=array[]::bytea[];\
    i int;\
  begin\
     while array_length(hashes::bytea[],1)>1 loop\
       for i in 1..array_length(hashes,1) by 2 loop\
         temp_hashes = temp_hashes || digest(hashes[i]||coalesce(hashes[i+1],hashes[i]),'sha256');\
       end loop;\
       hashes = temp_hashes;\
       temp_hashes=array[]::bytea[];\
     end loop;\
   result:=hashes[1];\
   end

#define get_connection_name(connection_string) ('cn'||md5(connection_string))

#define CREATE_DBLINK(connection_string)\
   if not get_connection_name(connection_string)=any(coalesce(dblink_get_connections(),array[]::text[])) then\
     perform dblink_connect(get_connection_name(connection_string), connection_string || ' application_name=' || trim($s$ BCW $s$) || '.send_mempool_to_peer');\
     perform dblink_exec(get_connection_name(connection_string),'set statement_timeout to 10000');\
   end if

