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
             type        TYPE zsap20_att_cfg-type,
           END OF ts_file_cfg.

    TYPES tt_file_cfg TYPE HASHED TABLE OF ts_file_cfg
      WITH UNIQUE KEY file_ext.

    TYPES tt_string TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    CLASS-METHODS normalize_extension
      IMPORTING iv_extension        TYPE string
      RETURNING VALUE(rv_extension) TYPE string.

    CLASS-METHODS normalize_mime_type
      IMPORTING iv_mime_type        TYPE string
      RETURNING VALUE(rv_mime_type) TYPE string.

    CLASS-METHODS normalize_mime_type_list
      IMPORTING iv_mime_type_list        TYPE string
      RETURNING VALUE(rv_mime_type_list) TYPE string.

    CLASS-METHODS split_mime_types
      IMPORTING iv_mime_type_list    TYPE string
      RETURNING VALUE(rt_mime_types) TYPE tt_string.

    CLASS-METHODS is_valid_extension_format
      IMPORTING iv_extension TYPE string
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    CLASS-METHODS is_valid_mime_format
      IMPORTING iv_mime_type TYPE string
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    CLASS-METHODS get_by_ext_and_mime
      IMPORTING iv_extension  TYPE string
                iv_mime_type  TYPE string
      RETURNING VALUE(rs_cfg) TYPE ts_file_cfg
      RAISING   zcx_attach_validation.

    CLASS-METHODS is_extension_allowed
      IMPORTING iv_extension TYPE string
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    CLASS-METHODS get_max_bytes
      IMPORTING iv_extension        TYPE string
                iv_mime_type        TYPE string
      RETURNING VALUE(rv_max_bytes) TYPE i
      RAISING   zcx_attach_validation.

    CLASS-METHODS get_type_by_ext_and_mime
      IMPORTING iv_extension   TYPE string
                iv_mime_type   TYPE string
      RETURNING VALUE(rv_type) TYPE zsap20_att_cfg-type
      RAISING   zcx_attach_validation.
    CLASS-METHODS get_by_extension
      IMPORTING iv_extension  TYPE string
      RETURNING VALUE(rs_cfg) TYPE ts_file_cfg
      RAISING   zcx_attach_validation.

    CLASS-METHODS reset_cache.

    CONSTANTS:
      c_audit_create              TYPE zsap20_att_audit-action VALUE 'CREATE',
      c_audit_update_title        TYPE zsap20_att_audit-action VALUE 'UPDATE',
      c_audit_set_current_version TYPE zsap20_att_audit-action VALUE 'SET_CURRENT_VERSION',
      c_audit_delete              TYPE zsap20_att_audit-action VALUE 'DELETE',
      c_audit_reactivate          TYPE zsap20_att_audit-action VALUE 'REACTIVATE',
      c_audit_link_to_bo          TYPE zsap20_att_audit-action VALUE 'LINK_BO',
      c_audit_unlink_bo           TYPE zsap20_att_audit-action VALUE 'UNLINK_BO',
      c_audit_create_version      TYPE zsap20_att_audit-action VALUE 'CREATE_VERSION'.

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
    SHIFT rv_mime_type LEFT DELETING LEADING space.
    SHIFT rv_mime_type RIGHT DELETING TRAILING space.
    TRANSLATE rv_mime_type TO LOWER CASE.
  ENDMETHOD.

  METHOD split_mime_types.
    DATA: lt_raw   TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lv_token TYPE string.

    CLEAR rt_mime_types.

    SPLIT iv_mime_type_list AT ';' INTO TABLE lt_raw.

    LOOP AT lt_raw INTO lv_token.
      lv_token = normalize_mime_type( lv_token ).
      IF lv_token IS NOT INITIAL.
        APPEND lv_token TO rt_mime_types.
      ENDIF.
    ENDLOOP.

    SORT rt_mime_types BY table_line.
    DELETE ADJACENT DUPLICATES FROM rt_mime_types COMPARING table_line.
  ENDMETHOD.

  METHOD normalize_mime_type_list.
    DATA lt_mimes TYPE tt_string.
    DATA lv_token TYPE string.

    CLEAR rv_mime_type_list.

    lt_mimes = split_mime_types( iv_mime_type_list ).

    LOOP AT lt_mimes INTO lv_token.
      IF rv_mime_type_list IS INITIAL.
        rv_mime_type_list = lv_token.
      ELSE.
        rv_mime_type_list = |{ rv_mime_type_list }; { lv_token }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_valid_extension_format.
    DATA lv_ext TYPE string.
    DATA lo_matcher TYPE REF TO cl_abap_matcher.

    rv_ok = abap_false.
    lv_ext = normalize_extension( iv_extension ).

    IF lv_ext IS INITIAL.
      RETURN.
    ENDIF.

    lo_matcher = cl_abap_matcher=>create_pcre(
      pattern = '^[a-z0-9_+\-]+$'
      text    = lv_ext ).

    IF lo_matcher->match( ) = abap_true.
      rv_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD is_valid_mime_format.
    DATA lv_mime TYPE string.
    DATA lo_matcher TYPE REF TO cl_abap_matcher.

    rv_ok = abap_false.
    lv_mime = normalize_mime_type( iv_mime_type ).

    IF lv_mime IS INITIAL.
      RETURN.
    ENDIF.

    lo_matcher = cl_abap_matcher=>create_pcre(
      pattern = '^[a-z0-9!#$&^_.+\-]+/[a-z0-9!#$&^_.+\-]+$'
      text    = lv_mime ).

    IF lo_matcher->match( ) = abap_true.
      rv_ok = abap_true.
    ENDIF.
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
           type
      INTO TABLE lt_cfg
      FROM zsap20_att_cfg
      WHERE is_active = 'X'.

    LOOP AT lt_cfg INTO ls_cfg.
      ls_cfg-file_ext  = normalize_extension( CONV string( ls_cfg-file_ext ) ).
      ls_cfg-mime_type = normalize_mime_type_list( CONV string( ls_cfg-mime_type ) ).
      INSERT ls_cfg INTO TABLE gt_cfg.
    ENDLOOP.

    gv_loaded = abap_true.
  ENDMETHOD.

  METHOD get_by_ext_and_mime.
    DATA lv_ext TYPE string.
    DATA lv_mime TYPE string.
    DATA lt_allowed_mimes TYPE tt_string.

    lv_ext = normalize_extension( iv_extension ).
    lv_mime = normalize_mime_type( iv_mime_type ).

    IF lv_ext IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_attr1 = 'EXTENSION'
          iv_msgno = '001'.
    ENDIF.

    IF lv_mime IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_attr1 = 'MIME'
          iv_msgno = '001'.
    ENDIF.

    load_config( ).

    READ TABLE gt_cfg
      WITH TABLE KEY file_ext = lv_ext
      INTO rs_cfg.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '035'.
    ENDIF.

    lt_allowed_mimes = split_mime_types( CONV string( rs_cfg-mime_type ) ).

    IF NOT line_exists( lt_allowed_mimes[ table_line = lv_mime ] ).
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '035'.
    ENDIF.
  ENDMETHOD.

  METHOD is_extension_allowed.
    DATA lv_ext TYPE string.

    rv_ok = abap_false.
    lv_ext = normalize_extension( iv_extension ).

    IF lv_ext IS INITIAL.
      RETURN.
    ENDIF.

    load_config( ).

    READ TABLE gt_cfg
      WITH TABLE KEY file_ext = lv_ext
      TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      rv_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD get_max_bytes.
    DATA ls_cfg TYPE ts_file_cfg.

    ls_cfg = get_by_ext_and_mime(
               iv_extension = iv_extension
               iv_mime_type = iv_mime_type ).

    rv_max_bytes = ls_cfg-max_bytes.
  ENDMETHOD.

  METHOD get_type_by_ext_and_mime.
    DATA ls_cfg TYPE ts_file_cfg.

    ls_cfg = get_by_ext_and_mime(
               iv_extension = iv_extension
               iv_mime_type = iv_mime_type ).

    rv_type = ls_cfg-type.
  ENDMETHOD.

  METHOD reset_cache.
    CLEAR: gt_cfg, gv_loaded.
  ENDMETHOD.

  METHOD get_by_extension.
    DATA lv_ext TYPE string.

    lv_ext = normalize_extension( iv_extension ).

    IF lv_ext IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '001'
          iv_attr1 = 'Extension'.
    ENDIF.

    load_config( ).

    READ TABLE gt_cfg
      WITH TABLE KEY file_ext = lv_ext
      INTO rs_cfg.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'File extension is not allowed or inactive.'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
