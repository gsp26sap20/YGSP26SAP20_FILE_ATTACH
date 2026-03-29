@EndUserText.label: 'Parameter for Link to BO'
define abstract entity Z_A_LINK_BO_P
{
  @Consumption.valueHelpDefinition: [
    {
      entity: {
        name    : 'Z_C_BIZOBJ_VH',
        element : 'BoId'
      }
    }
  ]
  bo_id : zgsp26sap20_bo_id;
}
