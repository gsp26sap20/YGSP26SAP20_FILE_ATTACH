@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Config - Projection View'
@Search.searchable: true
define root view entity Z_C_ATT_CFG
  provider contract transactional_query
  as projection on Z_I_ATT_CFG
{
      @Search.defaultSearchElement: true
      @Search.ranking: #HIGH
      @Search.fuzzinessThreshold: 0.9
  key FileExt,
      @Search.defaultSearchElement: true
      @Search.ranking: #HIGH
      @Search.fuzzinessThreshold: 0.9
      MimeType,
      MaxBytes,
      IsActive,
      @Search.defaultSearchElement: true
      @Search.ranking: #MEDIUM
      @Search.fuzzinessThreshold: 0.9
      Description,
      Type
}
