CLASS lhc_AttCfg DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      lc_max_10mb TYPE i VALUE 10485760.

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

    METHODS is_valid_extension
      IMPORTING iv_file_ext TYPE zsap20_att_cfg-file_ext
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
    DATA lt_tokens TYPE zcl_attach_config=>tt_string.

    rv_ok = abap_false.

    lt_tokens = zcl_attach_config=>split_mime_types(
                  CONV string( iv_mime_type ) ).

    IF lt_tokens IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_tokens INTO DATA(lv_token).
      IF zcl_attach_config=>is_valid_mime_format( lv_token ) <> abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

    rv_ok = abap_true.
  ENDMETHOD.

  METHOD is_valid_extension.
    rv_ok = zcl_attach_config=>is_valid_extension_format(
              CONV string( iv_file_ext ) ).
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

      ls_create-FileExt = zcl_attach_config=>normalize_extension(
                            CONV string( ls_create-FileExt ) ).

      ls_create-MimeType = zcl_attach_config=>normalize_mime_type_list(
                             CONV string( ls_create-MimeType ) ).

      SHIFT ls_create-Description LEFT DELETING LEADING space.
      SHIFT ls_create-Description RIGHT DELETING TRAILING space.

      IF ls_create-FileExt IS INITIAL OR
         ls_create-MimeType IS INITIAL OR
         ls_create-Type IS INITIAL.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '015'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.

      IF is_valid_extension( ls_create-FileExt ) <> abap_true.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'File extension format is invalid.' )
          %element-FileExt = if_abap_behv=>mk-on
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.

      IF is_valid_mime_type( ls_create-MimeType ) <> abap_true.

        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.

        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'One or more MIME types are invalid.' )
          %element-MimeType = if_abap_behv=>mk-on
        ) TO reported-attcfg.

        CONTINUE.
      ENDIF.

      IF ls_create-MaxBytes IS INITIAL OR ls_create-MaxBytes <= 0.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '017'
                   severity = if_abap_behv_message=>severity-error )
          %element-MaxBytes = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_create-MaxBytes > lc_max_10mb.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '018'
                   severity = if_abap_behv_message=>severity-error )
          %element-MaxBytes = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_create-Description IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Description cannot be empty.' )
          %element-Description = if_abap_behv=>mk-on
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
                   id       = 'YGSP26SAP20_MSG'
                   number   = '019'
                   v1       = ls_create-FileExt
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

      zcl_attach_config=>reset_cache( ).

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

      IF ls_update-FileExt IS NOT INITIAL.
        ls_update-FileExt = zcl_attach_config=>normalize_extension(
                              CONV string( ls_update-FileExt ) ).
      ENDIF.

      IF ls_update-MimeType IS NOT INITIAL.
        ls_update-MimeType = zcl_attach_config=>normalize_mime_type_list(
                               CONV string( ls_update-MimeType ) ).
      ENDIF.

      IF ls_update-FileExt IS NOT INITIAL AND
         is_valid_extension( ls_update-FileExt ) <> abap_true.

        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        APPEND VALUE #(
          %tky = ls_update-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'File extension format is invalid.' )
          %element-FileExt = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_update-MimeType IS NOT INITIAL AND
         is_valid_mime_type( ls_update-MimeType ) <> abap_true.

        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        APPEND VALUE #(
          %tky = ls_update-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'One or more MIME types are invalid.' )
          %element-MimeType = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_update-MaxBytes IS NOT INITIAL.

        IF ls_update-MaxBytes <= 0.
          APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
          APPEND VALUE #(
            %tky = ls_update-%tky
            %msg = new_message(
                     id       = 'YGSP26SAP20_MSG'
                     number   = '017'
                     severity = if_abap_behv_message=>severity-error )
            %element-MaxBytes = if_abap_behv=>mk-on
          ) TO reported-attcfg.
          CONTINUE.
        ENDIF.

        IF ls_update-MaxBytes > lc_max_10mb.
          APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
          APPEND VALUE #(
            %tky = ls_update-%tky
            %msg = new_message(
                     id       = 'YGSP26SAP20_MSG'
                     number   = '018'
                     severity = if_abap_behv_message=>severity-error )
            %element-MaxBytes = if_abap_behv=>mk-on
          ) TO reported-attcfg.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF ls_update-Description IS NOT INITIAL.
        SHIFT ls_update-Description LEFT DELETING LEADING space.
        SHIFT ls_update-Description RIGHT DELETING TRAILING space.

        IF ls_update-Description IS INITIAL.
          APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
          APPEND VALUE #(
            %tky = ls_update-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Description cannot be empty.' )
            %element-Description = if_abap_behv=>mk-on
          ) TO reported-attcfg.
          CONTINUE.
        ENDIF.
      ENDIF.

      UPDATE zsap20_att_cfg
        SET mime_type   = @ls_update-MimeType,
            max_bytes   = @ls_update-MaxBytes,
            is_active   = @ls_update-IsActive,
            description = @ls_update-Description,
            type        = @ls_update-Type
        WHERE file_ext  = @ls_update-FileExt.

      zcl_attach_config=>reset_cache( ).

    ENDLOOP.

  ENDMETHOD.

  METHOD disable.
    IF is_admin( ) <> abap_true.
      RETURN.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).
      UPDATE zsap20_att_cfg
        SET is_active = ' '
        WHERE file_ext = @ls_key-FileExt
          AND is_active = 'X'.
    ENDLOOP.

    zcl_attach_config=>reset_cache( ).
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

    zcl_attach_config=>reset_cache( ).
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
