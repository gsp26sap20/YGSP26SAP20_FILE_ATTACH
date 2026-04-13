CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: tt_auth TYPE STANDARD TABLE OF zsap20_att_auth.
    CLASS-DATA: mt_create TYPE tt_auth,
                mt_update TYPE tt_auth,
                mt_delete TYPE tt_auth.
ENDCLASS.

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

ENDCLASS.

CLASS lhc_Z_I_ATT_AUTH IMPLEMENTATION.

  METHOD is_admin.

    DATA lv_role TYPE zsap20_att_auth-role.

    CLEAR rv_is_admin.

    SELECT SINGLE role
      FROM zsap20_att_auth
      INTO @lv_role
      WHERE uname = @sy-uname.

    rv_is_admin = xsdbool( sy-subrc = 0 AND lv_role = 'ADMIN' ).

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

    DATA ls_auth_db TYPE zsap20_att_auth.

    IF is_admin( ) <> abap_true.

      LOOP AT entities INTO DATA(ls_create_denied).
        APPEND VALUE #( %cid = ls_create_denied-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create_denied-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '043'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-auth.
      ENDLOOP.

      RETURN.

    ENDIF.

    LOOP AT entities INTO DATA(ls_create).

      IF ls_create-Uname IS INITIAL.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '044'
                   severity = if_abap_behv_message=>severity-error )
          %element-Uname = if_abap_behv=>mk-on
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      IF ls_create-Role <> 'ADMIN'.
        APPEND VALUE #( %cid = ls_create-%cid ) TO failed-auth.
        APPEND VALUE #(
          %cid = ls_create-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '047'
                   severity = if_abap_behv_message=>severity-error )
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
                        %msg = new_message(
                               id       = 'YGSP26SAP20_MSG'
                               number   = '045'
                               severity = if_abap_behv_message=>severity-error
                               v1       = ( ls_create-Uname ) )
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      CLEAR ls_auth_db.
      ls_auth_db-mandt = sy-mandt.
      ls_auth_db-uname = ls_create-Uname.
      ls_auth_db-role  = ls_create-Role.
      ls_auth_db-erdat = sy-datum.
      ls_auth_db-ernam = sy-uname.

      APPEND ls_auth_db TO lcl_buffer=>mt_create.

      APPEND VALUE #(
        %cid  = ls_create-%cid
        Uname = ls_create-Uname
      ) TO mapped-auth.

      APPEND VALUE #(
                      %cid = ls_create-%cid
                      %msg = new_message(
                                id       = 'YGSP26SAP20_MSG'
                                number   = '036'
                                severity = if_abap_behv_message=>severity-success )
      ) TO reported-auth.

    ENDLOOP.

  ENDMETHOD.


  METHOD update.
  ENDMETHOD.


  METHOD delete.

    IF is_admin( ) <> abap_true.

      LOOP AT keys INTO DATA(ls_delete_denied).
        APPEND VALUE #( %tky = ls_delete_denied-%tky ) TO failed-auth.
        APPEND VALUE #(
          %tky = ls_delete_denied-%tky
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '043'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-auth.
      ENDLOOP.

      RETURN.

    ENDIF.

    LOOP AT keys INTO DATA(ls_delete).

      IF ls_delete-Uname = sy-uname.
        APPEND VALUE #( %tky = ls_delete-%tky ) TO failed-auth.
        APPEND VALUE #(
          %tky = ls_delete-%tky
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '048'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      SELECT SINGLE @abap_true
        FROM zsap20_att_auth
        WHERE uname = @ls_delete-Uname
        INTO @DATA(lv_exists_delete).

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_delete-%tky ) TO failed-auth.
        APPEND VALUE #(
                        %tky = ls_delete-%tky
                        %msg = new_message(
                                id       = 'YGSP26SAP20_MSG'
                                number   = '046'
                                severity = if_abap_behv_message=>severity-error
                                v1       = ( ls_delete-Uname ) )
        ) TO reported-auth.
        CONTINUE.
      ENDIF.

      DATA ls_auth_delete TYPE zsap20_att_auth.
      ls_auth_delete-uname = ls_delete-Uname.
      APPEND ls_auth_delete TO lcl_buffer=>mt_delete.

      APPEND VALUE #(
                      %tky = ls_delete-%tky
                      %msg = new_message(
                              id       = 'YGSP26SAP20_MSG'
                              number   = '036'
                              severity = if_abap_behv_message=>severity-success )
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

    IF lcl_buffer=>mt_create IS NOT INITIAL.
      INSERT zsap20_att_auth FROM TABLE @lcl_buffer=>mt_create.
    ENDIF.

    IF lcl_buffer=>mt_delete IS NOT INITIAL.
      LOOP AT lcl_buffer=>mt_delete INTO DATA(ls_delete).
        DELETE FROM zsap20_att_auth
          WHERE uname = @ls_delete-uname.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lcl_buffer=>mt_create,
           lcl_buffer=>mt_delete.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
