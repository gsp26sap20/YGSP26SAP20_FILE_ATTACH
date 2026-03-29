@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Obj - Link Att - Interface view'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z_I_BO_ATT_LK
  as select from zsap20_bo_att_lk as lk

  association to parent Z_I_BIZ_OBJ_R as _Bo
    on $projection.BoId = _Bo.BoId

  association [1..1] to Z_I_ATTACH_R as _Attach
      on $projection.FileId = _Attach.FileId
{
  key lk.bo_id   as BoId,
  key lk.file_id as FileId,

      lk.erdat as Erdat,
      lk.erzet as Erzet,
      lk.ernam as Ernam,

      _Bo,
      _Attach
}
