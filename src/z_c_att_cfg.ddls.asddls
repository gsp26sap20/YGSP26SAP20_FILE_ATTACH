@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Config - Projection View'
define root view entity Z_C_ATT_CFG
  provider contract transactional_query
  as projection on Z_I_ATT_CFG
{
  key FileExt,
      MimeType,
      MaxBytes,
      IsActive,
      Description,
      Type
}
