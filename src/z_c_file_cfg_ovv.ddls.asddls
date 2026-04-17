@AccessControl.authorizationCheck: #NOT_REQUIRED @EndUserText.label: 'File Config Overview'
define view entity Z_C_FILE_CFG_OVV
  as select from Z_I_ATT_CFG as C
    inner join   Z_I_CURR_ADMIN as A on A.Uname = $session.user
{
  key C.FileExt,
      C.MimeType,
      C.MaxBytes,
      C.IsActive,
      C.Description
}
