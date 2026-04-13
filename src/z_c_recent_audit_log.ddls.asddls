@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Recent Attachment Audit Logs'
define view entity Z_C_RECENT_AUDIT_LOG
  as select from zsap20_att_audit as AU
    inner join Z_I_CURR_ADMIN as A
      on A.Uname = $session.user
{
  key AU.file_id as FileId,
  key AU.erdat   as Erdat,
  key AU.erzet   as Erzet,
      AU.uname   as Uname,
      AU.action  as Action,
      AU.note    as Note,
      AU.ernam   as Ernam
}
