SQL_FILES = $(wildcard *.sql)
MARK_FILES = $(SQL_FILES:.sql=.mark)
%.mark: %.sql
	SCHEMA=gsp0 ./load-script.sh $^
	SCHEMA=gsp1 ./load-script.sh $^
	SCHEMA=gsp2 ./load-script.sh $^

all: schema.mark $(MARK_FILES) init.plpgsql.mark
	@echo $^ >/dev/null

init.plpgsql.mark: init.plpgsql
	SCHEMA=gsp0 ./load-script.sh $^
	SCHEMA=gsp1 ./load-script.sh $^
	SCHEMA=gsp2 ./load-script.sh $^

clean:
	rm *.mark

schema: schema.sql
	SCHEMA=gsp0 ./load-script.sh $^
	SCHEMA=gsp1 ./load-script.sh $^
	SCHEMA=gsp2 ./load-script.sh $^
