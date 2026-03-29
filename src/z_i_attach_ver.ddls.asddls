@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Version - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define view entity Z_I_ATTACH_VER
  as select from zsap20_file_ver as v
  association to parent Z_I_ATTACH_R as _Attachment
    on $projection.FileId = _Attachment.FileId
{
    key v.file_id as FileId,
    key v.version_no as VersionNo,
        v.file_name as FileName,
        v.file_extension as FileExtension,
        v.mime_type as MimeType,
        v.file_size as FileSize,
        v.file_content as FileContent,
        v.erdat as Erdat,
        v.erzet as Erzet,
        v.ernam as Ernam,

        /* association */
        _Attachment
}
