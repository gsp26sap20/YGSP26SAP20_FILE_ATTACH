@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Overview Stats'
define view entity Z_C_ATT_OVERVIEW
  as select from zsap20_file_mgmt as F
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key cast( '1' as abap.char(1) ) as OverviewKey,
      count( * ) as TotalAttachments,
      sum( case when F.is_active = 'X' then 1 else 0 end ) as ActiveAttachments,
      sum( case when F.is_active = ''  then 1 else 0 end ) as InactiveAttachments
}
