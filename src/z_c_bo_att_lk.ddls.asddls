@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Object - Link Attachment - Projection View'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_C_BO_ATT_LK as projection on Z_I_BO_ATT_LK
{
    key BoId,
    key FileId,
    Erdat,
    Erzet,
    Ernam,
    /* Associations */
    _Attach: redirected to Z_C_ATTACH,
    _Bo     : redirected to parent Z_C_BIZ_OBJ
}
