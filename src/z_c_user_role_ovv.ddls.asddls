@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'User Role Overview'
define view entity Z_C_USER_ROLE_OVV
  as select from zsap20_att_auth as U
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key U.role   as Role,
      count( * ) as UserCount
}
group by U.role
