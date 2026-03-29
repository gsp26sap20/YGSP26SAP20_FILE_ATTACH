@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Audit - Interface Views'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z_I_ATT_AUDIT as select from zsap20_att_audit
association to parent Z_I_ATTACH_R as _Attachment
    on $projection.FileId = _Attachment.FileId
{
  key file_id as FileId,
  key erdat   as Erdat,
  key erzet   as Erzet,
  key uname   as Uname,
      action  as Action,
      note    as Note,
      ernam   as Ernam,
      _Attachment
}
