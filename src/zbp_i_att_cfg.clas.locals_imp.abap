CLASS lhc_AttCfg DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    CLASS-DATA:
      gt_create_buffer TYPE STANDARD TABLE OF zsap20_att_cfg WITH DEFAULT KEY,
      gt_update_buffer TYPE STANDARD TABLE OF zsap20_att_cfg WITH DEFAULT KEY.

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
      IMPORTING iv_file_ext  TYPE zsap20_att_cfg-file_ext
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

    lt_tokens = zcl_attach_config=>split_mime_types( CONV string( iv_mime_type ) ).

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
    rv_ok = zcl_attach_config=>is_valid_extension_format( CONV string( iv_file_ext ) ).
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
                   number   = '004'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.
      ENDLOOP.
      RETURN.
    ENDIF.

    LOOP AT entities INTO DATA(ls_create).

      DATA: lv_file_ext    TYPE zsap20_att_cfg-file_ext,
            lv_mime_type   TYPE zsap20_att_cfg-mime_type,
            lv_description TYPE string,
            ls_db          TYPE zsap20_att_cfg.

      lv_file_ext = zcl_attach_config=>normalize_extension( CONV string( ls_create-FileExt ) ).
      lv_mime_type = zcl_attach_config=>normalize_mime_type_list( CONV string( ls_create-MimeType ) ).

      lv_description = CONV string( ls_create-Description ).
      SHIFT lv_description LEFT DELETING LEADING space.
      SHIFT lv_description RIGHT DELETING TRAILING space.

      IF lv_file_ext IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '001'
                   v1       = 'FileExt'
                   severity = if_abap_behv_message=>severity-error )
          %element-FileExt = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF lv_mime_type IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '001'
                   v1       = 'MimeType'
                   severity = if_abap_behv_message=>severity-error )
          %element-MimeType = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_create-Type IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '001'
                   v1       = 'Type'
                   severity = if_abap_behv_message=>severity-error )
          %element-Type = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF is_valid_extension( lv_file_ext ) <> abap_true.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '036'
                   severity = if_abap_behv_message=>severity-error )
          %element-FileExt = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF is_valid_mime_type( lv_mime_type ) <> abap_true.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '037'
                   severity = if_abap_behv_message=>severity-error )
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
                   number   = '031'
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
                   number   = '032'
                   severity = if_abap_behv_message=>severity-error )
          %element-MaxBytes = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF lv_description IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '002'
                   v1       = 'Description'
                   severity = if_abap_behv_message=>severity-error )
          %element-Description = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      SELECT SINGLE @abap_true
        FROM zsap20_att_cfg
        WHERE file_ext = @lv_file_ext
        INTO @DATA(lv_exists_db).

      IF sy-subrc = 0.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '033'
                   v1       = lv_file_ext
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF line_exists( gt_create_buffer[ file_ext = lv_file_ext ] ).
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '033'
                   v1       = lv_file_ext
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF line_exists( gt_update_buffer[ file_ext = lv_file_ext ] ).
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-attcfg.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '033'
                   v1       = lv_file_ext
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      " 4. Push to Buffer
      CLEAR ls_db.
      ls_db-mandt       = sy-mandt.
      ls_db-file_ext    = lv_file_ext.
      ls_db-mime_type   = lv_mime_type.
      ls_db-type        = ls_create-Type.
      ls_db-max_bytes   = ls_create-MaxBytes.
      ls_db-is_active   = COND #( WHEN ls_create-IsActive IS INITIAL THEN 'X' ELSE ls_create-IsActive ).
      ls_db-description = lv_description.

      APPEND ls_db TO gt_create_buffer.

      " 5. Map result
      APPEND VALUE #(
        %cid    = ls_create-%cid
        FileExt = lv_file_ext
      ) TO mapped-attcfg.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    IF is_admin( ) <> abap_true.
      LOOP AT entities INTO DATA(ls_denied).
        APPEND VALUE #( %tky = ls_denied-%tky ) TO failed-attcfg.
        APPEND VALUE #(
          %tky = ls_denied-%tky
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '004'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attcfg.
      ENDLOOP.
      RETURN.
    ENDIF.

    LOOP AT entities INTO DATA(ls_update).

      DATA: ls_db   TYPE zsap20_att_cfg,
            lv_mime TYPE string.

      IF ls_update-FileExt IS NOT INITIAL.
        ls_update-FileExt = zcl_attach_config=>normalize_extension( CONV string( ls_update-FileExt ) ).
      ENDIF.

      IF ls_update-MimeType IS NOT INITIAL.
        lv_mime = zcl_attach_config=>normalize_mime_type_list( CONV string( ls_update-MimeType ) ).
        ls_update-MimeType = lv_mime.
      ENDIF.

      IF ls_update-FileExt IS NOT INITIAL AND is_valid_extension( ls_update-FileExt ) <> abap_true.
        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        APPEND VALUE #(
          %tky = ls_update-%tky
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '036'
                   severity = if_abap_behv_message=>severity-error )
          %element-FileExt = if_abap_behv=>mk-on
        ) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_update-MimeType IS NOT INITIAL AND is_valid_mime_type( ls_update-MimeType ) <> abap_true.
        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        APPEND VALUE #(
          %tky = ls_update-%tky
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '094'
                   severity = if_abap_behv_message=>severity-error )
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
                     number   = '031'
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
                     number   = '032'
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
            %msg = new_message(
                     id       = 'YGSP26SAP20_MSG'
                     number   = '002'
                     v1       = 'Description'
                     severity = if_abap_behv_message=>severity-error )
            %element-Description = if_abap_behv=>mk-on
          ) TO reported-attcfg.
          CONTINUE.
        ENDIF.
      ENDIF.

      SELECT SINGLE *
        FROM zsap20_att_cfg
        WHERE file_ext = @ls_update-FileExt
        INTO @ls_db.

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-attcfg.
        APPEND VALUE #(
  %tky = ls_update-%tky
  %msg = new_message(
           id       = 'YGSP26SAP20_MSG'
           number   = '034'
           v1       = ls_update-FileExt
           severity = if_abap_behv_message=>severity-error )
) TO reported-attcfg.
        CONTINUE.
      ENDIF.

      IF ls_update-MimeType IS NOT INITIAL.
        ls_db-mime_type = ls_update-MimeType.
      ENDIF.

      IF ls_update-MaxBytes IS NOT INITIAL.
        ls_db-max_bytes = ls_update-MaxBytes.
      ENDIF.

      IF ls_update-Description IS NOT INITIAL.
        ls_db-description = ls_update-Description.
      ENDIF.

      IF ls_update-Type IS NOT INITIAL.
        ls_db-type = ls_update-Type.
      ENDIF.

      IF ls_update-IsActive IS NOT INITIAL.
        ls_db-is_active = ls_update-IsActive.
      ENDIF.

      ls_db-mandt    = sy-mandt.
      ls_db-file_ext = ls_update-FileExt.

      " Push to Buffer
      DELETE gt_update_buffer WHERE file_ext = ls_db-file_ext.
      APPEND ls_db TO gt_update_buffer.

    ENDLOOP.

  ENDMETHOD.

  METHOD disable.
    IF is_admin( ) <> abap_true.
      RETURN.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).
      DATA ls_db TYPE zsap20_att_cfg.
      CLEAR ls_db.

      READ TABLE gt_update_buffer INTO ls_db WITH KEY file_ext = ls_key-FileExt.
      IF sy-subrc <> 0.
        SELECT SINGLE * FROM zsap20_att_cfg WHERE file_ext = @ls_key-FileExt INTO @ls_db.
      ENDIF.

      IF ls_db IS NOT INITIAL AND ls_db-is_active = 'X'.
        ls_db-is_active = ' '.
        DELETE gt_update_buffer WHERE file_ext = ls_db-file_ext.
        APPEND ls_db TO gt_update_buffer.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD enable.
    IF is_admin( ) <> abap_true.
      RETURN.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).
      DATA ls_db TYPE zsap20_att_cfg.
      CLEAR ls_db.

      READ TABLE gt_update_buffer INTO ls_db WITH KEY file_ext = ls_key-FileExt.
      IF sy-subrc <> 0.
        SELECT SINGLE * FROM zsap20_att_cfg WHERE file_ext = @ls_key-FileExt INTO @ls_db.
      ENDIF.

      IF ls_db IS NOT INITIAL AND ls_db-is_active <> 'X'.
        ls_db-is_active = 'X'.
        DELETE gt_update_buffer WHERE file_ext = ls_db-file_ext.
        APPEND ls_db TO gt_update_buffer.
      ENDIF.
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

    LOOP AT result ASSIGNING FIELD-SYMBOL(<ls_result>).
      SHIFT <ls_result>-Description LEFT DELETING LEADING space.
      SHIFT <ls_result>-Description RIGHT DELETING TRAILING space.
    ENDLOOP.

  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_z_i_att_cfg DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_z_i_att_cfg IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    " Create
    IF lhc_attcfg=>gt_create_buffer IS NOT INITIAL.
      INSERT zsap20_att_cfg FROM TABLE @lhc_attcfg=>gt_create_buffer ACCEPTING DUPLICATE KEYS.
    ENDIF.

    " Update
    IF lhc_attcfg=>gt_update_buffer IS NOT INITIAL.
      UPDATE zsap20_att_cfg FROM TABLE @lhc_attcfg=>gt_update_buffer.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lhc_attcfg=>gt_create_buffer,
           lhc_attcfg=>gt_update_buffer.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR: lhc_attcfg=>gt_create_buffer,
           lhc_attcfg=>gt_update_buffer.

    zcl_attach_config=>reset_cache( ).
  ENDMETHOD.

ENDCLASS.
