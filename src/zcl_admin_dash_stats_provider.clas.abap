CLASS zcl_admin_dash_stats_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_result,
        overviewkey                 TYPE c LENGTH 1,
        attachmentscreatedday       TYPE i,
        attachmentscreatedweek      TYPE i,
        attachmentscreatedmonth     TYPE i,
        attachmentscreatedyear      TYPE i,
        bocreatedday                TYPE i,
        bocreatedweek               TYPE i,
        bocreatedmonth              TYPE i,
        bocreatedyear               TYPE i,
        linkscreatedday             TYPE i,
        linkscreatedweek            TYPE i,
        linkscreatedmonth           TYPE i,
        linkscreatedyear            TYPE i,
        deletedattachmentsday       TYPE i,
        deletedattachmentsweek      TYPE i,
        deletedattachmentsmonth     TYPE i,
        deletedattachmentsyear      TYPE i,
        reactivatedattachmentsday   TYPE i,
        reactivatedattachmentsweek  TYPE i,
        reactivatedattachmentsmonth TYPE i,
        reactivatedattachmentsyear  TYPE i,
        unlinkedattachments         TYPE i,
        bowithoutattachments        TYPE i,
      END OF ty_result.

    TYPES tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    METHODS is_admin
      RETURNING VALUE(rv_is_admin) TYPE abap_bool.

    METHODS get_day_range
      EXPORTING ev_date_from TYPE sydatum
                ev_date_to   TYPE sydatum.

    METHODS get_week_range
      EXPORTING ev_date_from TYPE sydatum
                ev_date_to   TYPE sydatum.

    METHODS get_month_range
      EXPORTING ev_date_from TYPE sydatum
                ev_date_to   TYPE sydatum.

    METHODS get_year_range
      EXPORTING ev_date_from TYPE sydatum
                ev_date_to   TYPE sydatum.

    METHODS count_attachments_created
      IMPORTING iv_date_from    TYPE sydatum
                iv_date_to      TYPE sydatum
      RETURNING VALUE(rv_count) TYPE i.

    METHODS count_bo_created
      IMPORTING iv_date_from    TYPE sydatum
                iv_date_to      TYPE sydatum
      RETURNING VALUE(rv_count) TYPE i.

    METHODS count_links_created
      IMPORTING iv_date_from    TYPE sydatum
                iv_date_to      TYPE sydatum
      RETURNING VALUE(rv_count) TYPE i.

    METHODS count_deleted_attachments
      IMPORTING iv_date_from    TYPE sydatum
                iv_date_to      TYPE sydatum
      RETURNING VALUE(rv_count) TYPE i.

    METHODS count_reactivated_attachments
      IMPORTING iv_date_from    TYPE sydatum
                iv_date_to      TYPE sydatum
      RETURNING VALUE(rv_count) TYPE i.

    METHODS count_unlinked_attachments
      RETURNING VALUE(rv_count) TYPE i.

    METHODS count_bo_without_attachments
      RETURNING VALUE(rv_count) TYPE i.
ENDCLASS.



