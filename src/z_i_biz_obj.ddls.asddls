@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Object - Interface view'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z_I_BIZ_OBJ as select from zsap20_biz_obj
{
    key bo_id as BoId,
    bo_type as BoType,
    bo_title as BoTitle,
    status as Status,
    erdat as Erdat,
    erzet as Erzet,
    ernam as Ernam,
    aedat as Aedat,
    aezet as Aezet,
    aenam as Aenam
}
