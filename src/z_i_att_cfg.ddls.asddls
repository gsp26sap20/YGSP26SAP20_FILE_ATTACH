@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Config - Interface View'
define root view entity Z_I_ATT_CFG
  as select from zsap20_att_cfg
{
  key file_ext     as FileExt,
      mime_type    as MimeType,
      max_bytes    as MaxBytes,
      is_active    as IsActive,
      description  as Description,
      type         as Type  
      
}
