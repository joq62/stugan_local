%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(start_test_system).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
-include("../test_src/master_service_tests.hrl").

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
    start_nodes(),
    ok=application:start(master_service),
    dns_service:add("master_service","localhost",40000),
    timer:sleep(10*1000),
    check_nodes(),
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
check_nodes()->
    NodesInfo=master_service:nodes(),
   
    ?assertMatch([],
		 lib_master:check_missing_nodes(NodesInfo)),
 %   ?assertMatch(glurk,dns_service:all()),
    ok.
    



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
start_nodes()->
    %% Start lib_service and tcp_server for pod_master 
    ok=application:start(dns_service),    
    dns_service:add("dns_service","localhost",40000),
    ok=application:start(log_service),    
    dns_service:add("log_service","localhost",40000),

    ok=application:start(lib_service),    
    lib_service:start_tcp_server("localhost",40000,parallell), 
    D=date(),
    ?assertEqual(D,tcp_client:call({"localhost",40000},{erlang,date,[]})),
    %% Create worker pods 
    {ok,NodeList}=file:consult(?NODE_CONFIG),
    WorkerList=[{NodeId,Node,IpAddr,Port,Mode}||{NodeId,Node,IpAddr,Port,Mode}<-NodeList,
						NodeId=/="master"],
    IpInfoComputer={"localhost",40000},
    NeededServices=[{{service,"lib_service"},{dir,?SOURCE}}],
    ?assertMatch([ok,ok],[start_pod(NodeId,IpAddrPod,PortPod,ModePod,NeededServices)
		     ||{NodeId,_Node,IpAddrPod,PortPod,ModePod}<-WorkerList]),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
start_pod(NodeId,IpAddrPod,PortPod,ModePod,NeededServices)->
    {ok,Node}=pod:create(NodeId),    
    [container:create(NodeId,
		     [NeededService])||NeededService<-NeededServices],

    R=rpc:call(Node,lib_service,start_tcp_server,[IpAddrPod,PortPod,ModePod]),
    timer:sleep(1000),
    R.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
start_test_pod_glurk(NodeId,IpAddrPod,PortPod,ModePod,NeededServices)->
   % Create Pod
    {ok,Node}=pod:create(NodeId),
    D=date(),
    D=rpc:call(Node,erlang,date,[]),

    os:cmd("mkdir "++filename:join(NodeId,"ebin")),
    []=os:cmd("cp -r "++filename:join(?SOURCE,"include")++" "++NodeId),    
    Paths=[filename:join([?SOURCE,ServiceId])||ServiceId<-NeededServices],
    [os:cmd("cp -r "++Path++" "++NodeId)||Path<-Paths],
    [os:cmd("erlc -I "
	    ++?SOURCE++"/include"
	    ++" -o "++filename:join(NodeId,"ebin")
	    ++" "
	    ++filename:join([NodeId,ServiceId,"src/*.erl"]))
	    ||ServiceId<-NeededServices],

    [os:cmd("cp "++Path++"/src/*.app"++" "++NodeId++"/ebin")||Path<-Paths],

    true=rpc:call(Node,code,add_path,[filename:join(NodeId,"ebin")]),
    R1=[{Node,list_to_atom(ServiceId),rpc:call(Node,application,start,[list_to_atom(ServiceId)])}||ServiceId<-NeededServices],   
    R=rpc:call(Node,lib_service,start_tcp_server,[IpAddrPod,PortPod,ModePod]),
    
    timer:sleep(1000),
    R.
  %  ok.
    
