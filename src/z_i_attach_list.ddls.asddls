@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment for List - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z_I_ATTACH_LIST as select from zsap20_file_mgmt as m
join zsap20_file_ver as v on v.file_id = m.file_id and v.version_no  = m.current_version
{
  key v.file_id as FileId,
  v.version_no as VersionNo,
  v.file_name as FileName,
  v.file_extension as FileExtension,
  v.mime_type as MimeType,
  v.file_size as FileSize,
//  v.file_content as FileContent,
  v.erdat as Erdat,
  v.erzet as Erzet,
  v.ernam as Ernam,
  m.title as Title,
  m.current_version as CurrentVersion,
  m.is_active as IsActive,
  m.aenam as F_Aenam  
}
//where m.is_active <> 'X'
