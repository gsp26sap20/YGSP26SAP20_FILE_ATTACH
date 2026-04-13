@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Stats By Type'
define view entity Z_C_ATT_STATS_TYPE
  as select from zsap20_file_ver as V
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key V.file_extension as FileExt,
      count( * )       as VersionCount,
      sum( V.file_size ) as TotalSize
}
group by V.file_extension
