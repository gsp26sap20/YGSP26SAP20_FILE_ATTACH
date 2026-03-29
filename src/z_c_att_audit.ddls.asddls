@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Audit - Projection Views'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_C_ATT_AUDIT as projection on Z_I_ATT_AUDIT
{
    key FileId,
    key Erdat,
    key Erzet,
    key Uname,
    Action,
    Note,
    Ernam,
    /* Associations */
    _Attachment : redirected to parent Z_C_ATTACH
}
