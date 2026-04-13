@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Authorization Overview Stats'
define view entity Z_C_AUTH_OVERVIEW
  as select from zsap20_att_auth as U
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key cast( '1' as abap.char(1) ) as OverviewKey,
      sum( case when U.role = 'ADMIN' then 1 else 0 end ) as AdminCount,
      sum( case when U.role = 'USER'  then 1 else 0 end ) as UserCount
}
