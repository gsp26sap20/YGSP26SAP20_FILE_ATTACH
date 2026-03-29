@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@EndUserText.label: 'Attachment - Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_C_ATTACH_VH
  as select from zsap20_file_mgmt
{
  key file_id         as FileId,
      @Search.defaultSearchElement: true
      title           as Title,
      current_version as CurrentVersion,
      is_active       as IsActive,
      erdat           as Erdat,
      @Search.defaultSearchElement: true
      ernam           as Ernam
}
where
  is_active = 'X'
