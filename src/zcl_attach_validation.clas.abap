CLASS zcl_attach_validation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      tt_versions_keys     TYPE TABLE FOR READ IMPORT z_i_attach_r\_Versions,
      tt_versions_failed   TYPE TABLE FOR FAILED z_i_attach_ver,
      tt_versions_reported TYPE TABLE FOR REPORTED z_i_attach_ver.

    CLASS-METHODS check_title
      IMPORTING iv_title TYPE string.

    CLASS-METHODS check_file_name
      IMPORTING iv_file_name         TYPE string
      RETURNING VALUE(rv_error_text) TYPE string.

    CLASS-METHODS check_extension
      IMPORTING iv_extension         TYPE string
      RETURNING VALUE(rv_error_text) TYPE string.

    CLASS-METHODS check_config_file
      IMPORTING iv_extension         TYPE string
                iv_mime_type         TYPE string
      RETURNING VALUE(rv_error_text) TYPE string.

    CLASS-METHODS get_file_size_error
      IMPORTING iv_extension         TYPE string
                iv_mime_type         TYPE string
                iv_file_size         TYPE i
      RETURNING VALUE(rv_error_text) TYPE string.

    CLASS-METHODS check_file_content
      IMPORTING iv_content TYPE xstring.

    CLASS-METHODS check_active_state
      IMPORTING iv_is_active TYPE abap_bool.

    CLASS-METHODS check_current_version
      IMPORTING iv_current_version TYPE string.

    CLASS-METHODS check_rollback_target
      IMPORTING iv_target_version TYPE string.

    CLASS-METHODS check_delete_rules
      IMPORTING iv_is_active       TYPE abap_bool
                iv_current_version TYPE string
                iv_version_no      TYPE string OPTIONAL
      RETURNING VALUE(ro_msg)      TYPE REF TO if_abap_behv_message.

    CLASS-METHODS check_attachment_has_version
      IMPORTING iv_file_id TYPE zsap20_file_ver-file_id
      RAISING   zcx_attach_validation.

    CLASS-METHODS check_latest_version_type
      IMPORTING iv_file_id   TYPE zsap20_file_ver-file_id
                iv_extension TYPE string
                iv_mime_type TYPE string
      RAISING   zcx_attach_validation.

ENDCLASS.

