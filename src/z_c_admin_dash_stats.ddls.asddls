@EndUserText.label: 'Admin Dashboard Statistics'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_ADMIN_DASH_STATS_PROVIDER'
define custom entity Z_C_ADMIN_DASH_STATS
{
  key OverviewKey                 : abap.char(1);

      AttachmentsCreatedDay       : abap.int4;
      AttachmentsCreatedWeek      : abap.int4;
      AttachmentsCreatedMonth     : abap.int4;
      AttachmentsCreatedYear      : abap.int4;

      BoCreatedDay                : abap.int4;
      BoCreatedWeek               : abap.int4;
      BoCreatedMonth              : abap.int4;
      BoCreatedYear               : abap.int4;

      LinksCreatedDay             : abap.int4;
      LinksCreatedWeek            : abap.int4;
      LinksCreatedMonth           : abap.int4;
      LinksCreatedYear            : abap.int4;

      DeletedAttachmentsDay       : abap.int4;
      DeletedAttachmentsWeek      : abap.int4;
      DeletedAttachmentsMonth     : abap.int4;
      DeletedAttachmentsYear      : abap.int4;

      ReactivatedAttachmentsDay   : abap.int4;
      ReactivatedAttachmentsWeek  : abap.int4;
      ReactivatedAttachmentsMonth : abap.int4;
      ReactivatedAttachmentsYear  : abap.int4;

      UnlinkedAttachments         : abap.int4;
      BoWithoutAttachments        : abap.int4;
}
