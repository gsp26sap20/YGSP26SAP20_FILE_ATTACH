@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Current User Role - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_CURRENT_USER_ROLE
  as select from zsap20_att_auth
{
  key uname as Uname,
      role  as Role
}
where uname = $session.user
