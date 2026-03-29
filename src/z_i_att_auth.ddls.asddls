@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Authentication - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_ATT_AUTH
  as select from zsap20_att_auth
{
  key uname as Uname,
      role  as Role,
      erdat as Erdat,
      ernam as Ernam
}
