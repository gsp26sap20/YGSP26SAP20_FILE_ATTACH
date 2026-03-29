@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment - Root View Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_ATTACH_R
  as select from    zsap20_file_mgmt as m
    left outer join zsap20_att_auth  as au on au.uname = $session.user
  composition [0..*] of Z_I_ATTACH_VER as _Versions
  composition [0..*] of Z_I_ATT_AUDIT  as _Audit
  association [0..1] to Z_I_ATTACH_VER as _CurrentVersion on  $projection.FileId         = _CurrentVersion.FileId
                                                          and $projection.CurrentVersion = _CurrentVersion.VersionNo
   association [0..*] to Z_I_BO_ATT_LK  as _Links
   on $projection.FileId = _Links.FileId                                                        
{
  key m.file_id         as FileId,
      m.title           as Title,
      m.current_version as CurrentVersion,
      m.is_active       as IsActive,
      m.erdat           as Erdat,
      m.erzet           as Erzet,
      m.ernam           as Ernam,
      m.aedat           as Aedat,
      m.aezet           as Aezet,
      m.aenam           as Aenam,
      m.edit_lock       as EditLock,
      _Versions,
      _Audit,
      _CurrentVersion,
      _Links
}
where
     m.is_active = 'X'
  or au.role     = 'ADMIN'
