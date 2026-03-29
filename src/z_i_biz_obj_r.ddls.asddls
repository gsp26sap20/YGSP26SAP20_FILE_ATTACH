@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Object - Root View Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_BIZ_OBJ_R
  as select from zsap20_biz_obj as bo

    composition [0..*] of Z_I_BO_ATT_LK as _Links
{
    
      key bo.bo_id       as BoId,
      bo.bo_type     as BoType,
      bo.bo_title    as BoTitle,
      bo.status      as Status,

      bo.erdat       as Erdat,
      bo.erzet       as Erzet,
      bo.ernam       as Ernam,
      bo.aedat       as Aedat,
      bo.aezet       as Aezet,
      bo.aenam       as Aenam,

      _Links
}
