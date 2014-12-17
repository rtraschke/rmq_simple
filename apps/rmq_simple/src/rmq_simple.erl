-module(rmq_simple).

-include("amqp_client/include/amqp_client.hrl").

-export([start/0]).

start() ->
    {Conn, Producer_Chan, Consumer_Chan} = setup_rabbitmq(),
    P = spawn_link(fun () -> producer(Producer_Chan) end),
    C = spawn_link(fun () -> consumer(Consumer_Chan) end),
    timer:sleep(1*60*1000),
    exit(P, kill),
    exit(C, kill),
    teardown_rabbitmq(Conn, Producer_Chan, Consumer_Chan).

setup_rabbitmq() ->
    {ok, Conn} = amqp_connection:start(#amqp_params_network{}),
    {ok, Producer_Chan} = amqp_connection:open_channel(Conn),
    {ok, Consumer_Chan} = amqp_connection:open_channel(Conn),
    #'queue.declare_ok'{} = amqp_channel:call(Producer_Chan,
            #'queue.declare'{
                queue = <<"rmq_simple_queue">>
            }
    ),
    {Conn, Producer_Chan, Consumer_Chan}.

producer(Chan) ->
    timer:sleep(500),
    Payload = now(),
    io:format("Publish: ~p~n", [Payload]),
    Publish = #'basic.publish'{
            exchange = <<>>,
            routing_key = <<"rmq_simple_queue">>
    },
    ok = amqp_channel:cast(Chan, Publish,
            #amqp_msg{payload = term_to_binary(Payload)}),
    producer(Chan).

consumer(Chan) ->
    Get = #'basic.get'{queue = <<"rmq_simple_queue">>},
    case amqp_channel:call(Chan, Get) of
        #'basic.get_empty'{} ->
            timer:sleep(1000);
        {#'basic.get_ok'{delivery_tag = Tag},
                #amqp_msg{payload = Payload}} ->
            io:format("Received: ~p~n", [binary_to_term(Payload)]),
            amqp_channel:cast(Chan, #'basic.ack'{delivery_tag = Tag})
    end,
    consumer(Chan).

teardown_rabbitmq(Conn, Producer_Chan, Consumer_Chan) ->
    ok = amqp_channel:close(Consumer_Chan),
    ok = amqp_channel:close(Producer_Chan),
    ok = amqp_connection:close(Conn).
