@EndUserText.label: 'Attachment Download DTO'
define abstract entity Z_I_ATTACH_DOWNLOAD 
{
  key FileId        : sysuuid_x16;
  key VersionNo     : abap.numc(3);

  FileName          : abap.char(255);
  FileExtension     : abap.char(10);
  MimeType          : abap.char(128);
  FileSize          : abap.int8;
  FileContent       : abap.string;
  Erdat             : abap.dats;
  Erzet             : abap.tims;
  Ernam             : abap.char(12);
}
