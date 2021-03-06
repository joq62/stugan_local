%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_lib_service). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(SERVER_ID,"test_tcp_server").
%% External exports
%-export([test/0,init_test/0,start_container_1_test/0,start_container_2_test/0,
%	 adder_1_test/0,adder_2_test/0,
%	 stop_container_1_test/0,stop_container_2_test/0,
%	 misc_lib_1_test/0,misc_lib_2_test/0,
%	 init_tcp_test/0,tcp_1_test/0,tcp_2_test/0,
%	 tcp_3_test/0,
%	 dns_address_test/0,
%	 end_tcp_test/0]).

-export([test/0,init_test/0,start_container_1_test/0,start_container_2_test/0,
	 adder_1_test/0,adder_2_test/0,stop_adder_test/0,
	 stop_container_1_test/0,stop_container_2_test/0,
	 misc_lib_1_test/0,misc_lib_2_test/0,
	 init_tcp_test/0,
	 tcp_seq_server_start_stop/0,
	 tcp_par_server_start_stop/0,
	 tcp_2_test/0,
	 tcp_3_test/0,
	 end_tcp_test/0]).

%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,
	      start_container_1_test,
	      adder_1_test,
	      start_container_2_test,
	      adder_2_test,
	      stop_adder_test,
	      stop_container_1_test,
	      stop_container_2_test,
	      misc_lib_1_test,misc_lib_2_test,
	      init_tcp_test,
	      tcp_seq_server_start_stop,
	      tcp_par_server_start_stop,
	      tcp_2_test,
	      tcp_3_test,
	      end_tcp_test],
    test_support:execute(TestList,?MODULE,?TIMEOUT).
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
 %   ok=application:start(lib_service),
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
    pod:delete(node(),"pod_adder_1"),
    container:delete(Pod,"pod_adder_2",["adder_service"]),
    pod:delete(node(),"pod_adder_2"),
    pod:delete(node(),"pod_lib_2"),
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_master"),
    pod:delete(node(),"pod_master2"),
    {pong,_,lib_service}=lib_service:ping(),
    
    {ok,PodMaster}=pod:create(node(),"pod_master"),
    ok=container:create(PodMaster,"pod_master",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    ok=container:create(PodMaster,"pod_master",
			[{{service,"dns_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    timer:sleep(50),
    {pong,PodMaster,lib_service}=rpc:call(PodMaster,lib_service,ping,[],1000),
    {pong,PodMaster,dns_service}=rpc:call(PodMaster,dns_service,ping,[],1000),
    ok=rpc:call(PodMaster,lib_service,start_tcp_server,["localhost",42000,parallell],2000),
    {pong,PodMaster,lib_service}=tcp_client:call({"localhost",42000},{lib_service,ping,[]}),
    {pong,PodMaster,dns_service}=tcp_client:call({"localhost",42000},{dns_service,ping,[]}),
    
    ok.
    

%------------------ misc_lib -----------------------------------
misc_lib_1_test()->
    ok.

misc_lib_2_test()->
    {ok,Host}=inet:gethostname(),
    PodIdServer=?SERVER_ID++"@"++Host,
    PodServer=list_to_atom(PodIdServer),
    PodServer=misc_lib:get_node_by_id(?SERVER_ID), 
    ok.


%------------------ ceate and delete Pods and containers -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_container_1_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_1"),
    ok=container:create(PodAdder,"pod_adder_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    ok=rpc:call(PodAdder,lib_service,start_tcp_server,["localhost",50001,parallell],2000),
    ok=container:create(PodAdder,"pod_adder_1",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
       
    
    
   ok.

start_container_2_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_2"),
    ok=container:create(PodAdder,"pod_adder_2",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    ok=rpc:call(PodAdder,lib_service,start_tcp_server,["localhost",50002,parallell],2000),
    ok=container:create(PodAdder,"pod_adder_2",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    
   ok.
adder_1_test()->
%    glurk=lib_service:dns_address(),
    {DnsIpAddr,DnsPort}=lib_service:dns_address(),
  %  glurk=tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["adder_service"]}),
    [[IpAddr,Port,_Vm]|_]=tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["adder_service"]}),
    42=tcp_client:call({IpAddr,Port},{adder_service,add,[20,22]}),
    ok.

adder_2_test()->
    {DnsIpAddr,DnsPort}=lib_service:dns_address(),
  %  glurk=tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["adder_service"]}),
    [[IpAddr,Port,_Vm],[IpAddr2,Port2,_Vm2]]=tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["adder_service"]}),
    42=tcp_client:call({IpAddr,Port},{adder_service,add,[20,22]}),
    142=tcp_client:call({IpAddr2,Port2},{adder_service,add,[120,22]}),
    ok.
stop_adder_test()->
    
    {ok,stopped}=tcp_client:call({"localhost",50002},{lib_service,stop_tcp_server,["localhost",50002]}),
    {ok,stopped}=tcp_client:call({"localhost",50001},{lib_service,stop_tcp_server,["localhost",50001]}),
    {ok,stopped}=tcp_client:call({"localhost",42000},{lib_service,stop_tcp_server,["localhost",42000]}),
    {error,econnrefused}=tcp_client:call({"localhost",50002},{adder_service,add,[20,22]}),
    ok.
stop_container_1_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
   % timer:sleep(500),
 
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),
    ok.

