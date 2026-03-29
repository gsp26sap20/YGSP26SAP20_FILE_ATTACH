*&---------------------------------------------------------------------*
*& Report zsap20_fill_att_cfg
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsap20_fill_att_cfg.

DATA: lt_cfg TYPE TABLE OF zsap20_att_cfg,
      ls_cfg TYPE zsap20_att_cfg.

DELETE FROM zsap20_att_cfg.

CLEAR ls_cfg.
ls_cfg-mandt = sy-mandt.
ls_cfg-file_ext = 'pdf'.
ls_cfg-mime_type = 'application/pdf'.
ls_cfg-max_bytes = 15728640.
ls_cfg-is_active = 'X'.
ls_cfg-description = 'PDF document'.
APPEND ls_cfg TO lt_cfg.

CLEAR ls_cfg.
ls_cfg-mandt = sy-mandt.
ls_cfg-file_ext = 'png'.
ls_cfg-mime_type = 'image/png'.
ls_cfg-max_bytes = 5242880.
ls_cfg-is_active = 'X'.
ls_cfg-description = 'PNG image'.
APPEND ls_cfg TO lt_cfg.

CLEAR ls_cfg.
ls_cfg-mandt = sy-mandt.
ls_cfg-file_ext = 'jpg'.
ls_cfg-mime_type = 'image/jpeg'.
ls_cfg-max_bytes = 5242880.
ls_cfg-is_active = 'X'.
ls_cfg-description = 'JPG image'.
APPEND ls_cfg TO lt_cfg.

CLEAR ls_cfg.
ls_cfg-mandt = sy-mandt.
ls_cfg-file_ext = 'jpeg'.
ls_cfg-mime_type = 'image/jpeg'.
ls_cfg-max_bytes = 5242880.
ls_cfg-is_active = 'X'.
ls_cfg-description = 'JPEG image'.
APPEND ls_cfg TO lt_cfg.

CLEAR ls_cfg.
ls_cfg-mandt = sy-mandt.
ls_cfg-file_ext = 'docx'.
ls_cfg-mime_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'.
ls_cfg-max_bytes = 10485760.
ls_cfg-is_active = 'X'.
ls_cfg-description = 'Word document'.
APPEND ls_cfg TO lt_cfg.

CLEAR ls_cfg.
ls_cfg-mandt = sy-mandt.
ls_cfg-file_ext = 'txt'.
ls_cfg-mime_type = 'text/plain'.
ls_cfg-max_bytes = 10485760.
ls_cfg-is_active = 'X'.
ls_cfg-description = 'Text file'.
APPEND ls_cfg TO lt_cfg.

CLEAR ls_cfg.
ls_cfg-mandt = sy-mandt.
ls_cfg-file_ext = 'xlsx'.
ls_cfg-mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
ls_cfg-max_bytes = 10485760.
ls_cfg-is_active = 'X'.
ls_cfg-description = 'Excel file'.
APPEND ls_cfg TO lt_cfg.

INSERT zsap20_att_cfg FROM TABLE lt_cfg.

COMMIT WORK.

WRITE: / 'ZSAP20_ATT_CFG has been filled successfully.'.
