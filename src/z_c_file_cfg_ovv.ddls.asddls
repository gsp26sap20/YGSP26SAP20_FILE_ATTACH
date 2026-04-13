@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'File Config Overview'
define view entity Z_C_FILE_CFG_OVV
  as select from zsap20_att_cfg as C
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key C.file_ext    as FileExt,
      C.mime_type   as MimeType,
      C.max_bytes   as MaxBytes,
      C.is_active   as IsActive,
      C.description as Description
}
