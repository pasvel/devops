select
  label,node_id,agent_id
from
  opc_nodes
where
  agent_id in (
	select
	  agent_id
	from
	  opc_nodes
	where
	  agent_id='&1'
  );
