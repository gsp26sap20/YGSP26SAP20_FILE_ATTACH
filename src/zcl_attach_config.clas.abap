*CLASS zcl_attach_config DEFINITION
*  PUBLIC FINAL CREATE PUBLIC.
*
*  PUBLIC SECTION.
*
*    "========================
*    " Extension
*    "========================
*    CONSTANTS:
*      c_ext_pdf  TYPE string VALUE 'pdf',
*      c_ext_png  TYPE string VALUE 'png',
*      c_ext_jpg  TYPE string VALUE 'jpg',
*      c_ext_jpeg TYPE string VALUE 'jpeg',
*      c_ext_docx TYPE string VALUE 'docx',
*      c_ext_txt TYPE string VALUE 'txt',
*      c_ext_xlsx TYPE string VALUE 'xlsx'.
*
*    "========================
*    " MIME
*    "========================
*    CONSTANTS:
*      c_mime_pdf  TYPE string VALUE 'application/pdf',
*      c_mime_txt  TYPE string VALUE 'text/plain',
*      c_mime_png  TYPE string VALUE 'image/png',
*      c_mime_jpeg TYPE string VALUE 'image/jpeg',
*      c_mime_docx TYPE string VALUE 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
*      c_mime_xlsx TYPE string VALUE 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
*
*    "========================
*    " Types
*    "========================
*    TYPES tt_string_set TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
*
*    TYPES: BEGIN OF ts_ext_limit,
*             ext       TYPE string,
*             max_bytes TYPE i,
*           END OF ts_ext_limit.
*    TYPES tt_ext_limit TYPE HASHED TABLE OF ts_ext_limit WITH UNIQUE KEY ext.
*    CLASS-METHODS allowed_extensions RETURNING VALUE(rt) TYPE tt_string_set.
*    CLASS-METHODS allowed_mime_types RETURNING VALUE(rt) TYPE tt_string_set.
*
*    "Return configured size limits (per extension)
*    CLASS-METHODS extension_size_limits RETURNING VALUE(rt) TYPE tt_ext_limit.
*
*    "Convenience: get max bytes for an extension (0 = not configured)
*    CLASS-METHODS get_max_bytes_for_ext
*      IMPORTING iv_extension TYPE string
*      RETURNING VALUE(rv_max_bytes) TYPE i.
*
*ENDCLASS.
*
*
*
*CLASS zcl_attach_config IMPLEMENTATION.
*
*  METHOD allowed_extensions.
*    rt = VALUE tt_string_set(
*      ( c_ext_pdf )
*      ( c_ext_png )
*      ( c_ext_jpg )
*      ( c_ext_jpeg )
*      ( c_ext_docx )
*      ( c_ext_xlsx )
*      ( c_ext_txt )
*    ).
*  ENDMETHOD.
*
*  METHOD allowed_mime_types.
*    rt = VALUE tt_string_set(
*      ( c_mime_pdf )
*      ( c_mime_png )
*      ( c_mime_jpeg )
*      ( c_mime_docx )
*      ( c_mime_xlsx )
*      ( c_mime_txt )
*    ).
*  ENDMETHOD.
*
*  METHOD extension_size_limits.
*
*    rt = VALUE tt_ext_limit(
*      ( ext = c_ext_pdf  max_bytes = 15728640 ) "15 * 1024 * 1024
*      ( ext = c_ext_png  max_bytes =  5242880 ) "5MB
*      ( ext = c_ext_jpg  max_bytes =  5242880 ) "5MB
*      ( ext = c_ext_jpeg max_bytes =  5242880 ) "5MB
*      ( ext = c_ext_docx max_bytes = 10485760 ) "10MB
*      ( ext = c_ext_txt max_bytes = 10485760 ) "10MB
*      ( ext = c_ext_xlsx max_bytes = 10485760 ) "10MB
*    ).
*  ENDMETHOD.
*
*  METHOD get_max_bytes_for_ext.
*    DATA(lv_ext) = to_lower( condense( iv_extension ) ).
*    SHIFT lv_ext LEFT DELETING LEADING '.'. "handle '.pdf'
*
*    rv_max_bytes = 0.
*
*    DATA(lt_limits) = extension_size_limits( ).
*    READ TABLE lt_limits WITH TABLE KEY ext = lv_ext INTO DATA(ls_limit).
*    IF sy-subrc = 0.
*      rv_max_bytes = ls_limit-max_bytes.
*    ENDIF.
*  ENDMETHOD.
*
*ENDCLASS.


