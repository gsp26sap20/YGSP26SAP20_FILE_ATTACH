@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment Authentication - Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define root view entity Z_C_ATT_AUTH
  as projection on Z_I_ATT_AUTH
{
      @Search.defaultSearchElement: true
      @Search.ranking: #HIGH
      @Search.fuzzinessThreshold: 0.9
  key Uname,
      Role,
      Erdat,
      @Search.defaultSearchElement: true
      @Search.ranking: #MEDIUM
      @Search.fuzzinessThreshold: 0.9
      Ernam
}