stop_container_2_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_2"),
    container:delete(Pod,"pod_adder_2",["adder_service"]),
  %  timer:sleep(500),
    {ok,stopped}=pod:delete(node(),"pod_adder_2"),
    ok.

%------------------------------------------------------------





%**************************** tcp test   ****************************
init_tcp_test()->
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_lib_2"),
    {ok,Pod_1}=pod:create(node(),"pod_lib_1"),
    ok=container:create(Pod_1,"pod_lib_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    {ok,Pod_2}=pod:create(node(),"pod_lib_2"),
    ok=container:create(Pod_2,"pod_lib_2",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    ok.

tcp_seq_server_start_stop()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    ok=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52000,sequence]),
    {error,_}=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52000,sequence]),
    
    %Check my ip
    {"localhost",52000}=rpc:call(PodServer,lib_service,myip,[],1000),
     D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",52000},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,Socket1}=tcp_client:connect("localhost",52000),
    {ok,Socket2}=tcp_client:connect("localhost",52000),
    tcp_client:cast(Socket1,{erlang,date,[]}),
    tcp_client:cast(Socket2,{erlang,date,[]}),
    D=tcp_client:get_msg(Socket1,1000),
    {error,[tcp_timeout,_,tcp_client,_]}=tcp_client:get_msg(Socket2,1000),
    
    tcp_client:disconnect(Socket1),
    tcp_client:disconnect(Socket2),

    {ok,stopped}=rpc:call(PodServer,lib_service,stop_tcp_server,["localhost",52000],1000),
    {error,econnrefused}=tcp_client:connect("localhost",52000),
    {error,econnrefused}=tcp_client:call({"localhost",52000},{erlang,date,[]}),
    ok.
% funkar hit 
tcp_par_server_start_stop()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    ok=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52001,parallell]),
    {error,_}=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52001,parallell]),
    
    %Check my ip
    {"localhost",52001}=rpc:call(PodServer,lib_service,myip,[],1000),
     D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",52001},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,Socket1}=tcp_client:connect("localhost",52001),
    {ok,Socket2}=tcp_client:connect("localhost",52001),
    tcp_client:cast(Socket1,{erlang,date,[]}),
    tcp_client:cast(Socket2,{erlang,date,[]}),
    D=tcp_client:get_msg(Socket1,1000),
    D=tcp_client:get_msg(Socket2,1000),
    
    tcp_client:disconnect(Socket1),
    tcp_client:disconnect(Socket2),

    {ok,stopped}=rpc:call(PodServer,lib_service,stop_tcp_server,["localhost",52001],1000),
    {error,econnrefused}=tcp_client:connect("localhost",52001),
    {error,econnrefused}=tcp_client:call({"localhost",52001},{erlang,date,[]}),
    ok.


