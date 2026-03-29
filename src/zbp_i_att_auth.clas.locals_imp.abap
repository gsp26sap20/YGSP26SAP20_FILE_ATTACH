CLASS lhc_Z_I_ATT_AUTH DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Auth RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Auth.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Auth.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Auth.

    METHODS read FOR READ
      IMPORTING keys FOR READ Auth RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Auth.

    METHODS is_admin
      RETURNING VALUE(rv_is_admin) TYPE abap_bool.

    METHODS is_valid_role
      IMPORTING iv_role         TYPE zsap20_att_auth-role
      RETURNING VALUE(rv_valid) TYPE abap_bool.

ENDCLASS.

CLASS lhc_Z_I_ATT_AUTH IMPLEMENTATION.

  METHOD is_admin.

    DATA lv_role TYPE zsap20_att_auth-role.

    CLEAR rv_is_admin.

    SELECT SINGLE role
      FROM zsap20_att_auth
      INTO @lv_role
      WHERE uname = @sy-uname.

    IF sy-subrc = 0 AND lv_role = 'ADMIN'.
      rv_is_admin = abap_true.
    ELSE.
      rv_is_admin = abap_false.
    ENDIF.

  ENDMETHOD.


  METHOD is_valid_role.

    rv_valid = xsdbool( iv_role = 'ADMIN' OR iv_role = 'USER' ).

  ENDMETHOD.


  METHOD get_instance_authorizations.

    DATA lv_is_admin TYPE abap_bool.

    lv_is_admin = is_admin( ).

    result = VALUE #(
      FOR ls_key IN keys
      (
        %tky = ls_key-%tky
        %update = COND #(
          WHEN lv_is_admin = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )
        %delete = COND #(
          WHEN lv_is_admin = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )
      )
    ).

  ENDMETHOD.


  METHOD create.

    IF is_admin( ) <> abap_true.

      LOOP AT entities INTO DATA(ls_create_denied).
        APPEND VALUE #( %cid = ls_create_denied-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create_denied-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only ADMIN can create authorization users.' )
        ) TO reported-auth.
      ENDLOOP.

      RETURN.

    ENDIF.

    DATA ls_auth_db TYPE zsap20_att_auth.

    LOOP AT entities INTO DATA(ls_create).

      IF ls_create-Uname IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Username is required.' )
          %element-Uname = if_abap_behv=>mk-on
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      IF is_valid_role( ls_create-Role ) <> abap_true.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Role must be ADMIN or USER.' )
          %element-Role = if_abap_behv=>mk-on
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      SELECT SINGLE @abap_true
        FROM zsap20_att_auth
        WHERE uname = @ls_create-Uname
        INTO @DATA(lv_exists_create).

      IF sy-subrc = 0.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |User { ls_create-Uname } already exists.| )
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      CLEAR ls_auth_db.
      ls_auth_db-mandt = sy-mandt.
      ls_auth_db-uname = ls_create-Uname.
      ls_auth_db-role  = ls_create-Role.
      ls_auth_db-erdat = sy-datum.
      ls_auth_db-ernam = sy-uname.

      INSERT zsap20_att_auth FROM @ls_auth_db.

      IF sy-subrc <> 0.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Create failed for user { ls_create-Uname }.| )
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %cid  = ls_create-%cid
        Uname = ls_create-Uname
      ) TO mapped-auth.

      APPEND VALUE #(
        %cid = ls_create-%cid
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Authorization for user { ls_create-Uname } created.| )
      ) TO reported-auth.

    ENDLOOP.

  ENDMETHOD.


  METHOD update.

    IF is_admin( ) <> abap_true.

      LOOP AT entities INTO DATA(ls_update_denied).
        APPEND VALUE #( %tky = ls_update_denied-%tky ) TO failed-auth.
        APPEND VALUE #(
          %tky = ls_update_denied-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only ADMIN can update authorization users.' )
        ) TO reported-auth.
      ENDLOOP.

      RETURN.

    ENDIF.

    LOOP AT entities INTO DATA(ls_update).

      IF is_valid_role( ls_update-Role ) <> abap_true.
        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-auth.
        APPEND VALUE #(
          %tky = ls_update-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Role must be ADMIN or USER.' )
          %element-Role = if_abap_behv=>mk-on
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      UPDATE zsap20_att_auth
        SET role = @ls_update-Role
        WHERE uname = @ls_update-Uname.

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_update-%tky ) TO failed-auth.
        APPEND VALUE #(
          %tky = ls_update-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |User { ls_update-Uname } not found.| )
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky = ls_update-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Role of user { ls_update-Uname } updated to { ls_update-Role }.| )
      ) TO reported-auth.

    ENDLOOP.

  ENDMETHOD.


  METHOD delete.

    IF is_admin( ) <> abap_true.

      LOOP AT keys INTO DATA(ls_delete_denied).
        APPEND VALUE #( %tky = ls_delete_denied-%tky ) TO failed-auth.
        APPEND VALUE #(
          %tky = ls_delete_denied-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only ADMIN can delete authorization users.' )
        ) TO reported-auth.
      ENDLOOP.

      RETURN.

    ENDIF.

    LOOP AT keys INTO DATA(ls_delete).

      DELETE FROM zsap20_att_auth
        WHERE uname = @ls_delete-Uname.

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_delete-%tky ) TO failed-auth.
        APPEND VALUE #(
          %tky = ls_delete-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |User { ls_delete-Uname } not found.| )
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky = ls_delete-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Authorization of user { ls_delete-Uname } deleted.| )
      ) TO reported-auth.

    ENDLOOP.

  ENDMETHOD.


  METHOD read.

    IF is_admin( ) <> abap_true.
      RETURN.
    ENDIF.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    SELECT
      uname AS Uname,
      role  AS Role,
      erdat AS Erdat,
      ernam AS Ernam
      FROM zsap20_att_auth
      INTO CORRESPONDING FIELDS OF TABLE @result
      FOR ALL ENTRIES IN @keys
      WHERE uname = @keys-Uname.

  ENDMETHOD.


  METHOD lock.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z_I_ATT_AUTH DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z_I_ATT_AUTH IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
