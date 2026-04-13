@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Current User Role - Projection View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_C_CURRENT_USER_ROLE
  as projection on Z_I_CURRENT_USER_ROLE
{
  key Uname,
      Role
}
