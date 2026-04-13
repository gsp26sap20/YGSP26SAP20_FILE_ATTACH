CLASS lhc_BizObj DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR BizObj RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR BizObj RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE BizObj.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE BizObj.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE BizObj.

    METHODS read FOR READ
      IMPORTING keys FOR READ BizObj RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK BizObj.

    METHODS rba_Links FOR READ
      IMPORTING keys_rba FOR READ BizObj\_Links FULL result_requested RESULT result LINK association_links.

    METHODS link_attachment FOR MODIFY
      IMPORTING keys FOR ACTION BizObj~link_attachment RESULT result.

ENDCLASS.

CLASS lhc_BizObj IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  "Bình
  METHOD create.
    DATA: ls_biz_obj TYPE zsap20_biz_obj,
          lv_bo_id   TYPE sysuuid_x16. " var to  store UUID

    LOOP AT entities INTO DATA(ls_entity).

      " 1. Validate Title
      DATA(lv_title) = ls_entity-BoTitle.
      " Remove whitespace at begining, end
      CONDENSE lv_title.
      REPLACE ALL OCCURRENCES OF `ㅤ` IN lv_title WITH ``.

      " If empty (or all empty characters) -> block.
      IF lv_title IS INITIAL.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-bizobj.
        APPEND VALUE #( %cid = ls_entity-%cid
                        %msg = new_message(
                               id       = 'YGSP26SAP20_MSG'
                               number   = '039'
                               severity = if_abap_behv_message=>severity-error )
                        %element-BoTitle = if_abap_behv=>mk-on " warning Type field
                      ) TO reported-bizobj.
        CONTINUE. " skip creation
      ENDIF.

      " 2. Validate Type
      DATA(lv_type) = ls_entity-BoType.

      IF lv_type <> 'PORDER' AND lv_type <> 'SORDER' AND lv_type <> 'INVOICE'.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-bizobj.
        APPEND VALUE #( %cid = ls_entity-%cid
                        %msg = new_message(
                               id       = 'YGSP26SAP20_MSG'
                               number   = '040'
                               severity = if_abap_behv_message=>severity-error )
                        %element-BoType = if_abap_behv=>mk-on
                      ) TO reported-bizobj.
        CONTINUE.
      ENDIF.

      " 3. Status validation
      DATA(lv_status) = ls_entity-Status.

      " If not enter, "New" is default
      IF lv_status IS INITIAL.
        lv_status = 'NEW'.
      ENDIF.

      " Check if entered status is permitted
      IF lv_status <> 'NEW' AND lv_status <> 'INPR' AND lv_status <> 'COMP'.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-bizobj.
        APPEND VALUE #( %cid = ls_entity-%cid
                        %msg = new_message(
                               id       = 'YGSP26SAP20_MSG'
                               number   = '041'
                               severity = if_abap_behv_message=>severity-error )
                        %element-Status = if_abap_behv=>mk-on
                      ) TO reported-bizobj.
        CONTINUE. " Skip this entry, do not proceed continue
      ENDIF.

      "4. Create UUID for BoId
      CLEAR lv_bo_id.
      TRY.
          lv_bo_id = cl_system_uuid=>create_uuid_x16_static(  ).
        CATCH cx_uuid_error.
          APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-bizobj.
          APPEND VALUE #( %cid = ls_entity-%cid
                          %msg = new_message(
                               id       = 'YGSP26SAP20_MSG'
                               number   = '042'
                               severity = if_abap_behv_message=>severity-error )
                        ) TO reported-bizobj.
          CONTINUE.
      ENDTRY.

      "5. bring data to Buffer
      CLEAR ls_biz_obj.
      ls_biz_obj-bo_id    = lv_bo_id.
      ls_biz_obj-bo_type  = ls_entity-BoType.
      ls_biz_obj-bo_title = ls_entity-BoTitle.
      ls_biz_obj-status   = lv_status.
      ls_biz_obj-erdat    = sy-datum.
      ls_biz_obj-erzet    = sy-uzeit.
      ls_biz_obj-ernam    = sy-uname.
      ls_biz_obj-aedat    = sy-datum.
      ls_biz_obj-aezet    = sy-uzeit.
      ls_biz_obj-aenam    = sy-uname.

      APPEND ls_biz_obj TO zbp_i_biz_obj_r=>gt_bo_create.

      "6. Noti success to Fiori
      APPEND VALUE #( %cid = ls_entity-%cid
                      BoId = lv_bo_id ) TO mapped-bizobj.

      APPEND VALUE #( %cid = ls_entity-%cid
                      %msg = new_message(
                               id       = 'YGSP26SAP20_MSG'
                               number   = '036'
                               severity = if_abap_behv_message=>severity-success )
                    ) TO reported-bizobj.
    ENDLOOP.
  ENDMETHOD.
  "CHương
  METHOD update.

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT entities INTO DATA(ls_entity).
      "Check tồn tại
      SELECT SINGLE bo_id
       FROM zsap20_biz_obj
       WHERE bo_id = @ls_entity-BoId
       INTO @DATA(lv_exist).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_entity-%tky ) TO failed-bizobj.
        APPEND VALUE #(
          %tky = ls_entity-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Business Object '{ ls_entity-BoId }' not found.| )
        ) TO reported-bizobj.
        CONTINUE.
      ENDIF.

      "Update (chỉ update field business + audit)
      UPDATE zsap20_biz_obj
        SET
          bo_type  = @ls_entity-BoType,
          bo_title = @ls_entity-BoTitle,
          status   = @ls_entity-Status,
          aedat    = @sy-datum,
          aezet    = @sy-uzeit,
          aenam    = @sy-uname
        WHERE bo_id = @ls_entity-BoId.

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_entity-%tky ) TO failed-bizobj.
        APPEND VALUE #(
          %tky = ls_entity-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Update failed for BO '{ ls_entity-BoId }'.| )
        ) TO reported-bizobj.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky = ls_entity-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Updated BO '{ ls_entity-BoId }'.| )
      ) TO reported-bizobj.

    ENDLOOP.
  ENDMETHOD.
  "BÌnh
  METHOD delete.
    DATA: ls_bo_del   TYPE zsap20_biz_obj,
          lv_has_link TYPE abap_bool.

    LOOP AT keys INTO DATA(ls_key).
      " 1. Prevent deletion if linked to attachments
      CLEAR lv_has_link.
      SELECT SINGLE @abap_true
        FROM zsap20_bo_att_lk
        WHERE bo_id = @ls_key-BoId
        INTO @lv_has_link.

      " If found link -> can't delete
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-bizobj.
        APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message(
                     id         = 'YGSP26SAP20_MSG'
                     number     = '031'
                     severity   = if_abap_behv_message=>severity-error )

        ) TO reported-bizobj.
        CONTINUE. " Skip this record, no push to buffer
      ENDIF.

      " 2. Bring BO want delete to buffer
      ls_bo_del-bo_id = ls_key-BoId.
      APPEND ls_bo_del TO zbp_i_biz_obj_r=>gt_bo_delete.

      APPEND VALUE #( %tky = ls_key-%tky
                      %msg = new_message(
                             id         = 'YGSP26SAP20_MSG'
                             number     = '032'
                             severity   = if_abap_behv_message=>severity-success )
                    ) TO reported-bizobj.
    ENDLOOP.
  ENDMETHOD.
  " Chương
  METHOD read.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    SELECT
    bo_id   AS BoId,
    bo_type   AS BoType,
    bo_title  AS BoTitle,
    status    AS Status,
    erdat     AS Erdat,
    erzet     AS Erzet,
    ernam     AS Ernam,
    aedat     AS Aedat,
    aezet     AS Aezet,
    aenam     AS Aenam
    FROM zsap20_biz_obj
    INTO CORRESPONDING FIELDS OF TABLE @result
    FOR ALL ENTRIES IN @keys
    WHERE bo_id = @keys-BoId.

  ENDMETHOD.
  " Chương
  METHOD lock.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).
      " Check BO exists and lock DB row
      SELECT SINGLE bo_id
        FROM zsap20_biz_obj
        WHERE bo_id = @ls_key-BoId
        INTO @DATA(lv_bo_id).

      IF sy-subrc <> 0.
        APPEND VALUE #( BoId = ls_key-BoId ) TO failed-bizobj.
        APPEND VALUE #(
          BoId = ls_key-BoId
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Business Object '{ ls_key-BoId }' not found or cannot be locked.| )
        ) TO reported-bizobj.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  " Chương
  METHOD rba_Links.
    DATA lt_link TYPE STANDARD TABLE OF zsap20_bo_att_lk.

    IF keys_rba IS INITIAL.
      RETURN.
    ENDIF.

    " Read all links
    SELECT bo_id,
           file_id,
           erdat,
           erzet,
           ernam
    FROM zsap20_bo_att_lk
         INTO CORRESPONDING FIELDS OF TABLE @lt_link
         FOR ALL ENTRIES IN @keys_rba
          WHERE bo_id = @keys_rba-BoId.

    IF lt_link IS INITIAL.
      RETURN.
    ENDIF.

    " Fill result
    result = VALUE #(
    FOR ls_link_row IN lt_link (
        BoId   = ls_link_row-bo_id
        FileId = ls_link_row-file_id
        Erdat  = ls_link_row-erdat
        Erzet  = ls_link_row-erzet
        Ernam  = ls_link_row-ernam
       )
    ).

    " Build association links
    LOOP AT keys_rba INTO DATA(ls_rba).
      LOOP AT lt_link INTO DATA(ls_link) WHERE bo_id = ls_rba-BoId.
        APPEND VALUE #(
               source-%key = ls_rba-%key
               target-%key = VALUE #(
                                     BoId   = ls_link-bo_id
                                     FileId = ls_link-file_id
                )
            ) TO association_links.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  " Bình
  METHOD link_attachment.
    DATA: ls_link_db TYPE zsap20_bo_att_lk.

    LOOP AT keys INTO DATA(ls_key).
      " 1. Get FileId from Fiori
      DATA(lv_file_id) = ls_key-%param-file_id.

      " 2. Validate: Must have FileId
      IF lv_file_id IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-bizobj.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message(
                                id         = 'YGSP26SAP20_MSG'
                                number     = '033'
                                severity = if_abap_behv_message=>severity-error )
                      ) TO reported-bizobj.
        CONTINUE.
      ENDIF.

      " 2.1 Validate: file must have at least one version
      TRY.
          zcl_attach_validation=>check_attachment_has_version(
            iv_file_id = lv_file_id
          ).
        CATCH zcx_attach_validation INTO DATA(lx_validation).
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-bizobj.
          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lx_validation->get_text( ) )
          ) TO reported-bizobj.
          CONTINUE.
      ENDTRY.

      " 3. Validate: Has file exists and active?
      SELECT SINGLE @abap_true
          FROM zsap20_file_mgmt
          WHERE file_id = @lv_file_id
              AND is_active = @abap_true
          INTO @DATA(lv_file_exists).

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-bizobj.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message(
                                id         = 'YGSP26SAP20_MSG'
                                number     = '034'
                                severity   = if_abap_behv_message=>severity-error
                                v1         = lv_file_id )
                      ) TO reported-bizobj.
        CONTINUE.
      ENDIF.

      " 4. Validate: Check duplicate (both DB & Buffer)
      SELECT SINGLE @abap_true
          FROM zsap20_bo_att_lk
          WHERE bo_id = @ls_key-BoId AND file_id = @lv_file_id
          INTO @DATA(lv_link_exists).

      DATA(lv_in_buffer) = abap_false.
      IF line_exists( zbp_i_biz_obj_r=>gt_link_buffer[ bo_id = ls_key-BoId file_id = lv_file_id ] ).
        lv_in_buffer = abap_true.
      ENDIF.

      IF lv_link_exists = abap_true OR lv_in_buffer = abap_true.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-bizobj.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message(
                                id         = 'YGSP26SAP20_MSG'
                                number     = '035'
                                severity   = if_abap_behv_message=>severity-warning )
                  ) TO reported-bizobj.
        CONTINUE.
      ENDIF.

      " 5. bring data to Buffer
      CLEAR ls_link_db.
      ls_link_db-bo_id   = ls_key-BoId.
      ls_link_db-file_id = lv_file_id.
      ls_link_db-erdat   = sy-datum.
      ls_link_db-erzet   = sy-uzeit.
      ls_link_db-ernam   = sy-uname.

      APPEND ls_link_db TO zbp_i_biz_obj_r=>gt_link_buffer.

      " 5.1 Update BO last modified time
      UPDATE zsap20_biz_obj
        SET aedat = @sy-datum,
            aezet = @sy-uzeit,
            aenam = @sy-uname
        WHERE bo_id = @ls_key-BoId.
      " 6. Return
      APPEND VALUE #( %tky        = ls_key-%tky
                      %param-%tky = ls_key-%tky ) TO result.

      APPEND VALUE #( %tky = ls_key-%tky
                      %msg = new_message(
                               id       = 'YGSP26SAP20_MSG'
                               number   = '036'
                               severity = if_abap_behv_message=>severity-success )
                    ) TO reported-bizobj.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_AttBizLk DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE AttBizLk.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE AttBizLk.

    METHODS read FOR READ
      IMPORTING keys FOR READ AttBizLk RESULT result.

    METHODS rba_Attach FOR READ
      IMPORTING keys_rba FOR READ AttBizLk\_Attach FULL result_requested RESULT result LINK association_links.

    METHODS rba_Bo FOR READ
      IMPORTING keys_rba FOR READ AttBizLk\_Bo FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_AttBizLk IMPLEMENTATION.

  "Hải
  METHOD create.
    DATA: ls_link_db     TYPE zsap20_bo_att_lk,
          lv_bo_exists   TYPE abap_bool,
          lv_file_exists TYPE abap_bool,
          lv_link_exists TYPE abap_bool,
          lv_in_buffer   TYPE abap_bool,
          lx_validation  TYPE REF TO zcx_attach_validation.

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT entities INTO DATA(ls_entity).

      " 1. Validate: BoId and FileId must not be empty
      IF ls_entity-BoId IS INITIAL OR ls_entity-FileId IS INITIAL.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-attbizlk.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '037'
                   severity = if_abap_behv_message=>severity-error )
        ) TO reported-attbizlk.
        CONTINUE.
      ENDIF.

      " 2. Validate: file must have at least one version
      CLEAR lx_validation.
      TRY.
          zcl_attach_validation=>check_attachment_has_version(
            iv_file_id = ls_entity-FileId
          ).
        CATCH zcx_attach_validation INTO lx_validation.
          APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-attbizlk.
          APPEND VALUE #(
            %cid = ls_entity-%cid
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lx_validation->get_text( ) )
          ) TO reported-attbizlk.
          CONTINUE.
      ENDTRY.

      " 3. Validate: BO exists
      CLEAR lv_bo_exists.
      SELECT SINGLE @abap_true
        FROM zsap20_biz_obj
        WHERE bo_id = @ls_entity-BoId
        INTO @lv_bo_exists.

      IF sy-subrc <> 0.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-attbizlk.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message(
                   id       = 'YGSP26SAP20_MSG'
                   number   = '038'
                   severity = if_abap_behv_message=>severity-error
                   v1       = ( ls_entity-BoId ) )
        ) TO reported-attbizlk.
        CONTINUE.
      ENDIF.

      " 4. Validate: file exists and active
      CLEAR lv_file_exists.
      SELECT SINGLE @abap_true
        FROM zsap20_file_mgmt
        WHERE file_id   = @ls_entity-FileId
          AND is_active = @abap_true
        INTO @lv_file_exists.

      IF sy-subrc <> 0.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-attbizlk.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message(
                                id         = 'YGSP26SAP20_MSG'
                                number     = '034'
                                severity   = if_abap_behv_message=>severity-error
                                v1         = ls_entity-FileId )
        ) TO reported-attbizlk.
        CONTINUE.
      ENDIF.

      " 5. Validate: duplicate in DB
      CLEAR lv_link_exists.
      SELECT SINGLE @abap_true
        FROM zsap20_bo_att_lk
        WHERE bo_id   = @ls_entity-BoId
          AND file_id = @ls_entity-FileId
        INTO @lv_link_exists.

      " 6. Validate: duplicate in buffer
      lv_in_buffer = abap_false.
      IF line_exists( zbp_i_biz_obj_r=>gt_link_buffer[
                        bo_id   = ls_entity-BoId
                        file_id = ls_entity-FileId ] ).
        lv_in_buffer = abap_true.
      ENDIF.

      IF lv_link_exists = abap_true OR lv_in_buffer = abap_true.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-attbizlk.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message(
                                id         = 'YGSP26SAP20_MSG'
                                number     = '035'
                                severity   = if_abap_behv_message=>severity-warning )
        ) TO reported-attbizlk.
        CONTINUE.
      ENDIF.

      " 7. Add to buffer
      CLEAR ls_link_db.
      ls_link_db-bo_id   = ls_entity-BoId.
      ls_link_db-file_id = ls_entity-FileId.
      ls_link_db-erdat   = sy-datum.
      ls_link_db-erzet   = sy-uzeit.
      ls_link_db-ernam   = sy-uname.

      APPEND ls_link_db TO zbp_i_biz_obj_r=>gt_link_buffer.

      " 8. Map and report success
      APPEND VALUE #(
        %cid   = ls_entity-%cid
        BoId   = ls_entity-BoId
        FileId = ls_entity-FileId
      ) TO mapped-attbizlk.

      APPEND VALUE #(
        %cid = ls_entity-%cid
        %msg = new_message(
                 id       = 'YGSP26SAP20_MSG'
                 number   = '036'
                 severity = if_abap_behv_message=>severity-success )
      ) TO reported-attbizlk.

    ENDLOOP.
  ENDMETHOD.
  "Chương
  METHOD delete.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).

      DELETE FROM zsap20_bo_att_lk
    WHERE bo_id   = @ls_key-BoId
      AND file_id = @ls_key-FileId.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attbizlk.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                    text     = |Link not found (BoId={ ls_key-BoId }, FileId={ ls_key-FileId }).| )
        ) TO reported-attbizlk.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky = ls_key-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Unlinked attachment from BO successfully.| )
      ) TO reported-attbizlk.

    ENDLOOP.
  ENDMETHOD.
  "Bình
  METHOD read.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    SELECT bo_id    AS BoId,
           file_id  AS FileId,
           erdat    AS Erdat,
           erzet    AS Erzet,
           ernam    AS Ernam
    FROM zsap20_bo_att_lk
    INTO CORRESPONDING FIELDS OF TABLE @result
    FOR ALL ENTRIES IN @keys
    WHERE   bo_id   = @keys-BoId
      AND   file_id = @keys-FileId.

  ENDMETHOD.
  "BÌnh
  METHOD rba_Attach.
    DATA: lt_link TYPE STANDARD TABLE OF zsap20_bo_att_lk,
          lt_file TYPE STANDARD TABLE OF zsap20_file_mgmt.

    " 1. Get list links
    SELECT bo_id, file_id
      FROM zsap20_bo_att_lk
      INTO CORRESPONDING FIELDS OF TABLE @lt_link
      FOR ALL ENTRIES IN @keys_rba
      WHERE bo_id   = @keys_rba-BoId
        AND file_id = @keys_rba-FileId.

    IF lt_link IS INITIAL.
      RETURN.
    ENDIF.

    " 2. Get attachment details based on FileID of Link table
    SELECT file_id, title, current_version, is_active, erdat, erzet, ernam, aedat, aezet, aenam, edit_lock
        FROM zsap20_file_mgmt
        INTO CORRESPONDING FIELDS OF TABLE @lt_file
        FOR ALL ENTRIES IN @lt_link
        WHERE file_id = @lt_link-file_id.

    " 3. Return result
    result = VALUE #(
        FOR f IN lt_file (
            FileId         = f-file_id
            Title          = f-title
            CurrentVersion = f-current_version
            IsActive       = f-is_active
            Erdat          = f-erdat
            Erzet          = f-erzet
            Ernam          = f-ernam
            Aedat          = f-aedat
            Aezet          = f-aezet
            Aenam          = f-aenam
            EditLock       = f-edit_lock
        )
    ).

    " 4. Build Association Links help Fiori understand
    LOOP AT keys_rba INTO DATA(ls_rba).
      READ TABLE lt_link INTO DATA(ls_l) WITH KEY bo_id = ls_rba-BoId file_id = ls_rba-FileId.
      IF sy-subrc = 0.
        APPEND VALUE #(
            source-%key = ls_rba-%key
            target-%key = VALUE #( FileId = ls_l-file_id )
        ) TO association_links.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
  "Chương
  METHOD rba_Bo.
    DATA: lt_link TYPE STANDARD TABLE OF zsap20_bo_att_lk,
          lt_bo   TYPE STANDARD TABLE OF zsap20_biz_obj.

    IF keys_rba IS INITIAL.
      RETURN.
    ENDIF.

    "Read link record
    SELECT bo_id, file_id FROM zsap20_bo_att_lk
           INTO CORRESPONDING FIELDS OF TABLE @lt_link
           FOR ALL ENTRIES IN @keys_rba
           WHERE bo_id   = @keys_rba-BoId AND
                 file_id = @keys_rba-FileId.

    IF lt_link IS INITIAL.
      RETURN.
    ENDIF.

    "Read BO info
    SELECT bo_id,
           bo_type,
           bo_title,
           status,
           erdat,
           erzet,
           ernam,
           aedat,
           aezet,
           aenam
    FROM zsap20_biz_obj INTO CORRESPONDING FIELDS OF TABLE @lt_bo
    FOR ALL ENTRIES IN @lt_link
    WHERE bo_id = @lt_link-bo_id.

    "Fill result
    result = VALUE #(
           FOR b IN lt_bo (
           BoID    = b-bo_id
           BoType  = b-bo_type
           BoTitle = b-bo_title
           Status  = b-status
           Erdat   = b-erdat
           Erzet   = b-erzet
           Ernam   = b-ernam
           Aedat   = b-aedat
           Aezet   = b-aezet
           Aenam   = b-aenam
           )
    ).

    "Build association link
    LOOP AT keys_rba INTO DATA(ls_rba).
      READ TABLE lt_link INTO DATA(ls_link)
          WITH KEY bo_id   = ls_rba-BoId
                   file_id = ls_rba-FileId.
      IF sy-subrc = 0.
        APPEND VALUE #(
               source-%key = ls_rba-%key
               target-%key = VALUE #( BoId = ls_link-bo_id )
              ) TO association_links.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z_I_BIZ_OBJ_R DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

    METHODS map_messages REDEFINITION.

