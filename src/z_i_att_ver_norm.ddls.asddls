@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Version Normalized'
define view entity Z_I_ATT_VER_NORM
  as select from zsap20_file_ver
{
  key file_id                    as FileId,
  key version_no                 as VersionNo,
      upper( file_extension )    as FileExtNorm,
      file_size                  as FileSize
}