tcp_2_test()->
    Pod_1=misc_lib:get_node_by_id("pod_lib_1"),
%    Pod_2=misc_lib:get_node_by_id("pod_lib_2"),
    ok=rpc:call( Pod_1,lib_service,start_tcp_server,["localhost",53000,parallell]),
%    {pong,pod_test_1@asus,lib_service}=lib_service:ping(),
    {error,[eexists,dns_service,{"localhost",42000},{error,econnrefused},
	    lib_service,_]}=lib_service:dns_address(),
    {error,[eexists,dns_service,{"localhost",42000},{error,econnrefused},
	    lib_service,_]}=tcp_client:call({"localhost",53000},{lib_service,dns_address,[]}),
    {ok,PodMaster}=pod:create(node(),"pod_master2"),
    ok=container:create(PodMaster,"pod_master2",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    ok=container:create(PodMaster,"pod_master2",
			[{{service,"dns_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    
    ok=rpc:call(PodMaster,lib_service,start_tcp_server,["localhost",42000,parallell]),
    {pong,PodMaster,lib_service}=tcp_client:call({"localhost",42000},{lib_service,ping,[]}),
    {pong,PodMaster,dns_service}=tcp_client:call({"localhost",42000},{dns_service,ping,[]}),
    
    {"localhost",42000}=tcp_client:call({"localhost",53000},{lib_service,dns_address,[]}),
    {"localhost",42000}=lib_service:dns_address(),
    {ok,Socket}=tcp_client:connect("localhost",53000),
    %tcp_client:cast(PidSession,{erlang,date,[]}),
    loop_send(2,Socket),
    _R1=loop_get(2,Socket,[]),
    loop_send2(2,Socket,Pod_1),
    _R2=loop_get(2,Socket,[]),
    tcp_client:disconnect(Socket),
    {ok,stopped}=rpc:call(Pod_1,lib_service,stop_tcp_server,["localhost",53000]),
    {ok,stopped}=rpc:call(PodMaster,lib_service,stop_tcp_server,["localhost",42000]),
    
    ok.

tcp_3_test()->
    Pod_1=misc_lib:get_node_by_id("pod_lib_1"),
    ok=rpc:call(Pod_1,lib_service,start_tcp_server,["localhost",54000,sequence]),
    do_call(2,"localhost",54000),
    {ok,stopped}=rpc:call(Pod_1,lib_service,stop_tcp_server,["localhost",54000]),
    ok.
    
do_call(0,_,_)->
    ok;
do_call(N,IpAddr,Port) ->
    D=date(),
    D=tcp_client:call({IpAddr,Port},{erlang,date,[]}),
    do_call(N-1,IpAddr,Port).

loop_send2(0,_,_)->
    ok;
loop_send2(N,Socket,Pod) ->
    tcp_client:cast(Socket,{erlang,date,[]}),
    loop_send2(N-1,Socket,Pod).
loop_send(0,_)->
    ok;
loop_send(N,Socket) ->
    tcp_client:cast(Socket,{erlang,date,[]}),
    loop_send(N-1,Socket).
loop_get(0,_Socket,Result)->
    Result;
loop_get(N,Socket,Acc) ->
    loop_get(N-1,Socket,[{N,tcp_client:get_msg(Socket,100)}|Acc]).
    
end_tcp_test()->
    container:delete('pod_lib_1@asus.com',"pod_adder_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_1"),
    container:delete('pod_lib_2@asus.com',"pod_adder_2",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_2"),
    {ok,stopped}=pod:delete(node(),"pod_master"),
    {ok,stopped}=pod:delete(node(),"pod_master2"),
    ok.


%**************************************************************