ENDCLASS.

CLASS lsc_Z_I_BIZ_OBJ_R IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  "binh
  METHOD save.
    " 1. Handle creation buffer
    IF zbp_i_biz_obj_r=>gt_bo_create IS NOT INITIAL.
      INSERT zsap20_biz_obj FROM TABLE @zbp_i_biz_obj_r=>gt_bo_create.
    ENDIF.

    " 2. Handle delete buffer
    IF zbp_i_biz_obj_r=>gt_bo_delete IS NOT INITIAL.
      " Delete all files attached to this BO first
      LOOP AT zbp_i_biz_obj_r=>gt_bo_delete INTO DATA(ls_bo_del_db).
        DELETE FROM zsap20_bo_att_lk WHERE bo_id = @ls_bo_del_db-bo_id.
      ENDLOOP.

      " Next, delete main BO shell
      DELETE zsap20_biz_obj FROM TABLE @zbp_i_biz_obj_r=>gt_bo_delete.
    ENDIF.

    " 3. Save buffer link to DB
    IF zbp_i_biz_obj_r=>gt_link_buffer IS NOT INITIAL.
      INSERT zsap20_bo_att_lk FROM TABLE @zbp_i_biz_obj_r=>gt_link_buffer ACCEPTING DUPLICATE KEYS.
    ENDIF.
  ENDMETHOD.

  " binh
  METHOD cleanup.
    CLEAR: zbp_i_biz_obj_r=>gt_bo_create,
           zbp_i_biz_obj_r=>gt_bo_delete,
           zbp_i_biz_obj_r=>gt_link_buffer.
  ENDMETHOD.
  " binh
  METHOD cleanup_finalize.
    CLEAR: zbp_i_biz_obj_r=>gt_bo_create,
           zbp_i_biz_obj_r=>gt_bo_delete,
           zbp_i_biz_obj_r=>gt_link_buffer.
  ENDMETHOD.

  METHOD map_messages.
  ENDMETHOD.

ENDCLASS.
