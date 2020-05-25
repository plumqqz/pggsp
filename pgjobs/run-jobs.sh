#!/bin/bash
[[ !$JOB_SCHEMA ]] && JOB_SCHEMA='jb';
PSQL="/home/if/work/postgreses/EE12/bin/psql -v ON_ERROR_STOP=1 -X -p 15432 -h localhost work"
sleep='/bin/sleep'
wait_interval=300
jq=/usr/local/bin/jq

function handle_error {
#   ttoken=`cat ../tokenomica.ini|grep '^TELEGRAM_TOKEN='|sed "s/TELEGRAM_TOKEN='\(.*\)'/\1/"`
#   tbot=`cat ../tokenomica.ini|grep '^TELEGRAM_BOT='|sed "s/TELEGRAM_BOT='\?\(.*\)'\?/\1/"`
#   error=$?
#   msg=`tail -n 10 $2`
#   url=`printf 'https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s' $ttoken $tbot $(echo "$msg"|$jq -sRr @uri)`
#   /usr/bin/curl -s $url
   var='zz'
}

function isnt_script_running {
  [[ `jobs|grep "bin/psql .*${JOB_SCHEMA}.run" | wc -l` -lt $1 ]]
}

function run_script {
  [[ ! $1 ]] && up=1 || up=$1
  for ((i=0;i<$up;i++))
  do
    if isnt_script_running $1; then
        echo "Start #$i"
        #echo "while true; do $PSQL -c \"call $JOB_SCHEMA.run()\"; done > >(ts >>outputs/$JOB_SCHEMA.run.stdout) 2> >(ts >>outputs/$JOB_SCHEMA.run.stderr) &">/tmp/tmp.sh && . /tmp/tmp.sh
        echo "$PSQL -c \"/*__JOB_EXECUTOR__$JOB_SCHEMA*/ call $JOB_SCHEMA.run()\"; > >(ts >>outputs/$JOB_SCHEMA.run.stdout) 2> >(ts >>outputs/$JOB_SCHEMA.run.stderr) ">/tmp/tmp.sh && . /tmp/tmp.sh &
    fi
  done
}

function stop_script {
   $PSQL -1 -c "select pg_terminate_backend(pid) from pg_stat_activity where query like '%__JOB_EXECUTOR__${JOB_SCHEMA}%' and pid<>pg_backend_pid();"
#  if [ "X$pids" != "X" ]
#  then
#    kill $pids
#  fi
}

case "$1" in
  ""      ) run_script "$2";;
  start   ) run_script "$2";;
  stop    ) stop_script;;
  *       ) echo "Usage run-jobs.sh all|start|stop";;
esac