CLASS zcl_attach_config DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ts_file_cfg,
             file_ext    TYPE zsap20_att_cfg-file_ext,
             mime_type   TYPE zsap20_att_cfg-mime_type,
             max_bytes   TYPE zsap20_att_cfg-max_bytes,
             is_active   TYPE zsap20_att_cfg-is_active,
             description TYPE zsap20_att_cfg-description,
           END OF ts_file_cfg.

    TYPES tt_file_cfg TYPE HASHED TABLE OF ts_file_cfg
      WITH UNIQUE KEY file_ext mime_type.

    CLASS-METHODS normalize_extension
      IMPORTING iv_extension TYPE string
      RETURNING VALUE(rv_extension) TYPE string.

    CLASS-METHODS normalize_mime_type
      IMPORTING iv_mime_type TYPE string
      RETURNING VALUE(rv_mime_type) TYPE string.

    CLASS-METHODS get_by_ext_and_mime
      IMPORTING iv_extension TYPE string
                iv_mime_type TYPE string
      RETURNING VALUE(rs_cfg) TYPE ts_file_cfg
      RAISING   zcx_attach_validation.

    CLASS-METHODS is_extension_allowed
      IMPORTING iv_extension TYPE string
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    CLASS-METHODS get_max_bytes
      IMPORTING iv_extension TYPE string
                iv_mime_type TYPE string
      RETURNING VALUE(rv_max_bytes) TYPE i
      RAISING   zcx_attach_validation.

  PRIVATE SECTION.
    CLASS-DATA gt_cfg TYPE tt_file_cfg.
    CLASS-DATA gv_loaded TYPE abap_bool.

    CLASS-METHODS load_config.
ENDCLASS.

CLASS zcl_attach_config IMPLEMENTATION.

  METHOD normalize_extension.
    rv_extension = iv_extension.
    CONDENSE rv_extension NO-GAPS.
    TRANSLATE rv_extension TO LOWER CASE.
    SHIFT rv_extension LEFT DELETING LEADING '.'.
  ENDMETHOD.

  METHOD normalize_mime_type.
    rv_mime_type = iv_mime_type.
    CONDENSE rv_mime_type NO-GAPS.
    TRANSLATE rv_mime_type TO LOWER CASE.
  ENDMETHOD.

  METHOD load_config.
    DATA lt_cfg TYPE STANDARD TABLE OF ts_file_cfg.
    DATA ls_cfg TYPE ts_file_cfg.

    IF gv_loaded = abap_true.
      RETURN.
    ENDIF.

    CLEAR gt_cfg.

    SELECT file_ext
           mime_type
           max_bytes
           is_active
           description
      INTO TABLE lt_cfg
      FROM zsap20_att_cfg
      WHERE is_active = 'X'.

    LOOP AT lt_cfg INTO ls_cfg.
      INSERT ls_cfg INTO TABLE gt_cfg.
    ENDLOOP.

    gv_loaded = abap_true.
  ENDMETHOD.

  METHOD get_by_ext_and_mime.
    DATA lv_ext TYPE string.
    DATA lv_mime TYPE string.

    lv_ext = normalize_extension( iv_extension ).
    lv_mime = normalize_mime_type( iv_mime_type ).

    IF lv_ext IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'FILE_EXTENSION must not be empty.'.
    ENDIF.

    IF lv_mime IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'MIME_TYPE must not be empty.'.
    ENDIF.

    load_config( ).

    READ TABLE gt_cfg
      WITH TABLE KEY file_ext = lv_ext
                     mime_type = lv_mime
      INTO rs_cfg.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'No active configuration found for this extension and MIME type.'.
    ENDIF.
  ENDMETHOD.

  METHOD is_extension_allowed.
    DATA lv_ext TYPE string.
    DATA ls_cfg TYPE ts_file_cfg.

    lv_ext = normalize_extension( iv_extension ).
    rv_ok = abap_false.

    IF lv_ext IS INITIAL.
      RETURN.
    ENDIF.

    load_config( ).

    LOOP AT gt_cfg INTO ls_cfg.
      IF ls_cfg-file_ext = lv_ext.
        rv_ok = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_max_bytes.
    DATA ls_cfg TYPE ts_file_cfg.

    ls_cfg = get_by_ext_and_mime(
               iv_extension = iv_extension
               iv_mime_type = iv_mime_type ).

    rv_max_bytes = ls_cfg-max_bytes.
  ENDMETHOD.

ENDCLASS.
