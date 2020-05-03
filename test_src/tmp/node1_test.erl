%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(node1_test).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").

%% --------------------------------------------------------------------
-compile(export_all).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:emulate loader
%% Description: requires pod+container module
%% Returns: non
%% --------------------------------------------------------------------
start()->
    ?assertEqual(ok,node_test()),   
    
    ok.

%% --------------------------------------------------------------------
%% Function:emulate loader
%% Description: requires pod+container module
%% Returns: non
%% --------------------------------------------------------------------
node_test()->
    create_delete_pod().


create_delete_pod()->
    %% Typical sequence to create a pod
    %% Create the Pod, load lib_service , start assigne tcp_server 
    %% 
    pod:delete("pod_lib_1"),  
   {ok,Pod}=pod:create("pod_lib_1"),    
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    ?assertEqual(PodServer,Pod),
    ?assertEqual(ok,container:create("pod_lib_1",
		     [{{service,"adder_service"},
		       {dir,"/home/pi/erlang/basic"}}
		     ])),
    timer:sleep(100),
    ?assertEqual(42,rpc:call(Pod,adder_service,add,[20,22])),

    %% FRom github 
    ?assertEqual(ok,container:create("pod_lib_1",
		     [{{service,"divi_service"},
		       {git,"https://github.com/joq62/basic.git"}}
		     ])),
  %  ?debugMsg("check if basic is present "),
    timer:sleep(100),
    ?assertEqual(24.0,rpc:call(Pod,divi_service,divi,[240,10])),

    %% ---- delete container ------------------------------------------------
    ?assertEqual([ok],container:delete("pod_lib_1",["adder_service"])),
    ?assertMatch({badrpc,_},rpc:call(Pod,adder_service,add,[20,22])),

    %%---- Delete pod -------------------------------------------------------
    D=date(),
    ?assertEqual(D,rpc:call(Pod,erlang,date,[])),
    ?assertEqual({ok,stopped},pod:delete("pod_lib_1")),
    ?assertEqual({badrpc,nodedown},rpc:call(Pod,erlang,date,[])),    
    ok.