CLASS zcl_attach_validation IMPLEMENTATION.

  METHOD check_title.
    DATA lv_title TYPE string.

    lv_title = iv_title.
    SHIFT lv_title LEFT DELETING LEADING space.
    SHIFT lv_title RIGHT DELETING TRAILING space.

    IF lv_title IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '002'
          iv_attr1 = 'Title'.
    ENDIF.

    IF strlen( lv_title ) > 120.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '010'.
    ENDIF.
  ENDMETHOD.

  METHOD check_file_name.
    DATA: lv_name    TYPE string,
          lv_trimmed TYPE string.

    CLEAR rv_error_text.

    lv_name = iv_file_name.

    IF lv_name IS INITIAL.
      MESSAGE e001(ygsp26sap20_msg) WITH 'File name' INTO rv_error_text.
      RETURN.
    ENDIF.

    lv_trimmed = lv_name.
    SHIFT lv_trimmed LEFT DELETING LEADING space.
    SHIFT lv_trimmed RIGHT DELETING TRAILING space.

    IF lv_name <> lv_trimmed.
      MESSAGE e011(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.

    IF lv_name = '.' OR lv_name = '..'.
      MESSAGE e012(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.

    DATA lv_last_index TYPE i.
    DATA lv_last_char  TYPE c LENGTH 1.

    lv_last_index = strlen( lv_name ) - 1.
    lv_last_char = lv_name+lv_last_index(1).

    IF lv_last_char = '.'.
      MESSAGE e013(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.

    IF strlen( lv_name ) > 255.
      MESSAGE e014(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.

    DATA lo_matcher TYPE REF TO cl_abap_matcher.

    lo_matcher = cl_abap_matcher=>create_pcre(
      pattern = '[<>:"/\\|?*\x00-\x1F]'
      text    = lv_name ).

    IF lo_matcher->match( ) = abap_true.
      MESSAGE e015(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.

    lo_matcher = cl_abap_matcher=>create_pcre(
      pattern     = '^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\..*)?$'
      text        = lv_name
      ignore_case = abap_true ).

    IF lo_matcher->match( ) = abap_true.
      MESSAGE e016(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD check_extension.
    DATA lv_ext TYPE string.

    CLEAR rv_error_text.

    lv_ext = zcl_attach_config=>normalize_extension( iv_extension ).

    IF lv_ext IS INITIAL.
      MESSAGE e001(ygsp26sap20_msg) WITH 'File extension' INTO rv_error_text.
      RETURN.
    ENDIF.

    IF zcl_attach_config=>is_valid_extension_format( lv_ext ) <> abap_true.
      MESSAGE e036(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD check_config_file.
    DATA lv_ext  TYPE string.
    DATA lv_mime TYPE string.
    DATA ls_cfg  TYPE zcl_attach_config=>ts_file_cfg.
    DATA lt_allowed_mimes TYPE zcl_attach_config=>tt_string.

    CLEAR rv_error_text.

    lv_ext  = zcl_attach_config=>normalize_extension( iv_extension ).
    lv_mime = zcl_attach_config=>normalize_mime_type( iv_mime_type ).

    IF lv_ext IS INITIAL.
      MESSAGE e001(ygsp26sap20_msg) WITH 'File extension' INTO rv_error_text.
      RETURN.
    ENDIF.

    IF lv_mime IS INITIAL.
      MESSAGE e001(ygsp26sap20_msg) WITH 'MIME type' INTO rv_error_text.
      RETURN.
    ENDIF.

    IF zcl_attach_config=>is_valid_mime_format( lv_mime ) <> abap_true.
      MESSAGE e037(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.

* 1. Check extension is active/allowed first
    TRY.
        ls_cfg = zcl_attach_config=>get_by_extension(
                   iv_extension = lv_ext ).
      CATCH zcx_attach_validation.
        MESSAGE e038(ygsp26sap20_msg) INTO rv_error_text.
        RETURN.
    ENDTRY.

* 2. Check MIME belongs to that extension
    lt_allowed_mimes = zcl_attach_config=>split_mime_types(
                         CONV string( ls_cfg-mime_type ) ).

    IF NOT line_exists( lt_allowed_mimes[ table_line = lv_mime ] ).
      MESSAGE e039(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD get_file_size_error.
    DATA lv_max_bytes TYPE i.
    DATA lv_error     TYPE string.

    CLEAR rv_error_text.

    lv_error = check_extension( iv_extension ).
    IF lv_error IS NOT INITIAL.
      rv_error_text = lv_error.
      RETURN.
    ENDIF.

    lv_error = check_config_file(
                 iv_extension = iv_extension
                 iv_mime_type = iv_mime_type ).
    IF lv_error IS NOT INITIAL.
      rv_error_text = lv_error.
      RETURN.
    ENDIF.

    IF iv_file_size <= 0.
      MESSAGE e040(ygsp26sap20_msg) INTO rv_error_text.
      RETURN.
    ENDIF.

    TRY.
        lv_max_bytes = zcl_attach_config=>get_max_bytes(
                         iv_extension = iv_extension
                         iv_mime_type = iv_mime_type ).

        IF lv_max_bytes <= 0.
          MESSAGE e035(ygsp26sap20_msg) INTO rv_error_text.
          RETURN.
        ENDIF.

        IF iv_file_size > lv_max_bytes.
          DATA(lv_max_bytes_str) = CONV string( lv_max_bytes ).
          MESSAGE e041(ygsp26sap20_msg) WITH lv_max_bytes_str INTO rv_error_text.
          RETURN.
        ENDIF.

      CATCH zcx_attach_validation.
        MESSAGE e034(ygsp26sap20_msg) WITH iv_extension INTO rv_error_text.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD check_file_content.

    IF iv_content IS INITIAL OR xstrlen( iv_content ) = 0.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '001'
          iv_attr1 = 'FILE_CONTENT'.
    ENDIF.

  ENDMETHOD.

  METHOD check_active_state.
    IF iv_is_active IS INITIAL OR iv_is_active = abap_false.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '062'.
    ENDIF.
  ENDMETHOD.

  METHOD check_current_version.
    DATA lv_ver TYPE string.

    lv_ver = iv_current_version.
    CONDENSE lv_ver.

    IF lv_ver IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '063'.
    ENDIF.

    IF strlen( lv_ver ) <> 3 OR NOT ( lv_ver CO '0123456789' ).
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '064'.
    ENDIF.
  ENDMETHOD.

  METHOD check_rollback_target.
    DATA lv_ver TYPE string.

    lv_ver = iv_target_version.
    CONDENSE lv_ver.

    IF lv_ver IS INITIAL OR strlen( lv_ver ) <> 3 OR NOT ( lv_ver CO '0123456789' ) OR lv_ver = '000'.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '065'.
    ENDIF.
  ENDMETHOD.

  METHOD check_delete_rules.
    IF iv_is_active = abap_false.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '062'.
    ENDIF.

    IF iv_version_no IS NOT INITIAL
       AND iv_version_no = iv_current_version.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '071'.
    ENDIF.
  ENDMETHOD.

  METHOD check_attachment_has_version.
    DATA lv_has_version TYPE abap_bool.

    IF iv_file_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '003'
          iv_attr1 = 'File'.
    ENDIF.

    CLEAR lv_has_version.

    SELECT SINGLE @abap_true
      FROM zsap20_file_ver
      WHERE file_id = @iv_file_id
      INTO @lv_has_version.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '061'.
    ENDIF.
  ENDMETHOD.

  METHOD check_latest_version_type.

    DATA: lv_new_type    TYPE zsap20_att_cfg-type,
          lv_last_type   TYPE zsap20_att_cfg-type,
          lv_current_ver TYPE zgsp26sap20_de_verno,
          lv_last_ext    TYPE zsap20_file_ver-file_extension,
          lv_last_mime   TYPE zsap20_file_ver-mime_type.

    IF iv_file_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '003'
          iv_attr1 = 'FileId'.
    ENDIF.

    SELECT SINGLE current_version
      FROM zsap20_file_mgmt
      INTO @lv_current_ver
      WHERE file_id   = @iv_file_id
        AND is_active = @abap_true.

    IF sy-subrc <> 0 OR lv_current_ver IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE file_extension,
                  mime_type
      FROM zsap20_file_ver
      INTO ( @lv_last_ext, @lv_last_mime )
      WHERE file_id    = @iv_file_id
        AND version_no = @lv_current_ver.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    TRY.
        lv_new_type = zcl_attach_config=>get_type_by_ext_and_mime(
                        iv_extension = iv_extension
                        iv_mime_type = iv_mime_type ).
      CATCH zcx_attach_validation.
        RAISE EXCEPTION TYPE zcx_attach_validation
          EXPORTING
            iv_msgid = 'YGSP26SAP20_MSG'
            iv_msgno = '035'.
    ENDTRY.

    TRY.
        lv_last_type = zcl_attach_config=>get_type_by_ext_and_mime(
                         iv_extension = CONV string( lv_last_ext )
                         iv_mime_type = CONV string( lv_last_mime ) ).
      CATCH zcx_attach_validation.
        RAISE EXCEPTION TYPE zcx_attach_validation
          EXPORTING
            iv_msgid = 'YGSP26SAP20_MSG'
            iv_msgno = '035'.
    ENDTRY.

    IF lv_new_type <> lv_last_type.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '070'
          iv_attr1 = CONV string( lv_new_type )
          iv_attr2 = CONV string( lv_last_type ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
