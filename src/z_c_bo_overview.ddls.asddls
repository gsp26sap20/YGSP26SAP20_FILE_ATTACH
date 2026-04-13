@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Object Overview Stats'
define view entity Z_C_BO_OVERVIEW
  as select from zsap20_biz_obj as B
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key cast( '1' as abap.char(1) ) as OverviewKey,
      count( * ) as TotalBusinessObjects
}
