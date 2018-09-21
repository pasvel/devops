select
  nga.object_text
from
  openview.dbo.sto_ov_nodegroupautodeploypolicygroupassoc nga
where
  nga.object_text like '%' + (
	select
	  ng.name	  
	from
	  openview.dbo.sto_ov_nodegroup	ng
	where
	  ng.object_text LIKE '%Caption = "&1";%'	  
) + '%';
