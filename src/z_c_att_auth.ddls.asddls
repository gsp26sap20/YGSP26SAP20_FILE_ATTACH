@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Authentication - Projection View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_C_ATT_AUTH
  as projection on Z_I_ATT_AUTH
{
  key Uname,
      Role,
      Erdat,
      Ernam
}
