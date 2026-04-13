@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Link Overview Stats'
define view entity Z_C_LINK_OVERVIEW
  as select from zsap20_bo_att_lk as L
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key cast( '1' as abap.char(1) ) as OverviewKey,
      count( * ) as TotalLinks
}
