CLASS zcx_attach_validation DEFINITION
  PUBLIC
  INHERITING FROM cx_no_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
   INTERFACES if_t100_message.

    METHODS constructor
      IMPORTING
        iv_text  TYPE string OPTIONAL
        iv_msgid TYPE symsgid OPTIONAL
        iv_msgno TYPE symsgno OPTIONAL
        iv_attr1 TYPE string OPTIONAL
        iv_attr2 TYPE string OPTIONAL
        iv_attr3 TYPE string OPTIONAL
        iv_attr4 TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

  PRIVATE SECTION.
    DATA mv_text TYPE string.
ENDCLASS.


CLASS zcx_attach_validation IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( ).
   IF iv_msgid IS NOT INITIAL AND iv_msgno IS NOT INITIAL.

      me->if_t100_message~t100key = VALUE scx_t100key(
        msgid = iv_msgid
        msgno = iv_msgno
        attr1 = iv_attr1
        attr2 = iv_attr2
        attr3 = iv_attr3
        attr4 = iv_attr4 ).

    ELSE.
      mv_text = iv_text.
    ENDIF.


  ENDMETHOD.

  METHOD get_text.
    IF mv_text IS NOT INITIAL.
    result = mv_text.
  ELSE.
    result = super->get_text( ).
  ENDIF.
  ENDMETHOD.
ENDCLASS.
