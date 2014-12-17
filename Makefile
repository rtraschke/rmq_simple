.PHONY: all deps compile clean run

all: compile

deps: deps/amqp_client deps/rabbit_common
	./rebar get-deps

compile:
	./rebar compile

clean:
	./rebar clean
	-rm *.ez

run: compile
	erl -pa apps/*/ebin -pa deps/*/ebin -s rmq_simple start -s init stop


RABBITMQ_VERSION=3.3.4

deps/amqp_client: amqp_client-$(RABBITMQ_VERSION).ez
	mkdir -p deps
	unzip -d deps amqp_client-$(RABBITMQ_VERSION).ez
	-rm -r deps/amqp_client
	mv deps/amqp_client-$(RABBITMQ_VERSION) deps/amqp_client
	touch deps/amqp_client

deps/rabbit_common: rabbit_common-$(RABBITMQ_VERSION).ez
	mkdir -p deps
	unzip -d deps rabbit_common-$(RABBITMQ_VERSION).ez
	-rm -r deps/rabbit_common
	mv deps/rabbit_common-$(RABBITMQ_VERSION) deps/rabbit_common
	touch deps/rabbit_common

amqp_client-$(RABBITMQ_VERSION).ez rabbit_common-$(RABBITMQ_VERSION).ez:
	curl -O http://www.rabbitmq.com/releases/rabbitmq-erlang-client/v$(RABBITMQ_VERSION)/$@
