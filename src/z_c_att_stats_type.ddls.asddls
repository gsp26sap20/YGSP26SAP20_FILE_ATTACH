@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Stats By Type'
define view entity Z_C_ATT_STATS_TYPE
  as select from Z_I_ATT_VER_NORM as V
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key V.FileExtNorm as FileExt,
      count( * )    as VersionCount,
      sum( V.FileSize ) as TotalSize
}
group by V.FileExtNorm
