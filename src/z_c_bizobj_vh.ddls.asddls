@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Object - Value Help'
@Search.searchable: true
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_C_BIZOBJ_VH
  as select from zsap20_biz_obj
{
      @Search.defaultSearchElement: true
  key bo_id    as BoId,
      @Search.defaultSearchElement: true
      bo_title as BoTitle,
      @Search.defaultSearchElement: true
      bo_type  as BoType,
      
      status   as Status
}
