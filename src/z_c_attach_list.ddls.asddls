@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment for List - Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z_C_ATTACH_LIST
  as select from Z_I_ATTACH_LIST
{
  key FileId,
      VersionNo,
      FileName,
      FileExtension,
      MimeType,
      FileSize,
      Erdat,
      Erzet,
      Ernam,
      Title,
      CurrentVersion,
      IsActive,
      F_Aenam
}
