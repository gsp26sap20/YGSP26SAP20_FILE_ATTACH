@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Current Admin Authorization'
define view entity Z_I_CURR_ADMIN
  as select from zsap20_att_auth
{
  key uname as Uname,
      role  as Role
}
where uname = $session.user
  and role  = 'ADMIN'
