@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Config Overview Stats'
define view entity Z_C_CFG_OVERVIEW
  as select from zsap20_att_cfg as C
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key cast( '1' as abap.char(1) ) as OverviewKey,
      count( * ) as TotalConfigs,
      sum( case when C.is_active = 'X' then 1 else 0 end ) as ActiveConfigs
}
