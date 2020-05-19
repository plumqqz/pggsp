SQL_FILES = $(wildcard *.sql)
MARK_FILES = $(SQL_FILES:.sql=.mark)
%.mark: %.sql
	SCHEMA=gsp0 ./load-script.sh $^
	SCHEMA=gsp1 ./load-script.sh $^
	SCHEMA=gsp2 ./load-script.sh $^

all: schema $(MARK_FILES) init
	@echo $^ >/dev/null

init: init.sql

clean:
	rm *.mark

schema: schema.sql
	SCHEMA=gsp0 ./load-script.sh $^
	SCHEMA=gsp1 ./load-script.sh $^
	SCHEMA=gsp2 ./load-script.sh $^
