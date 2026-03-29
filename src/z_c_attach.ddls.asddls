@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment - Projection Views'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z_C_ATTACH as projection on Z_I_ATTACH_R
{
    key FileId,
    @Search.defaultSearchElement: true
    Title,
    CurrentVersion,
    IsActive,
    Erdat,
    Erzet,
    @Search.defaultSearchElement: true
    Ernam,
    Aedat,
    Aezet,
    Aenam,
    EditLock,
    /* Associations */
    _Versions : redirected to composition child Z_C_ATTACH_VER,
    _Audit : redirected to composition child Z_C_ATT_AUDIT,
    _CurrentVersion : redirected to Z_C_ATTACH_VER,
    _Links : redirected to Z_C_BO_ATT_LK
}
