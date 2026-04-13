@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Object - Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z_C_BIZ_OBJ
  as projection on Z_I_BIZ_OBJ_R
{
  key BoId,
      @Search.defaultSearchElement: true
      @Search.ranking: #MEDIUM
      BoType,
      @Search.defaultSearchElement: true
      @Search.ranking: #HIGH
      @Search.fuzzinessThreshold: 0.8
      BoTitle,
      @Search.defaultSearchElement: true
      @Search.ranking: #MEDIUM
      Status,
      Erdat,
      Erzet,
      @Search.defaultSearchElement: true
      @Search.ranking: #MEDIUM
      Ernam,
      Aedat,
      Aezet,
      Aenam,
      /* Associations */
      _Links : redirected to composition child Z_C_BO_ATT_LK
}
