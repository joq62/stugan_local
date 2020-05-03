-define(CLIENT_TIMEOUT,6*1000).


-define(MASTER_NODEID,"pod_master").
-define(NODE_CONFIG,"node.config").
-define(APP_SPEC,"app.spec").
-define(CATALOG_INFO,"catalog.info").

-record(syslog_info,{date,
		     time,
		     ip_addr,
		     port,
		     pod,
		     module,
		     line,
		     severity,
		     message
		    }).

-record(node_info,{
	  vm_name,
	  vm,
	  ip_addr,
	  port,
	  mode,
	  status
	 }).

-record(app_list,{
	  service,
	  ip_addr,
	  port,
	  status
	 }).

-record(app_info,{
	  service,
	  num,
	  nodes,
	  source,
	  status
	 }).

% test
-ifdef(unit_test).
-define(TEST,unit_test).
-endif.
-ifdef(system_test).
-define(TEST,system_test).
-endif.

% dns_address
-ifdef(public).
-define(DNS_ADDRESS,{"joqhome.dynamic-dns.net",40000}).
-endif.
-ifdef(private).
-define(DNS_ADDRESS,{"192.168.0.100",40000}).
-endif.
-ifdef(local).
-define(DNS_ADDRESS,{"localhost",40000}).
-endif.
-ifndef(DNS_ADDRESS).
-define(DNS_ADDRESS,{"192.168.0.100",40000}).
-endif.
% Heartbeat
-ifdef(unit_test).
-define(HB_TIMEOUT,20*1000).
-else.
-define(HB_TIMEOUT,1*60*1000).
-endif.



%compiler
