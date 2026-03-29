@EndUserText.label: 'Parameter for Link Attachment'
define abstract entity Z_A_LINK_ATT_P
{
  @Consumption.valueHelpDefinition: [
    {
      entity: {
        name    : 'Z_C_ATTACH_VH',
        element : 'FileId'
      }
    }
  ]
  file_id : sysuuid_x16;
}
