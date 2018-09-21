REM ***********************************************************************
REM Querry that get node's layout group by name (not label!)
REM Written by pasvel (et4956@edb.com) 
REM ***********************************************************************

set heading off
set echo off
set feedback off
set verify off

select
  h.name
from
  opc_nodehier_layout h
where
  h.layout_id = (
    select
      h.parent_id
    from
      opc_node_names nn,
      opc_nodehier_layout h
    where
      nn.node_name = '&1'
      and nn.node_id = h.node_id
  );
