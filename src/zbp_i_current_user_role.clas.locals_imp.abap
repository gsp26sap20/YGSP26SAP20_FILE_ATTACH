CLASS lhc_CurrentUserRole DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR CurrentUserRole RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ CurrentUserRole RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK CurrentUserRole.

ENDCLASS.

CLASS lhc_CurrentUserRole IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.

    SELECT
      uname AS Uname,
      role  AS Role
      FROM zsap20_att_auth
      INTO CORRESPONDING FIELDS OF TABLE @result
      WHERE uname = @sy-uname.

    IF result IS INITIAL.
      APPEND VALUE #(
        Uname = sy-uname
        Role  = 'NONE'
      ) TO result.
    ENDIF.

  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.


ENDCLASS.

CLASS lsc_Z_I_CURRENT_USER_ROLE DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z_I_CURRENT_USER_ROLE IMPLEMENTATION.

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
