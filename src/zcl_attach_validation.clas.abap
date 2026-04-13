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

*    CLASS-METHODS check_extension
*      IMPORTING iv_extension TYPE string.
*
*    CLASS-METHODS check_mime_type
*      IMPORTING iv_extension TYPE string
*                iv_mime_type TYPE string.
*
*    CLASS-METHODS check_file_size
*      IMPORTING keys     TYPE tt_versions_keys
*      CHANGING  failed   TYPE tt_versions_failed
*                reported TYPE tt_versions_reported.
    CLASS-METHODS check_extension
      IMPORTING iv_extension         TYPE string
      RETURNING VALUE(rv_error_text) TYPE string.

    CLASS-METHODS check_mime_type
      IMPORTING iv_extension         TYPE string
                iv_mime_type         TYPE string
      RETURNING VALUE(rv_error_text) TYPE string.

    CLASS-METHODS check_file_size
      IMPORTING keys     TYPE tt_versions_keys
      CHANGING  failed   TYPE tt_versions_failed
                reported TYPE tt_versions_reported.

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
    CONDENSE lv_title.

    IF lv_title IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'Title must not be empty.'.
    ENDIF.

    IF strlen( lv_title ) > 120.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'Title length must not exceed 120 characters.'.
    ENDIF.
  ENDMETHOD.


  METHOD check_extension.
    DATA lv_ext TYPE string.

    CLEAR rv_error_text.

    lv_ext = zcl_attach_config=>normalize_extension( iv_extension ).

    IF lv_ext IS INITIAL.
      rv_error_text = 'FILE_EXTENSION must not be empty.'.
      RETURN.
    ENDIF.

    IF zcl_attach_config=>is_extension_allowed( lv_ext ) = abap_false.
      rv_error_text = 'Unsupported file extension.'.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD check_mime_type.
    DATA lv_ext  TYPE string.
    DATA lv_mime TYPE string.
    DATA ls_cfg  TYPE zcl_attach_config=>ts_file_cfg.

    CLEAR rv_error_text.

    lv_ext  = zcl_attach_config=>normalize_extension( iv_extension ).
    lv_mime = zcl_attach_config=>normalize_mime_type( iv_mime_type ).

    IF lv_ext IS INITIAL.
      rv_error_text = 'FILE_EXTENSION must not be empty.'.
      RETURN.
    ENDIF.

    IF lv_mime IS INITIAL.
      rv_error_text = 'MIME_TYPE must not be empty.'.
      RETURN.
    ENDIF.

    TRY.
        ls_cfg = zcl_attach_config=>get_by_ext_and_mime(
                   iv_extension = lv_ext
                   iv_mime_type = lv_mime ).
      CATCH zcx_attach_validation.
        rv_error_text = 'Unsupported MIME type for file extension.'.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD check_file_size.

    CONSTANTS c_state_area TYPE string VALUE 'VALIDATE_SIZE'.

    DATA lv_max_bytes TYPE i.
    DATA lv_ext       TYPE string.
    DATA lv_mime      TYPE string.
    DATA lv_error     TYPE string.

    READ ENTITIES OF z_i_attach_r IN LOCAL MODE
      ENTITY z_i_attach_r BY \_Versions
        FIELDS ( FileSize FileExtension MimeType )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_versions).

    LOOP AT lt_versions INTO DATA(ls_ver).

      CLEAR: lv_max_bytes, lv_ext, lv_mime, lv_error.

      lv_ext  = ls_ver-FileExtension.
      lv_mime = ls_ver-MimeType.

      APPEND VALUE #(
        %tky        = ls_ver-%tky
        %state_area = c_state_area
      ) TO reported.

      lv_error = check_extension( lv_ext ).
      IF lv_error IS NOT INITIAL.
        APPEND VALUE #(
          %tky = ls_ver-%tky
        ) TO failed.
        CONTINUE.
      ENDIF.

      lv_error = check_mime_type(
                   iv_extension = lv_ext
                   iv_mime_type = lv_mime ).
      IF lv_error IS NOT INITIAL.
        APPEND VALUE #(
          %tky = ls_ver-%tky
        ) TO failed.
        CONTINUE.
      ENDIF.

      TRY.
          lv_max_bytes = zcl_attach_config=>get_max_bytes(
                           iv_extension = lv_ext
                           iv_mime_type = lv_mime ).

          IF lv_max_bytes <= 0 OR ls_ver-FileSize > lv_max_bytes.
            APPEND VALUE #(
              %tky = ls_ver-%tky
            ) TO failed.
          ENDIF.

        CATCH zcx_attach_validation.
          APPEND VALUE #(
            %tky = ls_ver-%tky
          ) TO failed.
      ENDTRY.

    ENDLOOP.

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

    lv_error = check_mime_type(
                 iv_extension = iv_extension
                 iv_mime_type = iv_mime_type ).
    IF lv_error IS NOT INITIAL.
      rv_error_text = lv_error.
      RETURN.
    ENDIF.

    TRY.
        lv_max_bytes = zcl_attach_config=>get_max_bytes(
                         iv_extension = iv_extension
                         iv_mime_type = iv_mime_type ).

        IF lv_max_bytes <= 0.
          rv_error_text = 'No active file size configuration found.'.
          RETURN.
        ENDIF.

        IF iv_file_size > lv_max_bytes.
          rv_error_text = |File size exceeds configured limit ({ lv_max_bytes } bytes).|.
          RETURN.
        ENDIF.

      CATCH zcx_attach_validation.
        rv_error_text = 'Invalid file configuration.'.
        RETURN.
    ENDTRY.
  ENDMETHOD.


  METHOD check_file_content.

    IF iv_content IS INITIAL OR xstrlen( iv_content ) = 0.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '011'.
    ENDIF.

  ENDMETHOD.

  METHOD check_active_state.
    IF iv_is_active IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '002'.
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
          iv_msgno = '003'.
    ENDIF.

    IF strlen( lv_ver ) <> 3 OR NOT ( lv_ver CO '0123456789' ).
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '004'.
    ENDIF.
  ENDMETHOD.

  METHOD check_rollback_target.
    DATA lv_ver TYPE string.

    lv_ver = iv_target_version.
    CONDENSE lv_ver.

    IF lv_ver IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '005'.
    ENDIF.

    IF strlen( lv_ver ) <> 3.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '006'.
    ENDIF.

    IF NOT ( lv_ver CO '0123456789' ).
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '007'.
    ENDIF.

    IF lv_ver = '000'.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '008'.
    ENDIF.
  ENDMETHOD.

  METHOD check_delete_rules.
    IF iv_is_active = abap_false.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '009'.
    ENDIF.

    IF iv_version_no IS NOT INITIAL
       AND iv_version_no = iv_current_version.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_msgid = 'YGSP26SAP20_MSG'
          iv_msgno = '010'.
    ENDIF.
  ENDMETHOD.

  METHOD check_attachment_has_version.
    DATA lv_has_version TYPE abap_bool.

    IF iv_file_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'File ID must not be empty.'.
    ENDIF.

    CLEAR lv_has_version.

    SELECT SINGLE @abap_true
      FROM zsap20_file_ver
      WHERE file_id = @iv_file_id
      INTO @lv_has_version.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'This attachment has no version yet.'.
    ENDIF.
  ENDMETHOD.

  METHOD check_latest_version_type.

    DATA: lv_new_ext     TYPE string,
          lv_new_mime    TYPE string,
          lv_new_type    TYPE zsap20_att_cfg-type,
          lv_last_ext    TYPE string,
          lv_last_mime   TYPE string,
          lv_last_type   TYPE zsap20_att_cfg-type,
          lv_current_ver TYPE zgsp26sap20_verno,
          ls_last_ver    TYPE zsap20_file_ver.

    IF iv_file_id IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'File ID must not be empty.'.
    ENDIF.

    " Normalize uploaded file info
    lv_new_ext  = zcl_attach_config=>normalize_extension( iv_extension ).
    lv_new_mime = zcl_attach_config=>normalize_mime_type( iv_mime_type ).

    " Get current version from attachment master
    SELECT SINGLE current_version
      FROM zsap20_file_mgmt
      INTO @lv_current_ver
      WHERE file_id   = @iv_file_id
        AND is_active = @abap_true.

    " No previous version -> skip check
    IF sy-subrc <> 0 OR lv_current_ver IS INITIAL.
      RETURN.
    ENDIF.

    " Get latest version record
    SELECT SINGLE *
      FROM zsap20_file_ver
      INTO @ls_last_ver
      WHERE file_id    = @iv_file_id
        AND version_no = @lv_current_ver.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Normalize latest version file info
    lv_last_ext = zcl_attach_config=>normalize_extension(
                    CONV string( ls_last_ver-file_extension ) ).

    lv_last_mime = zcl_attach_config=>normalize_mime_type(
                     CONV string( ls_last_ver-mime_type ) ).

    " Get type of uploaded file from config
    SELECT SINGLE type
      FROM zsap20_att_cfg
      INTO @lv_new_type
      WHERE file_ext  = @lv_new_ext
        AND mime_type = @lv_new_mime
        AND is_active = 'X'.

    IF sy-subrc <> 0 OR lv_new_type IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'No active configuration found for uploaded file type.'.
    ENDIF.

    " Get type of latest version from config
    SELECT SINGLE type
      FROM zsap20_att_cfg
      INTO @lv_last_type
      WHERE file_ext  = @lv_last_ext
        AND mime_type = @lv_last_mime
        AND is_active = 'X'.

    IF sy-subrc <> 0 OR lv_last_type IS INITIAL.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = 'No active configuration found for latest version file type.'.
    ENDIF.

    " Reject if type is different
    IF lv_new_type <> lv_last_type.
      RAISE EXCEPTION TYPE zcx_attach_validation
        EXPORTING
          iv_text = |Uploaded file type '{ lv_new_type }' does not match latest version type '{ lv_last_type }'.|.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
