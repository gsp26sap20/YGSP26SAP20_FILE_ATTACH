CLASS lhc_AttCfg DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      lc_max_10mb      TYPE i VALUE 10485760,
      gc_type_image    TYPE zsap20_att_cfg-type VALUE 'IMAGE',
      gc_type_document TYPE zsap20_att_cfg-type VALUE 'DOCUMENT'.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR AttCfg RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE AttCfg.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE AttCfg.

    METHODS disable FOR MODIFY
      IMPORTING keys FOR ACTION AttCfg~disable.

    METHODS enable FOR MODIFY
      IMPORTING keys FOR ACTION AttCfg~enable.

    METHODS read FOR READ
      IMPORTING keys FOR READ AttCfg RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK AttCfg.

    METHODS is_admin
      RETURNING VALUE(rv_is_admin) TYPE abap_bool.

    METHODS is_valid_mime_type
      IMPORTING iv_mime_type TYPE zsap20_att_cfg-mime_type
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    METHODS is_valid_type_ext
      IMPORTING
        iv_type     TYPE zsap20_att_cfg-type
        iv_file_ext TYPE zsap20_att_cfg-file_ext
      RETURNING VALUE(rv_ok) TYPE abap_bool.

ENDCLASS.



CLASS lhc_AttCfg IMPLEMENTATION.

  METHOD is_admin.
    SELECT SINGLE role
      FROM zsap20_att_auth
      WHERE uname = @sy-uname
      INTO @DATA(lv_role).

    rv_is_admin = xsdbool( lv_role = 'ADMIN' ).
  ENDMETHOD.


  METHOD is_valid_mime_type.
    rv_ok = xsdbool( iv_mime_type CS '/' ).
  ENDMETHOD.


  METHOD is_valid_type_ext.

    DATA: lt_image TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lt_doc   TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lv_ext   TYPE string.

    lv_ext = iv_file_ext.
    TRANSLATE lv_ext TO LOWER CASE.

    lt_image = VALUE string_table(
      ( CONV string( 'jpg' ) )
      ( CONV string( 'jpeg' ) )
      ( CONV string( 'png' ) )
      ( CONV string( 'gif' ) )
    ).

    lt_doc = VALUE string_table(
      ( CONV string( 'doc' ) )
      ( CONV string( 'docx' ) )
      ( CONV string( 'xls' ) )
      ( CONV string( 'xlsx' ) )
      ( CONV string( 'ppt' ) )
      ( CONV string( 'pptx' ) )
      ( CONV string( 'pdf' ) )
      ( CONV string( 'txt' ) )
      ( CONV string( 'json' ) )
      ( CONV string( 'xml' ) )
      ( CONV string( 'csv' ) )
    ).

    CASE iv_type.
      WHEN gc_type_image.
        rv_ok = xsdbool( line_exists( lt_image[ table_line = lv_ext ] ) ).

      WHEN gc_type_document.
        rv_ok = xsdbool( line_exists( lt_doc[ table_line = lv_ext ] ) ).

      WHEN OTHERS.
        rv_ok = abap_false.
    ENDCASE.

  ENDMETHOD.


  METHOD get_instance_authorizations.

    DATA(lv_admin) = is_admin( ).

    SELECT file_ext, is_active
      FROM zsap20_att_cfg
      FOR ALL ENTRIES IN @keys
      WHERE file_ext = @keys-FileExt
      INTO TABLE @DATA(lt_cfg).

    result = VALUE #(
      FOR ls_key IN keys
      LET ls_cfg = VALUE #( lt_cfg[ file_ext = ls_key-FileExt ] OPTIONAL )
      IN
      (
        %tky = ls_key-%tky

        %update = COND #(
          WHEN lv_admin = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )

        %action-disable = COND #(
          WHEN lv_admin = abap_true
           AND ls_cfg-is_active = 'X'
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )

        %action-enable = COND #(
          WHEN lv_admin = abap_true
           AND ls_cfg-is_active <> 'X'
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )
      )
    ).

  ENDMETHOD.


  METHOD create.

    IF is_admin( ) <> abap_true.

      LOOP AT entities INTO DATA(ls_denied).
        APPEND VALUE #( %cid = ls_denied-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_denied-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '012'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.
      ENDLOOP.

      RETURN.
    ENDIF.


    LOOP AT entities INTO DATA(ls_create).

      TRANSLATE ls_create-FileExt TO LOWER CASE.

      IF ls_create-FileExt IS INITIAL OR
         ls_create-MimeType IS INITIAL OR
         ls_create-Type IS INITIAL.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id = 'YGSP26SAP20_MSG'
                   number = '015'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.


      IF is_valid_mime_type( ls_create-MimeType ) <> abap_true.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id = 'YGSP26SAP20_MSG'
                   number = '016'
                   severity = if_abap_behv_message=>severity-error )
          %element-MimeType = if_abap_behv=>mk-on
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.


      IF is_valid_type_ext(
           iv_type     = ls_create-Type
           iv_file_ext = ls_create-FileExt ) <> abap_true.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id = 'YGSP26SAP20_MSG'
                   number = '030'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.


      IF ls_create-MaxBytes IS INITIAL OR
         ls_create-MaxBytes <= 0 OR
         ls_create-MaxBytes > lc_max_10mb.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id = 'YGSP26SAP20_MSG'
                   number = '017'
                   severity = if_abap_behv_message=>severity-error )
          %element-MaxBytes = if_abap_behv=>mk-on
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.


      SELECT SINGLE @abap_true
        FROM zsap20_att_cfg
        WHERE file_ext = @ls_create-FileExt
        INTO @DATA(lv_exists).

      IF sy-subrc = 0.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id = 'YGSP26SAP20_MSG'
                   number = '019'
                   v1 = ls_create-FileExt
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.


      IF ls_create-IsActive IS INITIAL.
        ls_create-IsActive = 'X'.
      ENDIF.


      DATA ls_db TYPE zsap20_att_cfg.

      ls_db-mandt       = sy-mandt.
      ls_db-file_ext    = ls_create-FileExt.
      ls_db-mime_type   = ls_create-MimeType.
      ls_db-type        = ls_create-Type.
      ls_db-max_bytes   = ls_create-MaxBytes.
      ls_db-is_active   = ls_create-IsActive.
      ls_db-description = ls_create-Description.

      INSERT zsap20_att_cfg FROM @ls_db.

      IF sy-subrc <> 0.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        CONTINUE.
      ENDIF.


      APPEND VALUE #(
        %cid    = ls_create-%cid
        FileExt = ls_create-FileExt
      ) TO mapped-attcfg.

    ENDLOOP.

  ENDMETHOD.


  METHOD update.

    IF is_admin( ) <> abap_true.
      RETURN.
    ENDIF.

    LOOP AT entities INTO DATA(ls_update).

      IF ls_update-Type IS NOT INITIAL AND
         is_valid_type_ext(
           iv_type     = ls_update-Type
           iv_file_ext = ls_update-FileExt ) <> abap_true.

        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_update-MimeType IS NOT INITIAL AND
         is_valid_mime_type( ls_update-MimeType ) <> abap_true.

        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_update-MaxBytes IS NOT INITIAL AND
         ( ls_update-MaxBytes <= 0 OR ls_update-MaxBytes > lc_max_10mb ).

        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        CONTINUE.
      ENDIF.

      UPDATE zsap20_att_cfg
        SET mime_type   = @ls_update-MimeType,
            max_bytes   = @ls_update-MaxBytes,
            is_active   = @ls_update-IsActive,
            description = @ls_update-Description,
            type        = @ls_update-Type
        WHERE file_ext  = @ls_update-FileExt.

    ENDLOOP.

  ENDMETHOD.


  METHOD disable.
    IF is_admin( ) <> abap_true.
      RETURN.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).
      UPDATE zsap20_att_cfg
        SET is_active = '0'
        WHERE file_ext = @ls_key-FileExt
          AND is_active = 'X'.
    ENDLOOP.
  ENDMETHOD.


  METHOD enable.
    IF is_admin( ) <> abap_true.
      RETURN.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).
      UPDATE zsap20_att_cfg
        SET is_active = 'X'
        WHERE file_ext = @ls_key-FileExt
          AND is_active <> 'X'.
    ENDLOOP.
  ENDMETHOD.


  METHOD read.

    SELECT
      file_ext    AS FileExt,
      mime_type   AS MimeType,
      max_bytes   AS MaxBytes,
      is_active   AS IsActive,
      description AS Description,
      type        AS Type
      FROM zsap20_att_cfg
      INTO CORRESPONDING FIELDS OF TABLE @result
      FOR ALL ENTRIES IN @keys
      WHERE file_ext = @keys-FileExt.

  ENDMETHOD.


  METHOD lock.
  ENDMETHOD.

ENDCLASS.
