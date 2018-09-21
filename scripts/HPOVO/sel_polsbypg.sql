-- ***********************************************************************
-- Querry that gets list of policies in policy groups
-- Written by pasvel (et4956@edb.com)
-- ***********************************************************************

select
  pga.PolicyId
from
  openview.dbo.OV_PM_PolicyGroupAssignment pga
where
  pga.GroupId = (
	select
	  pg.GroupId
	from
	  openview.dbo.OV_PM_PolicyGroup pg
	where
	  pg.Name = '&1'
);
