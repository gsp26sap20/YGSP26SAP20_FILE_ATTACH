@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Version - Projection Views'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z_C_ATTACH_VER as projection on Z_I_ATTACH_VER
{
    key FileId,
    key VersionNo,
    FileName,
    FileExtension,
    MimeType,
    FileSize,
    FileContent, 
    Erdat,
    Erzet,
    Ernam,
    /* Associations */
    _Attachment : redirected to parent Z_C_ATTACH
}