CLASS zcl_admin_dash_stats_provider IMPLEMENTATION.

  METHOD is_admin.
    DATA lv_role TYPE zsap20_att_auth-role.

    rv_is_admin = abap_false.

    SELECT SINGLE role
      FROM zsap20_att_auth
      INTO @lv_role
      WHERE uname = @sy-uname.

    IF sy-subrc = 0 AND lv_role = 'ADMIN'.
      rv_is_admin = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD get_day_range.
    ev_date_from = sy-datum.
    ev_date_to   = sy-datum.
  ENDMETHOD.


  METHOD get_week_range.

    DATA lv_weekday   TYPE scal-indicator.
    DATA lv_weekday_i TYPE i.

    CALL FUNCTION 'DATE_COMPUTE_DAY'
      EXPORTING
        date = sy-datum
      IMPORTING
        day  = lv_weekday.

    lv_weekday_i = lv_weekday.

    ev_date_from = sy-datum - lv_weekday_i + 1.
    ev_date_to   = sy-datum.

  ENDMETHOD.


  METHOD get_month_range.
    DATA lv_year  TYPE n LENGTH 4.
    DATA lv_month TYPE n LENGTH 2.

    lv_year  = sy-datum+0(4).
    lv_month = sy-datum+4(2).

    ev_date_from = |{ lv_year }{ lv_month }01|.
    ev_date_to   = sy-datum.
  ENDMETHOD.


  METHOD get_year_range.
    DATA lv_year TYPE n LENGTH 4.

    lv_year = sy-datum+0(4).

    ev_date_from = |{ lv_year }0101|.
    ev_date_to   = sy-datum.
  ENDMETHOD.


  METHOD if_rap_query_provider~select.

    DATA lt_result       TYPE tt_result.
    DATA lt_result_paged TYPE tt_result.
    DATA ls_result       TYPE ty_result.

    DATA lv_day_from   TYPE sydatum.
    DATA lv_day_to     TYPE sydatum.
    DATA lv_week_from  TYPE sydatum.
    DATA lv_week_to    TYPE sydatum.
    DATA lv_month_from TYPE sydatum.
    DATA lv_month_to   TYPE sydatum.
    DATA lv_year_from  TYPE sydatum.
    DATA lv_year_to    TYPE sydatum.

    DATA lo_paging    TYPE REF TO if_rap_query_paging.
    DATA lv_page_size TYPE i VALUE 0.
    DATA lv_offset    TYPE i VALUE 0.
    DATA lv_from      TYPE i.
    DATA lv_to        TYPE i.

    " auth
    IF is_admin( ) <> abap_true.
      IF io_request->is_total_numb_of_rec_requested( ).
        io_response->set_total_number_of_records( 0 ).
      ENDIF.

      IF io_request->is_data_requested( ).
        io_response->set_data( VALUE tt_result( ) ).
      ENDIF.
      RETURN.
    ENDIF.

    " paging safe
    lo_paging = io_request->get_paging( ).
    IF lo_paging IS BOUND.
      lv_page_size = lo_paging->get_page_size( ).
      lv_offset    = lo_paging->get_offset( ).
    ENDIF.

    " date range
    get_day_range(   IMPORTING ev_date_from = lv_day_from   ev_date_to = lv_day_to ).
    get_week_range(  IMPORTING ev_date_from = lv_week_from  ev_date_to = lv_week_to ).
    get_month_range( IMPORTING ev_date_from = lv_month_from ev_date_to = lv_month_to ).
    get_year_range(  IMPORTING ev_date_from = lv_year_from  ev_date_to = lv_year_to ).

    " build data
    CLEAR ls_result.
    ls_result-overviewkey = '1'.

    ls_result-attachmentscreatedday = count_attachments_created(
      iv_date_from = lv_day_from
      iv_date_to   = lv_day_to ).

    ls_result-attachmentscreatedweek = count_attachments_created(
      iv_date_from = lv_week_from
      iv_date_to   = lv_week_to ).

    ls_result-attachmentscreatedmonth = count_attachments_created(
      iv_date_from = lv_month_from
      iv_date_to   = lv_month_to ).

    ls_result-attachmentscreatedyear = count_attachments_created(
      iv_date_from = lv_year_from
      iv_date_to   = lv_year_to ).

    ls_result-bocreatedday = count_bo_created(
      iv_date_from = lv_day_from
      iv_date_to   = lv_day_to ).

    ls_result-bocreatedweek = count_bo_created(
      iv_date_from = lv_week_from
      iv_date_to   = lv_week_to ).

    ls_result-bocreatedmonth = count_bo_created(
      iv_date_from = lv_month_from
      iv_date_to   = lv_month_to ).

    ls_result-bocreatedyear = count_bo_created(
      iv_date_from = lv_year_from
      iv_date_to   = lv_year_to ).

    ls_result-linkscreatedday = count_links_created(
      iv_date_from = lv_day_from
      iv_date_to   = lv_day_to ).

    ls_result-linkscreatedweek = count_links_created(
      iv_date_from = lv_week_from
      iv_date_to   = lv_week_to ).

    ls_result-linkscreatedmonth = count_links_created(
      iv_date_from = lv_month_from
      iv_date_to   = lv_month_to ).

    ls_result-linkscreatedyear = count_links_created(
      iv_date_from = lv_year_from
      iv_date_to   = lv_year_to ).

    ls_result-deletedattachmentsday = count_deleted_attachments(
      iv_date_from = lv_day_from
      iv_date_to   = lv_day_to ).

    ls_result-deletedattachmentsweek = count_deleted_attachments(
      iv_date_from = lv_week_from
      iv_date_to   = lv_week_to ).

    ls_result-deletedattachmentsmonth = count_deleted_attachments(
      iv_date_from = lv_month_from
      iv_date_to   = lv_month_to ).

    ls_result-deletedattachmentsyear = count_deleted_attachments(
      iv_date_from = lv_year_from
      iv_date_to   = lv_year_to ).

    ls_result-reactivatedattachmentsday = count_reactivated_attachments(
      iv_date_from = lv_day_from
      iv_date_to   = lv_day_to ).

    ls_result-reactivatedattachmentsweek = count_reactivated_attachments(
      iv_date_from = lv_week_from
      iv_date_to   = lv_week_to ).

    ls_result-reactivatedattachmentsmonth = count_reactivated_attachments(
      iv_date_from = lv_month_from
      iv_date_to   = lv_month_to ).

    ls_result-reactivatedattachmentsyear = count_reactivated_attachments(
      iv_date_from = lv_year_from
      iv_date_to   = lv_year_to ).

    ls_result-unlinkedattachments = count_unlinked_attachments( ).
    ls_result-bowithoutattachments = count_bo_without_attachments( ).
    APPEND ls_result TO lt_result.

    " total
    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.

    " paging
    IF lv_page_size <= 0.
      lt_result_paged = lt_result.
    ELSE.
      lv_from = lv_offset + 1.
      lv_to   = lv_offset + lv_page_size.

      LOOP AT lt_result INTO ls_result FROM lv_from TO lv_to.
        APPEND ls_result TO lt_result_paged.
      ENDLOOP.
    ENDIF.

    " return
    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result_paged ).
    ENDIF.

  ENDMETHOD.

  METHOD count_attachments_created.
    SELECT COUNT( * )
      FROM zsap20_file_mgmt
      WHERE erdat >= @iv_date_from
        AND erdat <= @iv_date_to
      INTO @rv_count.
  ENDMETHOD.


  METHOD count_bo_created.
    SELECT COUNT( * )
      FROM zsap20_biz_obj
      WHERE erdat >= @iv_date_from
        AND erdat <= @iv_date_to
      INTO @rv_count.
  ENDMETHOD.


  METHOD count_links_created.
    SELECT COUNT( * )
      FROM zsap20_bo_att_lk
      WHERE erdat >= @iv_date_from
        AND erdat <= @iv_date_to
      INTO @rv_count.
  ENDMETHOD.


  METHOD count_deleted_attachments.
    SELECT COUNT( DISTINCT file_id )
      FROM zsap20_att_audit
      WHERE action = 'DELETE'
        AND erdat >= @iv_date_from
        AND erdat <= @iv_date_to
      INTO @rv_count.
  ENDMETHOD.


  METHOD count_reactivated_attachments.
    SELECT COUNT( DISTINCT file_id )
      FROM zsap20_att_audit
      WHERE action = 'REACTIVATE'
        AND erdat >= @iv_date_from
        AND erdat <= @iv_date_to
      INTO @rv_count.
  ENDMETHOD.


  METHOD count_unlinked_attachments.
    SELECT COUNT( * )
      FROM zsap20_file_mgmt AS f
      WHERE NOT EXISTS (
        SELECT *
          FROM zsap20_bo_att_lk AS l
          WHERE l~file_id = f~file_id )
      INTO @rv_count.
  ENDMETHOD.


  METHOD count_bo_without_attachments.
    SELECT COUNT( * )
      FROM zsap20_biz_obj AS b
      WHERE NOT EXISTS (
        SELECT *
          FROM zsap20_bo_att_lk AS l
          WHERE l~bo_id = b~bo_id )
      INTO @rv_count.
  ENDMETHOD.

ENDCLASS.
