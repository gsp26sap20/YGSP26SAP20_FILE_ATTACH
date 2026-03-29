CLASS lhc_Attach DEFINITION INHERITING FROM cl_abap_behavior_handler.


  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Attach RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Attach RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
  IMPORTING REQUEST requested_authorizations FOR Attach RESULT result.

    METHODS get_global_features FOR GLOBAL FEATURES
      IMPORTING REQUEST requested_features FOR Attach RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Attach.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Attach.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Attach.

    METHODS read FOR READ
      IMPORTING keys FOR READ Attach RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Attach.

    METHODS rba_Versions FOR READ
      IMPORTING keys_rba FOR READ Attach\_Versions FULL result_requested RESULT result LINK association_links.

*    METHODS deactivate FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~deactivate RESULT result.

    METHODS link_to_bo FOR MODIFY
      IMPORTING keys FOR ACTION Attach~link_to_bo RESULT result.
    METHODS cba_Versions FOR MODIFY
      IMPORTING entities_cba FOR CREATE Attach\_Versions.
    METHODS deactivate FOR MODIFY
      IMPORTING keys FOR ACTION Attach~deactivate RESULT result.
    METHODS reactivate FOR MODIFY
      IMPORTING keys FOR ACTION Attach~reactivate RESULT result.
    METHODS download_version FOR MODIFY
      IMPORTING keys FOR ACTION Attach~download_version RESULT result.
    METHODS rba_Audit FOR READ
      IMPORTING keys_rba FOR READ Attach\_Audit FULL result_requested RESULT result LINK association_links.
    METHODS get_user_role
      RETURNING VALUE(rv_role) TYPE zsap20_att_auth-role.

    METHODS is_admin
      RETURNING VALUE(rv_admin) TYPE abap_bool.

    METHODS is_owner
      IMPORTING iv_file_id      TYPE zsap20_file_mgmt-file_id
      RETURNING VALUE(rv_owner) TYPE abap_bool.

    METHODS can_update_attach
      IMPORTING iv_file_id        TYPE zsap20_file_mgmt-file_id
      RETURNING VALUE(rv_allowed) TYPE abap_bool.

    METHODS can_delete_attach
      IMPORTING iv_file_id        TYPE zsap20_file_mgmt-file_id
      RETURNING VALUE(rv_allowed) TYPE abap_bool.

*    METHODS rollback_version FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~rollback_version RESULT result.

*    METHODS upload_att_ver FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~upload_att_ver RESULT result.
*
*    METHODS upload_new_version FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~upload_new_version RESULT result.

*    METHODS view_version FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~view_version RESULT result.



*    METHODS rollback_version FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~rollback_version RESULT result.

*    METHODS upload_new_version FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~upload_new_version RESULT result.
*
*    METHODS view_version FOR MODIFY
*      IMPORTING keys FOR ACTION Attach~view_version RESULT result.
    METHODS rba_CurrentVersion FOR READ
      IMPORTING keys_rba FOR READ Attach\_CurrentVersion FULL result_requested RESULT result LINK association_links.
    METHODS rba_Links FOR READ
      IMPORTING keys_rba FOR READ Attach\_Links FULL result_requested RESULT result LINK association_links.



ENDCLASS.

CLASS lhc_Attach IMPLEMENTATION.

  METHOD get_instance_features.

    result = VALUE #(
      FOR key IN keys
      (
        %tky = key-%tky

        %update = COND #(
          WHEN can_update_attach( key-FileId ) = abap_true
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )

        %delete = COND #(
          WHEN can_delete_attach( key-FileId ) = abap_true
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )

*      %assoc-_Versions = COND #(
*        WHEN can_update_attach( key-FileId ) = abap_true
*        THEN if_abap_behv=>fc-o-enabled
*        ELSE if_abap_behv=>fc-o-disabled )

        %action-download_version = if_abap_behv=>fc-o-enabled

        %action-link_to_bo = if_abap_behv=>fc-o-enabled

        %action-deactivate = COND #(
          WHEN can_delete_attach( key-FileId ) = abap_true
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )

        %action-reactivate = COND #(
          WHEN is_admin( ) = abap_true
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )
      )
    ).

  ENDMETHOD.


  "Ai có quyền abc gì đó trên lớp này - Hải
  METHOD get_instance_authorizations.

    result = VALUE #(
      FOR key IN keys
      (
        %tky = key-%tky

        %update = COND #(
          WHEN can_update_attach( key-FileId ) = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )

        %delete = COND #(
          WHEN can_delete_attach( key-FileId ) = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )

        %action-download_version = if_abap_behv=>auth-allowed

        %action-link_to_bo = if_abap_behv=>auth-allowed

        %action-deactivate = COND #(
          WHEN can_delete_attach( key-FileId ) = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )

        %action-reactivate = COND #(
          WHEN is_admin( ) = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )
      )
    ).

  ENDMETHOD.

  METHOD get_global_authorizations.

    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.


  METHOD get_global_features.

    IF requested_features-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>fc-o-enabled.
    ENDIF.

  ENDMETHOD.


  METHOD get_user_role.
    CLEAR rv_role.

    SELECT SINGLE role
      FROM zsap20_att_auth
      INTO @rv_role
      WHERE uname = @sy-uname.
  ENDMETHOD.

  METHOD is_admin.
    DATA lv_role TYPE zsap20_att_auth-role.

    rv_admin = abap_false.

    SELECT SINGLE role
      FROM zsap20_att_auth
      INTO @lv_role
      WHERE uname = @sy-uname.

    IF sy-subrc = 0 AND lv_role = 'ADMIN'.
      rv_admin = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD is_owner.
    DATA lv_ernam TYPE zsap20_file_mgmt-ernam.

    rv_owner = abap_false.

    READ TABLE zbp_i_attach_r=>gt_attach_buffer INTO DATA(ls_buf)
      WITH KEY file_id = iv_file_id.

    IF sy-subrc = 0.
      lv_ernam = ls_buf-ernam.
    ELSE.
      SELECT SINGLE ernam
        FROM zsap20_file_mgmt
        INTO @lv_ernam
        WHERE file_id = @iv_file_id.
    ENDIF.

    IF lv_ernam = sy-uname.
      rv_owner = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD can_update_attach.
    DATA: lv_edit_lock TYPE zsap20_file_mgmt-edit_lock.

    rv_allowed = abap_false.

    IF is_admin( ) = abap_true.
      rv_allowed = abap_true.
      RETURN.
    ENDIF.

    READ TABLE zbp_i_attach_r=>gt_attach_buffer INTO DATA(ls_buf)
      WITH KEY file_id = iv_file_id.

    IF sy-subrc = 0.
      lv_edit_lock = ls_buf-edit_lock.
      IF lv_edit_lock = abap_false.
        rv_allowed = abap_true.
        RETURN.
      ENDIF.
    ELSE.
      SELECT SINGLE edit_lock
        FROM zsap20_file_mgmt
        INTO @lv_edit_lock
        WHERE file_id = @iv_file_id.

      IF sy-subrc = 0 AND lv_edit_lock = abap_false.
        rv_allowed = abap_true.
        RETURN.
      ENDIF.
    ENDIF.

    IF is_owner( iv_file_id ) = abap_true.
      rv_allowed = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD can_delete_attach.
    rv_allowed = abap_false.

    IF is_admin( ) = abap_true OR is_owner( iv_file_id ) = abap_true.
      rv_allowed = abap_true.
    ENDIF.
  ENDMETHOD.

  "Tạo Attachment - Hải
  METHOD create.

    DATA: lv_file_id   TYPE sysuuid_x16,
          lv_edit_lock TYPE abap_bool,
          ls_mgmt      TYPE zsap20_file_mgmt.

    LOOP AT entities INTO DATA(ls_ent).

      "Validate title by validation class
      TRY.
          zcl_attach_validation=>check_title(
            iv_title = CONV string( ls_ent-Title )
          ).
        CATCH zcx_attach_validation INTO DATA(lx_val).
          APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-Attach.
          APPEND VALUE #(
            %cid = ls_ent-%cid
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lx_val->get_text( ) )
            %element-Title = if_abap_behv=>mk-on
          ) TO reported-Attach.
          CONTINUE.
      ENDTRY.

      "Generate UUID (FileId)
      CLEAR lv_file_id.
      TRY.
          lv_file_id = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
          APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-Attach.
          APPEND VALUE #(
            %cid = ls_ent-%cid
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Unable to generate FILE_ID (UUID).' )
          ) TO reported-Attach.
          CONTINUE.
      ENDTRY.

      IF lv_file_id IS INITIAL.
        APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-Attach.
        APPEND VALUE #(
          %cid = ls_ent-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'FILE_ID is initial after UUID generation.' )
        ) TO reported-Attach.
        CONTINUE.
      ENDIF.

      "EditLock default false if not provided
      lv_edit_lock = abap_false.
      IF ls_ent-EditLock IS NOT INITIAL.
        lv_edit_lock = ls_ent-EditLock.
      ENDIF.

      "Insert into Z-table
      CLEAR ls_mgmt.
      ls_mgmt-file_id         = lv_file_id.
      ls_mgmt-title           = ls_ent-Title.
      ls_mgmt-current_version = '000'.
      ls_mgmt-edit_lock       = lv_edit_lock.
      ls_mgmt-is_active       = abap_true.
      ls_mgmt-erdat           = sy-datum.
      ls_mgmt-erzet           = sy-uzeit.
      ls_mgmt-ernam           = sy-uname.
      ls_mgmt-aedat           = sy-datum.
      ls_mgmt-aezet           = sy-uzeit.
      ls_mgmt-aenam           = sy-uname.

      "BUFFER instead of INSERT
      APPEND ls_mgmt TO zbp_i_attach_r=>gt_attach_buffer.

      "Audit buffer
      APPEND VALUE zsap20_att_audit(
        uname  = sy-uname
        file_id = lv_file_id
        action = 'CREATE'
        note   = |Created attachment. Title="{ ls_ent-Title }".|
        erdat  = sy-datum
        erzet  = sy-uzeit
        ernam  = sy-uname
      ) TO zbp_i_attach_r=>gt_audit_buffer.

      "mapped + success message
      APPEND VALUE #(
        %cid  = ls_ent-%cid
        FileId = lv_file_id
      ) TO mapped-Attach.

      APPEND VALUE #(
        %cid = ls_ent-%cid
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Attachment created. FileId={ lv_file_id }.| )
      ) TO reported-Attach.

    ENDLOOP.

  ENDMETHOD.

  "Update Title, rollbackversion - CHương
  METHOD update.
    DATA: lv_title_db TYPE zsap20_file_mgmt-title,
          lv_ver_db   TYPE zsap20_file_mgmt-current_version,
          lv_active   TYPE zsap20_file_mgmt-is_active.

    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE title,
                    current_version,
                    is_active
      FROM zsap20_file_mgmt INTO (  @lv_title_db, @lv_ver_db, @lv_active )
      WHERE file_id = @ls_entity-FileId.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF can_update_attach( ls_entity-FileId ) <> abap_true.
        APPEND VALUE #( %tky = ls_entity-%tky ) TO failed-attach.
        APPEND VALUE #(
          %tky = ls_entity-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'You do not have permission to update this attachment.' )
        ) TO reported-attach.
        CONTINUE.
      ENDIF.

*      validation active state
      TRY.
          zcl_attach_validation=>check_active_state( lv_active ).
        CATCH zcx_attach_validation INTO DATA(lx_state).
          APPEND VALUE #( %tky = ls_entity-%tky ) TO failed-attach.
          APPEND VALUE #( %tky = ls_entity-%tky
                          %msg = new_message_with_text(
                                  severity = if_abap_behv_message=>severity-error
                                  text     = lx_state->get_text(  ) )
                        ) TO reported-attach.
          CONTINUE.
      ENDTRY.

*        update title
      IF ls_entity-Title IS NOT INITIAL AND ls_entity-Title  <>  lv_title_db.
        TRY.
            zcl_attach_validation=>check_title(
            CONV string( ls_entity-Title ) ).
          CATCH zcx_attach_validation INTO DATA(lx_title).
            APPEND VALUE #( %tky = ls_entity-%tky ) TO failed-attach.
            APPEND VALUE #(
                  %tky = ls_entity-%tky
                  %msg = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = lx_title->get_text(  ) )
                  %element-Title = if_abap_behv=>mk-on
                  ) TO reported-attach.
            CONTINUE.
        ENDTRY.

        UPDATE zsap20_file_mgmt
        SET title = @ls_entity-Title,
            aedat = @sy-datum,
            aezet = @sy-uzeit,
            aenam = @sy-uname
        WHERE file_id = @ls_entity-FileId.

*        Audit
        APPEND VALUE zsap20_att_audit(
        uname  = sy-uname
        file_id = ls_entity-FileId
        action = 'UPDATE_TITLE'
        note = |Title changed from "{ lv_title_db }" to "{ ls_entity-Title }"|
        erdat = sy-datum
        erzet = sy-uzeit
        ernam = sy-uname
         ) TO zbp_i_attach_r=>gt_audit_buffer.
      ENDIF.

*         Rollback version
      IF ls_entity-CurrentVersion IS NOT INITIAL
      AND CONV i( ls_entity-CurrentVersion ) < CONV i( lv_ver_db ).

        TRY.
            zcl_attach_validation=>check_rollback_target( iv_target_version = CONV string( ls_entity-CurrentVersion ) ).
          CATCH zcx_attach_validation INTO DATA(lx_roll).
            APPEND VALUE #( %tky = ls_entity-%tky ) TO failed-attach.
            APPEND VALUE #(
                   %tky = ls_entity-%tky
                   %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = lx_roll->get_text( ) )
                   %element-CurrentVersion = if_abap_behv=>mk-on
            ) TO reported-attach.
            CONTINUE.
        ENDTRY.

        UPDATE zsap20_file_mgmt
        SET current_version = @ls_entity-CurrentVersion,
        aedat = @sy-datum,
        aezet = @sy-uzeit,
        aenam = @sy-uname
        WHERE file_id = @ls_entity-FileId.

        APPEND VALUE zsap20_att_audit(
        uname = sy-uname
        file_id = ls_entity-FileId
        action = 'ROLLBACK_VERSION'
        note = |Rollback version from { lv_ver_db } to { ls_entity-CurrentVersion }|
        erdat = sy-datum
        erzet = sy-uzeit
        ernam = sy-uname
        ) TO zbp_i_attach_r=>gt_audit_buffer.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  " Xóa mềm - Chương
  METHOD delete.
    DATA: lv_active TYPE zsap20_file_mgmt-is_active,
          lv_curr   TYPE zsap20_file_mgmt-current_version.
    LOOP AT keys INTO DATA(ls_key).

      SELECT SINGLE is_active,
                    current_version
                    FROM zsap20_file_mgmt INTO ( @lv_active, @lv_curr )
                    WHERE file_id = @ls_key-FileId.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF can_delete_attach( ls_key-FileId ) <> abap_true.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attach.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only owner or ADMIN can delete this attachment.' )
        ) TO reported-attach.
        CONTINUE.
      ENDIF.

      TRY.
          zcl_attach_validation=>check_delete_rules(
            iv_is_active       = lv_active
            iv_current_version = CONV string( lv_curr ) ).
        CATCH zcx_attach_validation INTO DATA(lx_del).

          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attach.
          APPEND VALUE #( %tky = ls_key-%tky
                          %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = lx_del->get_text( ) )
                        ) TO reported-attach.
          CONTINUE.
      ENDTRY.

      UPDATE zsap20_file_mgmt
      SET is_active = @abap_false,
      aedat = @sy-datum,
      aezet = @sy-uzeit,
      aenam = @sy-uname
      WHERE file_id = @ls_key-FileId AND is_active = @abap_true.
      IF sy-subrc = 0.
        APPEND VALUE zsap20_att_audit(
        uname = sy-uname
        file_id = ls_key-FileId
        action = 'DELETE'
        note = |Soft delete attachment { ls_key-FileId }|
        erdat = sy-datum
        erzet = sy-uzeit
        ernam = sy-uname
        ) TO zbp_i_attach_r=>gt_audit_buffer.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "Đọc Attachment - Chương
  METHOD read.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    IF is_admin( ) = abap_true.

      SELECT file_id AS FileId,
             title AS Title,
             current_version AS CurrentVersion,
             is_active AS IsActive,
             erdat AS Erdat,
             erzet AS Erzet,
             ernam AS Ernam,
             aedat AS Aedat,
             aezet AS Aezet,
             aenam AS Aenam,
             edit_lock AS EditLock
        FROM zsap20_file_mgmt
        INTO CORRESPONDING FIELDS OF TABLE @result
        FOR ALL ENTRIES IN @keys
        WHERE file_id = @keys-FileId.

    ELSE.

      SELECT file_id AS FileId,
             title AS Title,
             current_version AS CurrentVersion,
             is_active AS IsActive,
             erdat AS Erdat,
             erzet AS Erzet,
             ernam AS Ernam,
             aedat AS Aedat,
             aezet AS Aezet,
             aenam AS Aenam,
             edit_lock AS EditLock
        FROM zsap20_file_mgmt
        INTO CORRESPONDING FIELDS OF TABLE @result
        FOR ALL ENTRIES IN @keys
        WHERE file_id = @keys-FileId
          AND is_active = @abap_true.

    ENDIF.

  ENDMETHOD.

  METHOD reactivate.

    LOOP AT keys INTO DATA(ls_key).

      IF is_admin( ) <> abap_true.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attach.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only ADMIN can reactivate attachment.' )
        ) TO reported-attach.
        CONTINUE.
      ENDIF.

      UPDATE zsap20_file_mgmt
        SET is_active = @abap_true,
            aedat     = @sy-datum,
            aezet     = @sy-uzeit,
            aenam     = @sy-uname
        WHERE file_id = @ls_key-FileId.

      IF sy-subrc = 0.
        APPEND VALUE zsap20_att_audit(
          uname   = sy-uname
          file_id = ls_key-FileId
          action  = 'REACTIVATE'
          note    = |Attachment reactivated by { sy-uname }.|
          erdat   = sy-datum
          erzet   = sy-uzeit
          ernam   = sy-uname
        ) TO zbp_i_attach_r=>gt_audit_buffer.

        APPEND VALUE #(
          %tky        = ls_key-%tky
          %param-%tky = ls_key-%tky
        ) TO result.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  "Lock là khi 1 thằng đụng cái file thì những thằng còn lại như nào - Hải
  METHOD lock.
  ENDMETHOD.

  "Đọc phiên bản từ thằng cha. - Hải
  METHOD rba_Versions.

    TYPES: BEGIN OF ty_cur,
             file_id         TYPE zsap20_file_mgmt-file_id,
             current_version TYPE zsap20_file_mgmt-current_version,
           END OF ty_cur.

    DATA: lt_fileid TYPE SORTED TABLE OF zsap20_file_mgmt-file_id
                      WITH UNIQUE KEY table_line,
          lt_cur    TYPE STANDARD TABLE OF ty_cur,
          lt_ver    TYPE STANDARD TABLE OF zsap20_file_ver.

    "Lay file id tu Attach cha
    LOOP AT keys_rba INTO DATA(ls_rba).
      IF ls_rba-FileId IS NOT INITIAL.
        INSERT ls_rba-FileId INTO TABLE lt_fileid.
      ENDIF.
    ENDLOOP.

    IF lt_fileid IS INITIAL.
      RETURN.
    ENDIF.

    "Lay current version cua tung file
    SELECT file_id,
           current_version
      FROM zsap20_file_mgmt
      INTO TABLE @lt_cur
      FOR ALL ENTRIES IN @lt_fileid
      WHERE file_id   = @lt_fileid-table_line
        AND is_active = @abap_true.

    IF lt_cur IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_cur BY file_id.

    "Lay tat ca versions cua file
    SELECT file_id,
           version_no,
           file_name,
           file_extension,
           mime_type,
           file_size,
           file_content,
           erdat,
           erzet,
           ernam
      FROM zsap20_file_ver
      FOR ALL ENTRIES IN @lt_fileid
      WHERE file_id = @lt_fileid-table_line
      INTO CORRESPONDING FIELDS OF TABLE @lt_ver.

    IF lt_ver IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_ver BY file_id version_no.

    "Chi current version moi tra FileContent
    CLEAR result.
    LOOP AT lt_ver INTO DATA(ls_ver).

      READ TABLE lt_cur INTO DATA(ls_cur)
        WITH KEY file_id = ls_ver-file_id
        BINARY SEARCH.

      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).

      <ls_result>-FileId        = ls_ver-file_id.
      <ls_result>-VersionNo     = ls_ver-version_no.
      <ls_result>-FileName      = ls_ver-file_name.
      <ls_result>-FileExtension = ls_ver-file_extension.
      <ls_result>-MimeType      = ls_ver-mime_type.
      <ls_result>-FileSize      = ls_ver-file_size.
      <ls_result>-Erdat         = ls_ver-erdat.
      <ls_result>-Erzet         = ls_ver-erzet.
      <ls_result>-Ernam         = ls_ver-ernam.

      IF sy-subrc = 0 AND ls_ver-version_no = ls_cur-current_version.
        <ls_result>-FileContent = ls_ver-file_content.
      ENDIF.

    ENDLOOP.

    "Build association link Attach -> Versions
    CLEAR association_links.
    LOOP AT keys_rba INTO ls_rba.
      LOOP AT lt_ver INTO ls_ver WHERE file_id = ls_rba-FileId.
        APPEND VALUE #(
          source-%key = VALUE #( FileId = ls_rba-FileId )
          target-%key = VALUE #(
            FileId    = ls_ver-file_id
            VersionNo = ls_ver-version_no
          )
        ) TO association_links.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.
*"Xóa mềm
*  METHOD deactivate.
*  ENDMETHOD.

  "Link tới cái BO nào đó (Create bản ghi trên Z_I_BO_ATT_LK) - Bình
  METHOD link_to_bo.
    DATA: ls_link_db     TYPE zsap20_bo_att_lk,
          lv_bo_exists   TYPE abap_bool,
          lv_link_exists TYPE abap_bool.

    LOOP AT keys INTO DATA(ls_key).
      " 1. Popup to enter BO id
      DATA(lv_bo_id) = ls_key-%param-bo_id.

      " 2. Basic validation: has id been entered
      IF lv_bo_id IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attach.
        APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text     = 'Please enter Business Object ID')
        ) TO reported-attach.
        CONTINUE.
      ENDIF.

      " 3. Check if entered id exists in DB
      SELECT SINGLE @abap_true
          FROM zsap20_biz_obj
          WHERE bo_id = @lv_bo_id
          INTO @lv_bo_exists.

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attach.
        APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-error
               text     = |Business Object '{ lv_bo_id }' does not exist in the database!| )
        ) TO reported-attach.
        CONTINUE.
      ENDIF.

      TRY.
          zcl_attach_validation=>check_attachment_has_version(
            iv_file_id = ls_key-FileId
          ).
        CATCH zcx_attach_validation INTO DATA(lx_val).
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attach.
          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lx_val->get_text( ) )
          ) TO reported-attach.
          CONTINUE.
      ENDTRY.

      " 4. Check if this file already been prev linked to this bo -> if YES so INSERT -> dumpppp
      SELECT SINGLE @abap_true
          FROM zsap20_bo_att_lk
          WHERE file_id = @ls_key-FileId
              AND bo_id = @lv_bo_id
          INTO @lv_link_exists.

      IF sy-subrc = 0.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-attach.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-warning
                   text     = |This file already been previously linked to Business Object: '{ lv_bo_id }'| )
        ) TO reported-attach.
        CONTINUE.
      ENDIF.

      " 5. Shipping data to Buffer
      CLEAR ls_link_db.
      ls_link_db-file_id = ls_key-FileId.
      ls_link_db-bo_id   = lv_bo_id.
      ls_link_db-erdat   = sy-datum.
      ls_link_db-erzet   = sy-uzeit.
      ls_link_db-ernam   = sy-uname.

      APPEND ls_link_db TO zbp_i_attach_r=>gt_link_buffer.

      " 6. Audit log
      APPEND VALUE zsap20_att_audit(
        uname   = sy-uname
        file_id = ls_key-FileId
        action  = 'LINK_TO_BO'
        note    = |Linked file to Business Object: { lv_bo_id }|
        erdat   = sy-datum
        erzet   = sy-uzeit
        ernam   = sy-uname
      ) TO zbp_i_attach_r=>gt_audit_buffer.

      " 7. Return result to FIori
      APPEND VALUE #( %tky = ls_key-%tky
                      %param-%tky = ls_key-%tky ) TO result.

      APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-success
                   text     = |Linked to Business Object '{ lv_bo_id }' successfully!| )
      ) TO reported-attach.

    ENDLOOP.
  ENDMETHOD.
*"
*  METHOD rollback_version.
*  ENDMETHOD.

*  METHOD upload_new_version.
*  ENDMETHOD.
*
*  METHOD view_version.
*  ENDMETHOD.
  METHOD rba_CurrentVersion.

    TYPES: BEGIN OF ty_cur,
             file_id         TYPE zsap20_file_mgmt-file_id,
             current_version TYPE zsap20_file_mgmt-current_version,
           END OF ty_cur.

    DATA: lt_fileid TYPE SORTED TABLE OF zsap20_file_mgmt-file_id
                      WITH UNIQUE KEY table_line,
          lt_cur    TYPE STANDARD TABLE OF ty_cur,
          lt_ver    TYPE STANDARD TABLE OF zsap20_file_ver.

    LOOP AT keys_rba INTO DATA(ls_rba).
      IF ls_rba-FileId IS NOT INITIAL.
        INSERT ls_rba-FileId INTO TABLE lt_fileid.
      ENDIF.
    ENDLOOP.

    IF lt_fileid IS INITIAL.
      RETURN.
    ENDIF.

    SELECT file_id,
           current_version
      FROM zsap20_file_mgmt
      FOR ALL ENTRIES IN @lt_fileid
      WHERE file_id   = @lt_fileid-table_line
        AND is_active = @abap_true
      INTO TABLE @lt_cur.

    IF lt_cur IS INITIAL.
      RETURN.
    ENDIF.

    SELECT file_id,
           version_no,
           file_name,
           file_extension,
           mime_type,
           file_size,
           file_content,
           erdat,
           erzet,
           ernam
      FROM zsap20_file_ver
      FOR ALL ENTRIES IN @lt_cur
      WHERE file_id    = @lt_cur-file_id
        AND version_no = @lt_cur-current_version
      INTO CORRESPONDING FIELDS OF TABLE @lt_ver.

    IF lt_ver IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_ver BY file_id version_no.

    result = VALUE #(
      FOR v IN lt_ver
      (
        FileId        = v-file_id
        VersionNo     = v-version_no
        FileName      = v-file_name
        FileExtension = v-file_extension
        MimeType      = v-mime_type
        FileSize      = v-file_size
        FileContent   = v-file_content
        Erdat         = v-erdat
        Erzet         = v-erzet
        Ernam         = v-ernam
      )
    ).

    CLEAR association_links.
    LOOP AT keys_rba INTO ls_rba.
      READ TABLE lt_ver INTO DATA(ls_v)
        WITH KEY file_id = ls_rba-FileId
        BINARY SEARCH.
      IF sy-subrc = 0.
        APPEND VALUE #(
          source-%key = VALUE #( FileId = ls_rba-FileId )
          target-%key = VALUE #( FileId = ls_v-file_id VersionNo = ls_v-version_no )
        ) TO association_links.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD cba_Versions.

    DATA: ls_mgmt     TYPE zsap20_file_mgmt,
          ls_ver_db   TYPE zsap20_file_ver,
          lv_max_ver  TYPE zgsp26sap20_verno,
          lv_next_i   TYPE i,
          lv_next_ver TYPE zgsp26sap20_verno,
          lv_b64      TYPE string,
          lv_xcont    TYPE xstring.

    LOOP AT entities_cba INTO DATA(ls_cba).

      " Get master Attach (BUFFER -> DB)
      CLEAR ls_mgmt.

      "Check buffer first
      READ TABLE zbp_i_attach_r=>gt_attach_buffer
        INTO ls_mgmt
        WITH KEY file_id = ls_cba-FileId.

      IF sy-subrc <> 0.

        "Check DB
        SELECT SINGLE *
          FROM zsap20_file_mgmt
          INTO @ls_mgmt
          WHERE file_id   = @ls_cba-FileId
            AND is_active = @abap_true.

      ENDIF.

      " Validate master exists
      IF ls_mgmt-file_id IS INITIAL.

        APPEND VALUE #( %tky = ls_cba-%tky ) TO failed-versions.

        APPEND VALUE #(
          %tky = ls_cba-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Attachment not found.' )
        ) TO reported-versions.

        CONTINUE.

      ENDIF.

      " Edit lock check
      IF ls_mgmt-edit_lock = abap_true
         AND ls_mgmt-ernam <> sy-uname
         AND is_admin( ) <> abap_true.

        APPEND VALUE #( %tky = ls_cba-%tky ) TO failed-versions.

        APPEND VALUE #(
          %tky = ls_cba-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Attachment locked. Only owner { ls_mgmt-ernam } can add versions.| )
        ) TO reported-versions.

        CONTINUE.

      ENDIF.

      " Loop target payload
      LOOP AT ls_cba-%target INTO DATA(ls_v).

        " Validation
        DATA lv_error_text TYPE string.
        DATA lv_max_bytes  TYPE i.
        DATA lv_ext_str    TYPE string.
        DATA lv_mime_str   TYPE string.

        CLEAR: lv_error_text, lv_max_bytes, lv_ext_str, lv_mime_str.

        lv_ext_str  = CONV string( ls_v-FileExtension ).
        lv_mime_str = CONV string( ls_v-MimeType ).

        lv_error_text = zcl_attach_validation=>check_extension(
                          iv_extension = lv_ext_str ).
        IF lv_error_text IS NOT INITIAL.
          APPEND VALUE #( %key = ls_v-%key ) TO failed-versions.
          APPEND VALUE #(
            %key = ls_v-%key
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lv_error_text )
            %element-FileExtension = if_abap_behv=>mk-on
          ) TO reported-versions.
          CONTINUE.
        ENDIF.

        lv_error_text = zcl_attach_validation=>check_mime_type(
                          iv_extension = lv_ext_str
                          iv_mime_type = lv_mime_str ).
        IF lv_error_text IS NOT INITIAL.
          APPEND VALUE #( %key = ls_v-%key ) TO failed-versions.
          APPEND VALUE #(
            %key = ls_v-%key
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lv_error_text )
            %element-MimeType = if_abap_behv=>mk-on
          ) TO reported-versions.
          CONTINUE.
        ENDIF.

        TRY.
            zcl_attach_validation=>check_file_content(
              iv_content = ls_v-FileContent ).
          CATCH zcx_attach_validation INTO DATA(lx_val).
            APPEND VALUE #( %key = ls_v-%key ) TO failed-versions.
            APPEND VALUE #(
              %key = ls_v-%key
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = lx_val->get_text( ) )
            ) TO reported-versions.
            CONTINUE.
        ENDTRY.

        lv_error_text = zcl_attach_validation=>get_file_size_error(
                          iv_extension = lv_ext_str
                          iv_mime_type = lv_mime_str
                          iv_file_size = ls_v-FileSize ).
        IF lv_error_text IS NOT INITIAL.
          APPEND VALUE #( %key = ls_v-%key ) TO failed-versions.
          APPEND VALUE #(
            %key = ls_v-%key
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lv_error_text )
            %element-FileSize = if_abap_behv=>mk-on
          ) TO reported-versions.
          CONTINUE.
        ENDIF.

        " Decode Base64 -> XSTRING
        CLEAR: lv_b64, lv_xcont.
        lv_b64 = CONV string( ls_v-FileContent ).

        TRY.
            lv_xcont = cl_http_utility=>decode_x_base64( lv_b64 ).
          CATCH cx_root INTO DATA(lx_decode).

            APPEND VALUE #( %key = ls_v-%key ) TO failed-versions.

            APPEND VALUE #(
              %key = ls_v-%key
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = 'FileContent is not valid Base64.' )
            ) TO reported-versions.

            CONTINUE.

        ENDTRY.

        " Determine next version
        CLEAR lv_max_ver.

        SELECT SINGLE MAX( version_no )
          FROM zsap20_file_ver
          INTO @lv_max_ver
          WHERE file_id = @ls_cba-FileId.

        LOOP AT zbp_i_attach_r=>gt_ver_buffer INTO DATA(ls_buf_ver)
          WHERE file_id = ls_cba-FileId.

          IF ls_buf_ver-version_no > lv_max_ver.
            lv_max_ver = ls_buf_ver-version_no.
          ENDIF.

        ENDLOOP.

        IF lv_max_ver IS INITIAL.
          lv_next_i = 1.
        ELSE.
          lv_next_i = lv_max_ver + 1.
        ENDIF.

        IF lv_next_i > 999.

          APPEND VALUE #( %key = ls_v-%key ) TO failed-versions.

          APPEND VALUE #(
            %key = ls_v-%key
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Maximum version limit (999) reached.' )
          ) TO reported-versions.

          CONTINUE.

        ENDIF.

        " Format version number
        lv_next_ver = |{ lv_next_i WIDTH = 3 PAD = '0' }|.

        " Buffer version
        CLEAR ls_ver_db.

        ls_ver_db-file_id          = ls_cba-FileId.
        ls_ver_db-version_no       = lv_next_ver.
        ls_ver_db-file_name        = ls_v-FileName.
        ls_ver_db-file_extension   = ls_v-FileExtension.
        ls_ver_db-mime_type        = ls_v-MimeType.
        ls_ver_db-file_size        = ls_v-FileSize.

        " Giữ field text cũ nếu project vẫn còn dùng
        ls_ver_db-file_content     = ls_v-FileContent.

        ls_ver_db-erdat = sy-datum.
        ls_ver_db-erzet = sy-uzeit.
        ls_ver_db-ernam = sy-uname.

        APPEND ls_ver_db TO zbp_i_attach_r=>gt_ver_buffer.

        "Update current version of attachment
        READ TABLE zbp_i_attach_r=>gt_attach_buffer
          ASSIGNING FIELD-SYMBOL(<ls_attach>)
          WITH KEY file_id = ls_cba-FileId.

        IF sy-subrc = 0.

          <ls_attach>-current_version = lv_next_ver.
          <ls_attach>-aedat = sy-datum.
          <ls_attach>-aezet = sy-uzeit.
          <ls_attach>-aenam = sy-uname.

        ELSE.

          UPDATE zsap20_file_mgmt
            SET current_version = @lv_next_ver,
                aedat           = @sy-datum,
                aezet           = @sy-uzeit,
                aenam           = @sy-uname
            WHERE file_id   = @ls_cba-FileId
              AND is_active = @abap_true.

        ENDIF.

        " Audit buffer
        APPEND VALUE zsap20_att_audit(
          uname   = sy-uname
          file_id = ls_cba-FileId
          action  = 'CREATE_VERSION'
          note    = |Created version { lv_next_ver }.|
          erdat   = sy-datum
          erzet   = sy-uzeit
          ernam   = sy-uname
        ) TO zbp_i_attach_r=>gt_audit_buffer.

        " mapped result
        APPEND VALUE #(
          %cid      = ls_v-%cid
          FileId    = ls_cba-FileId
          VersionNo = lv_next_ver
        ) TO mapped-versions.

        " success message
        APPEND VALUE #(
          %cid = ls_v-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-success
                   text     = |Version { lv_next_ver } uploaded.| )
        ) TO reported-versions.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD deactivate.
  ENDMETHOD.

  "Down - Chương (trả về FileContent của current version, Mime, extension, filename)
  METHOD download_version.
    DATA: ls_db      TYPE zsap20_file_ver,
          lv_version TYPE zsap20_file_ver-version_no.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      lv_version = <ls_key>-%param-version_no.

      SELECT SINGLE
          v~file_id,
          v~version_no,
          v~file_name,
          v~file_extension,
          v~mime_type,
          v~file_size,
          v~file_content,
          v~erdat,
          v~erzet,
          v~ernam
     FROM zsap20_file_mgmt AS m
     INNER JOIN zsap20_file_ver AS v
       ON v~file_id = m~file_id
     INTO CORRESPONDING FIELDS OF @ls_db
     WHERE m~file_id   = @<ls_key>-FileId
       AND m~is_active = @abap_true
       AND v~version_no = @lv_version.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<res>).

      <res>-%tky = <ls_key>-%tky.

      <res>-%param-FileId        = ls_db-file_id.
      <res>-%param-VersionNo     = ls_db-version_no.
      <res>-%param-FileName      = ls_db-file_name.
      <res>-%param-FileExtension = ls_db-file_extension.
      <res>-%param-MimeType      = ls_db-mime_type.
      <res>-%param-FileSize      = ls_db-file_size.
      <res>-%param-FileContent   = ls_db-file_content.
      <res>-%param-Erdat         = ls_db-erdat.
      <res>-%param-Erzet         = ls_db-erzet.
      <res>-%param-Ernam         = ls_db-ernam.

    ENDLOOP.

  ENDMETHOD.

  METHOD rba_Audit.

    DATA: lt_fileid TYPE SORTED TABLE OF zsap20_att_audit-file_id
                    WITH UNIQUE KEY table_line.

    IF keys_rba IS INITIAL.
      RETURN.
    ENDIF.

    "Lay danh sach FileId tu Attach
    LOOP AT keys_rba INTO DATA(ls_rba).
      IF ls_rba-FileId IS NOT INITIAL.
        INSERT ls_rba-FileId INTO TABLE lt_fileid.
      ENDIF.
    ENDLOOP.

    IF lt_fileid IS INITIAL.
      RETURN.
    ENDIF.

    "Doc audit theo FileId
    SELECT
        file_id AS FileId,
        erdat   AS Erdat,
        erzet   AS Erzet,
        uname   AS Uname,
        action  AS Action,
        note    AS Note,
        ernam   AS Ernam
      FROM zsap20_att_audit
      INTO CORRESPONDING FIELDS OF TABLE @result
      FOR ALL ENTRIES IN @lt_fileid
      WHERE file_id = @lt_fileid-table_line.

    IF result IS INITIAL.
      RETURN.
    ENDIF.

    SORT result BY FileId Erdat Erzet.

    "Build association link: Attach -> Audit
    CLEAR association_links.
    LOOP AT keys_rba INTO ls_rba.

      LOOP AT result INTO DATA(ls_audit)
        USING KEY id
        WHERE FileId = ls_rba-FileId.

        APPEND VALUE #(
          source-%key = VALUE #(
            FileId = ls_rba-FileId
          )
          target-%key = VALUE #(
            FileId = ls_audit-FileId
            Erdat  = ls_audit-Erdat
            Erzet  = ls_audit-Erzet
          )
        ) TO association_links.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD rba_Links.

    DATA: lt_link TYPE STANDARD TABLE OF zsap20_bo_att_lk.

    IF keys_rba IS INITIAL.
      RETURN.
    ENDIF.

    SELECT bo_id,
           file_id,
           erdat,
           erzet,
           ernam
      FROM zsap20_bo_att_lk
      INTO CORRESPONDING FIELDS OF TABLE @lt_link
      FOR ALL ENTRIES IN @keys_rba
      WHERE file_id = @keys_rba-FileId.

    IF lt_link IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_link BY file_id bo_id.

    CLEAR result.
    result = VALUE #(
      FOR ls_link IN lt_link
      (
        BoId   = ls_link-bo_id
        FileId = ls_link-file_id
        Erdat  = ls_link-erdat
        Erzet  = ls_link-erzet
        Ernam  = ls_link-ernam
      )
    ).

    CLEAR association_links.
    LOOP AT keys_rba INTO DATA(ls_rba).
      LOOP AT lt_link INTO DATA(ls_link_row) WHERE file_id = ls_rba-FileId.
        APPEND VALUE #(
          source-%key = VALUE #(
            FileId = ls_rba-FileId
          )
          target-%key = VALUE #(
            BoId   = ls_link_row-bo_id
            FileId = ls_link_row-file_id
          )
        ) TO association_links.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Versions DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Versions.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Versions.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Versions.

    METHODS read FOR READ
      IMPORTING keys FOR READ Versions RESULT result.

    METHODS rba_Attachment FOR READ
      IMPORTING keys_rba FOR READ Versions\_Attachment FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_Versions IMPLEMENTATION.

  "Tạo version- Hải
  METHOD create.

    DATA: ls_mgmt     TYPE zsap20_file_mgmt,
          ls_ver_db   TYPE zsap20_file_ver,
          lv_max_ver  TYPE zgsp26sap20_verno,
          lv_next_i   TYPE i,
          lv_next_ver TYPE zgsp26sap20_verno.

    LOOP AT entities INTO DATA(ls_ent).

*     1. Get master attachment (BUFFER -> DB)
      CLEAR ls_mgmt.

      READ TABLE zbp_i_attach_r=>gt_attach_buffer
        INTO ls_mgmt
        WITH KEY file_id = ls_ent-FileId.

      IF sy-subrc <> 0.

        SELECT SINGLE *
          FROM zsap20_file_mgmt
          INTO @ls_mgmt
          WHERE file_id   = @ls_ent-FileId
            AND is_active = @abap_true.

      ENDIF.

*     2. Check attachment exists
      IF ls_mgmt-file_id IS INITIAL.

        APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.

        APPEND VALUE #(
          %cid = ls_ent-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Attachment not found.' )
        ) TO reported-versions.

        CONTINUE.

      ENDIF.

*     3. Edit lock check
      IF ls_mgmt-edit_lock = abap_true
         AND ls_mgmt-ernam <> sy-uname.

        APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.

        APPEND VALUE #(
          %cid = ls_ent-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Attachment locked. Only owner { ls_mgmt-ernam } can upload.| )
        ) TO reported-versions.

        CONTINUE.

      ENDIF.

*     4. Validation
*      TRY.
*
*          zcl_attach_validation=>check_extension(
*            CONV string( ls_ent-FileExtension ) ).
*
*          zcl_attach_validation=>check_mime_type(
*            CONV string( ls_ent-MimeType ) ).
*
*          zcl_attach_validation=>check_file_content(
*            ls_ent-FileContent ).
*
*        CATCH zcx_attach_validation INTO DATA(lx_val).
*
*          APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.
*
*          APPEND VALUE #(
*            %cid = ls_ent-%cid
*            %msg = new_message_with_text(
*                     severity = if_abap_behv_message=>severity-error
*                     text     = lx_val->get_text( ) )
*          ) TO reported-versions.
*
*          CONTINUE.
*
*      ENDTRY.
      DATA lv_error_text TYPE string.
      DATA lv_max_bytes  TYPE i.
      DATA lv_ext_str    TYPE string.
      DATA lv_mime_str   TYPE string.

      CLEAR: lv_error_text, lv_max_bytes, lv_ext_str, lv_mime_str.

      lv_ext_str  = CONV string( ls_ent-FileExtension ).
      lv_mime_str = CONV string( ls_ent-MimeType ).

      lv_error_text = zcl_attach_validation=>check_extension(
                        iv_extension = lv_ext_str ).
      IF lv_error_text IS NOT INITIAL.

        APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.

        APPEND VALUE #(
          %cid = ls_ent-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = lv_error_text )
          %element-FileExtension = if_abap_behv=>mk-on
        ) TO reported-versions.

        CONTINUE.
      ENDIF.

      lv_error_text = zcl_attach_validation=>check_mime_type(
                        iv_extension = lv_ext_str
                        iv_mime_type = lv_mime_str ).
      IF lv_error_text IS NOT INITIAL.

        APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.

        APPEND VALUE #(
          %cid = ls_ent-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = lv_error_text )
          %element-MimeType = if_abap_behv=>mk-on
        ) TO reported-versions.

        CONTINUE.
      ENDIF.

      TRY.
          zcl_attach_validation=>check_file_content(
            iv_content = ls_ent-FileContent ).
        CATCH zcx_attach_validation INTO DATA(lx_val).

          APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.

          APPEND VALUE #(
            %cid = ls_ent-%cid
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lx_val->get_text( ) )
          ) TO reported-versions.

          CONTINUE.
      ENDTRY.

      lv_error_text = zcl_attach_validation=>get_file_size_error(
                        iv_extension = lv_ext_str
                        iv_mime_type = lv_mime_str
                        iv_file_size = ls_ent-FileSize ).
      IF lv_error_text IS NOT INITIAL.

        APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.

        APPEND VALUE #(
          %cid = ls_ent-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = lv_error_text )
          %element-FileSize = if_abap_behv=>mk-on
        ) TO reported-versions.

        CONTINUE.
      ENDIF.

*     5. Determine next version
      CLEAR lv_max_ver.

      SELECT SINGLE MAX( version_no )
        FROM zsap20_file_ver
        INTO @lv_max_ver
        WHERE file_id = @ls_ent-FileId.

      LOOP AT zbp_i_attach_r=>gt_ver_buffer INTO DATA(ls_buf)
        WHERE file_id = ls_ent-FileId.

        IF ls_buf-version_no > lv_max_ver.
          lv_max_ver = ls_buf-version_no.
        ENDIF.

      ENDLOOP.

      IF lv_max_ver IS INITIAL.
        lv_next_i = 1.
      ELSE.
        lv_next_i = lv_max_ver + 1.
      ENDIF.

      IF lv_next_i > 999.

        APPEND VALUE #( %cid = ls_ent-%cid ) TO failed-versions.

        APPEND VALUE #(
          %cid = ls_ent-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Version limit exceeded (999).' )
        ) TO reported-versions.

        CONTINUE.

      ENDIF.

*     6. Format version number
      lv_next_ver = |{ lv_next_i WIDTH = 3 PAD = '0' }|.

*     7. Buffer version
      CLEAR ls_ver_db.

      ls_ver_db-file_id        = ls_ent-FileId.
      ls_ver_db-version_no     = lv_next_ver.
      ls_ver_db-file_name      = ls_ent-FileName.
      ls_ver_db-file_extension = ls_ent-FileExtension.
      ls_ver_db-mime_type      = ls_ent-MimeType.
      ls_ver_db-file_size      = ls_ent-FileSize.
      ls_ver_db-file_content   = ls_ent-FileContent.

      ls_ver_db-erdat = sy-datum.
      ls_ver_db-erzet = sy-uzeit.
      ls_ver_db-ernam = sy-uname.

      APPEND ls_ver_db TO zbp_i_attach_r=>gt_ver_buffer.

      "Update current version of attachment
      READ TABLE zbp_i_attach_r=>gt_attach_buffer
        ASSIGNING FIELD-SYMBOL(<ls_attach>)
        WITH KEY file_id = ls_ent-FileId.

      IF sy-subrc = 0.

        "Attach đang nằm trong buffer -> update buffer
        <ls_attach>-current_version = lv_next_ver.
        <ls_attach>-aedat = sy-datum.
        <ls_attach>-aezet = sy-uzeit.
        <ls_attach>-aenam = sy-uname.

      ELSE.

        "Attach nằm trong DB -> update DB luôn
        UPDATE zsap20_file_mgmt
          SET current_version = @lv_next_ver,
              aedat           = @sy-datum,
              aezet           = @sy-uzeit,
              aenam           = @sy-uname
          WHERE file_id = @ls_ent-FileId
            AND is_active = @abap_true.

      ENDIF.

*     8. Audit buffer
      APPEND VALUE zsap20_att_audit(

        uname   = sy-uname
        file_id = ls_ent-FileId
        action  = 'CREATE_VERSION'
        note    = |Created version { lv_next_ver }.|

        erdat   = sy-datum
        erzet   = sy-uzeit
        ernam   = sy-uname

      ) TO zbp_i_attach_r=>gt_audit_buffer.

*     9. mapped
      APPEND VALUE #(
        %cid       = ls_ent-%cid
        FileId     = ls_ent-FileId
        VersionNo  = lv_next_ver
      ) TO mapped-versions.

*     10. success message
      APPEND VALUE #(
        %cid = ls_ent-%cid
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Version { lv_next_ver } uploaded.| )
      ) TO reported-versions.

    ENDLOOP.

  ENDMETHOD.
  "Hiện tại k có update
  METHOD update.
  ENDMETHOD.
  "Hiện tại k cho xóa version nên không code ở đây.
  METHOD delete.
  ENDMETHOD.

  "Read version thông qua thằng cha - CHương
  METHOD read.

    TYPES: BEGIN OF ty_cur,
             file_id         TYPE zsap20_file_mgmt-file_id,
             current_version TYPE zsap20_file_mgmt-current_version,
           END OF ty_cur.

    DATA: lt_ver TYPE STANDARD TABLE OF zsap20_file_ver,
          lt_cur TYPE STANDARD TABLE OF ty_cur.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    "Lay du lieu version
    SELECT file_id,
           version_no,
           file_name,
           file_extension,
           mime_type,
           file_size,
           file_content,
           erdat,
           erzet,
           ernam
      FROM zsap20_file_ver
      FOR ALL ENTRIES IN @keys
      WHERE file_id    = @keys-FileId
        AND version_no = @keys-VersionNo
      INTO CORRESPONDING FIELDS OF TABLE @lt_ver.

    IF lt_ver IS INITIAL.
      RETURN.
    ENDIF.

    "Lay current version cua attachment
    SELECT file_id,
           current_version
      FROM zsap20_file_mgmt
      FOR ALL ENTRIES IN @lt_ver
      WHERE file_id = @lt_ver-file_id
        AND is_active = @abap_true
      INTO TABLE @lt_cur.

    SORT lt_cur BY file_id.
    SORT lt_ver BY file_id version_no.

    CLEAR result.
    LOOP AT lt_ver INTO DATA(ls_ver).

      READ TABLE lt_cur INTO DATA(ls_cur)
        WITH KEY file_id = ls_ver-file_id
        BINARY SEARCH.

      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).

      <ls_result>-FileId        = ls_ver-file_id.
      <ls_result>-VersionNo     = ls_ver-version_no.
      <ls_result>-FileName      = ls_ver-file_name.
      <ls_result>-FileExtension = ls_ver-file_extension.
      <ls_result>-MimeType      = ls_ver-mime_type.
      <ls_result>-FileSize      = ls_ver-file_size.
      <ls_result>-Erdat         = ls_ver-erdat.
      <ls_result>-Erzet         = ls_ver-erzet.
      <ls_result>-Ernam         = ls_ver-ernam.

      IF sy-subrc = 0 AND ls_ver-version_no = ls_cur-current_version.
        <ls_result>-FileContent = ls_ver-file_content.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  "READ cả thằng cha lẫn thằng con - Chương
  METHOD rba_Attachment.
    TYPES: BEGIN OF ty_attach,
             file_id         TYPE zsap20_file_mgmt-file_id,
             title           TYPE zsap20_file_mgmt-title,
             current_version TYPE zsap20_file_mgmt-current_version,
             is_active       TYPE zsap20_file_mgmt-is_active,
             erdat           TYPE zsap20_file_mgmt-erdat,
             erzet           TYPE zsap20_file_mgmt-erzet,
             ernam           TYPE zsap20_file_mgmt-ernam,
             aedat           TYPE zsap20_file_mgmt-aedat,
             aezet           TYPE zsap20_file_mgmt-aezet,
             aenam           TYPE zsap20_file_mgmt-aenam,
             edit_lock       TYPE zsap20_file_mgmt-edit_lock,
           END OF ty_attach.

    DATA: lt_fileid TYPE SORTED TABLE OF zsap20_file_mgmt-file_id
                    WITH UNIQUE KEY table_line,
          lt_attach TYPE STANDARD TABLE OF ty_attach.

    "Lay danh sach fileid tu thang con versions
    LOOP AT keys_rba INTO DATA(ls_rba).
      IF ls_rba-FileId IS NOT INITIAL.
        INSERT ls_rba-FileId INTO TABLE lt_fileid.
      ENDIF.
    ENDLOOP.

    IF lt_fileid IS INITIAL.
      RETURN.
    ENDIF.

    "Doc du lieu cua attachment cha
    SELECT
         file_id,
         title,
         current_version,
         is_active,
         erdat,
         erzet,
         ernam,
         aedat,
         aezet,
         aenam,
         edit_lock
 FROM zsap20_file_mgmt
 INTO TABLE @lt_attach FOR ALL ENTRIES IN @lt_fileid
 WHERE file_id      = @lt_fileid-table_line
 AND   is_active    = @abap_true.

    IF lt_attach IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_attach BY file_id.

    "Fill result
    CLEAR result.
    result = VALUE #(
      FOR a IN lt_attach
      (
       FileId         = a-file_id
        Title          = a-title
        CurrentVersion = a-current_version
        IsActive       = a-is_active
        Erdat          = a-erdat
        Erzet          = a-erzet
        Ernam          = a-ernam
        Aedat          = a-aedat
        Aezet          = a-aezet
        Aenam          = a-aenam
        EditLock       = a-edit_lock
      )
    ).

    "association link: child Versions -> parent Attachment
    CLEAR association_links.
    LOOP AT keys_rba INTO ls_rba.
      READ TABLE lt_attach INTO DATA(ls_attach)
     WITH KEY file_id = ls_rba-FileId
     BINARY SEARCH.
      IF sy-subrc = 0.
        APPEND VALUE #(
          source-%key = VALUE #(
            FileId    = ls_rba-FileId
            VersionNo = ls_rba-VersionNo
          )
          target-%key = VALUE #(
            FileId = ls_attach-file_id
          )
        ) TO association_links.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_audit DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS rba_Attachment FOR READ
      IMPORTING keys_rba FOR READ Audit\_Attachment FULL result_requested RESULT result LINK association_links.
    METHODS read FOR READ
      IMPORTING keys FOR READ Audit RESULT result.

ENDCLASS.

CLASS lhc_audit IMPLEMENTATION.

  METHOD rba_Attachment.

    TYPES: BEGIN OF ty_attach,
             file_id         TYPE zsap20_file_mgmt-file_id,
             title           TYPE zsap20_file_mgmt-title,
             current_version TYPE zsap20_file_mgmt-current_version,
             is_active       TYPE zsap20_file_mgmt-is_active,
             erdat           TYPE zsap20_file_mgmt-erdat,
             erzet           TYPE zsap20_file_mgmt-erzet,
             ernam           TYPE zsap20_file_mgmt-ernam,
             aedat           TYPE zsap20_file_mgmt-aedat,
             aezet           TYPE zsap20_file_mgmt-aezet,
             aenam           TYPE zsap20_file_mgmt-aenam,
             edit_lock       TYPE zsap20_file_mgmt-edit_lock,
           END OF ty_attach.

    DATA: lt_fileid TYPE SORTED TABLE OF zsap20_file_mgmt-file_id
                    WITH UNIQUE KEY table_line,
          lt_attach TYPE STANDARD TABLE OF ty_attach.

    IF keys_rba IS INITIAL.
      RETURN.
    ENDIF.

    "Lay danh sach FileId tu Audit
    LOOP AT keys_rba INTO DATA(ls_rba).
      IF ls_rba-FileId IS NOT INITIAL.
        INSERT ls_rba-FileId INTO TABLE lt_fileid.
      ENDIF.
    ENDLOOP.

    IF lt_fileid IS INITIAL.
      RETURN.
    ENDIF.

    "Doc Attachment cha
    SELECT
        file_id,
        title,
        current_version,
        is_active,
        erdat,
        erzet,
        ernam,
        aedat,
        aezet,
        aenam,
        edit_lock
      FROM zsap20_file_mgmt
      INTO TABLE @lt_attach
      FOR ALL ENTRIES IN @lt_fileid
      WHERE file_id   = @lt_fileid-table_line
        AND is_active = @abap_true.

    IF lt_attach IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_attach BY file_id.

    "Fill result
    CLEAR result.
    result = VALUE #(
      FOR a IN lt_attach
      (
        FileId         = a-file_id
        Title          = a-title
        CurrentVersion = a-current_version
        IsActive       = a-is_active
        Erdat          = a-erdat
        Erzet          = a-erzet
        Ernam          = a-ernam
        Aedat          = a-aedat
        Aezet          = a-aezet
        Aenam          = a-aenam
        EditLock       = a-edit_lock
      )
    ).

    "Build association link: Audit -> Attachment
    CLEAR association_links.
    LOOP AT keys_rba INTO ls_rba.

      READ TABLE lt_attach INTO DATA(ls_attach)
        WITH KEY file_id = ls_rba-FileId
        BINARY SEARCH.

      IF sy-subrc = 0.
        APPEND VALUE #(
          source-%key = VALUE #(
            FileId = ls_rba-FileId
            Erdat  = ls_rba-Erdat
            Erzet  = ls_rba-Erzet
          )
          target-%key = VALUE #(
            FileId = ls_attach-file_id
          )
        ) TO association_links.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD read.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    SELECT
        file_id AS FileId,
        erdat   AS Erdat,
        erzet   AS Erzet,
        uname   AS Uname,
        action  AS Action,
        note    AS Note,
        ernam   AS Ernam
      FROM zsap20_att_audit
      INTO CORRESPONDING FIELDS OF TABLE @result
      FOR ALL ENTRIES IN @keys
      WHERE file_id = @keys-FileId
        AND erdat   = @keys-Erdat
        AND erzet   = @keys-Erzet.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z_I_ATTACH_R DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z_I_ATTACH_R IMPLEMENTATION.

  "Hải
  METHOD finalize.

    TYPES: BEGIN OF ty_audit_key,
             file_id TYPE zsap20_att_audit-file_id,
             erdat   TYPE zsap20_att_audit-erdat,
             erzet   TYPE zsap20_att_audit-erzet,
           END OF ty_audit_key.

    DATA: lt_used_keys TYPE HASHED TABLE OF ty_audit_key
                         WITH UNIQUE KEY file_id erdat erzet,
          ls_key       TYPE ty_audit_key,
          lv_secs      TYPE i,
          lv_hour      TYPE i,
          lv_min       TYPE i,
          lv_sec       TYPE i.

    LOOP AT zbp_i_attach_r=>gt_audit_buffer ASSIGNING FIELD-SYMBOL(<ls_audit>).

      IF <ls_audit>-file_id IS INITIAL.
        CONTINUE.
      ENDIF.

      IF <ls_audit>-uname IS INITIAL.
        <ls_audit>-uname = sy-uname.
      ENDIF.

      IF <ls_audit>-ernam IS INITIAL.
        <ls_audit>-ernam = sy-uname.
      ENDIF.

      IF <ls_audit>-erdat IS INITIAL.
        <ls_audit>-erdat = sy-datum.
      ENDIF.

      IF <ls_audit>-erzet IS INITIAL.
        <ls_audit>-erzet = sy-uzeit.
      ENDIF.

      ls_key-file_id = <ls_audit>-file_id.
      ls_key-erdat   = <ls_audit>-erdat.
      ls_key-erzet   = <ls_audit>-erzet.

      WHILE line_exists(
        lt_used_keys[
          file_id = ls_key-file_id
          erdat   = ls_key-erdat
          erzet   = ls_key-erzet
        ] ).

        lv_hour = CONV i( ls_key-erzet+0(2) ).
        lv_min  = CONV i( ls_key-erzet+2(2) ).
        lv_sec  = CONV i( ls_key-erzet+4(2) ).

        lv_secs = lv_hour * 3600 + lv_min * 60 + lv_sec + 1.

        IF lv_secs >= 86400.
          lv_secs = lv_secs - 86400.
          ls_key-erdat = ls_key-erdat + 1.
        ENDIF.

        lv_hour = lv_secs DIV 3600.
        lv_min  = ( lv_secs MOD 3600 ) DIV 60.
        lv_sec  = lv_secs MOD 60.

        ls_key-erzet = |{ lv_hour WIDTH = 2 PAD = '0' }{ lv_min WIDTH = 2 PAD = '0' }{ lv_sec WIDTH = 2 PAD = '0' }|.

      ENDWHILE.

      <ls_audit>-erdat = ls_key-erdat.
      <ls_audit>-erzet = ls_key-erzet.

      INSERT ls_key INTO TABLE lt_used_keys.

    ENDLOOP.

  ENDMETHOD.

  "Verify trước lưu - Hải
  METHOD check_before_save.

*    LOOP AT zbp_i_attach_r=>gt_attach_buffer INTO DATA(ls_attach).
*
*      READ TABLE zbp_i_attach_r=>gt_ver_buffer
*        WITH KEY file_id = ls_attach-file_id
*        TRANSPORTING NO FIELDS.
*
*      IF sy-subrc <> 0.
*
*        RAISE EXCEPTION TYPE zcx_attach_validation
*          EXPORTING
*            iv_text = 'Attachment must have at least one version'.
*
*      ENDIF.
*
*    ENDLOOP.

  ENDMETHOD.

  "Save được rồi thì làm gì (Ghi audit) - Chương (Bình bổ sung phần link từ buffer -> db)
  METHOD save.
    " Code cũ của Chương
    " LOOP AT zbp_i_attach_r=>gt_audit_buffer INTO DATA(ls_audit).
    "  INSERT zsap20_att_audit FROM ls_audit.
    "ENDLOOP.

    "CLEAR zbp_i_attach_r=>gt_audit_buffer.
    "Insert Attach
    IF zbp_i_attach_r=>gt_attach_buffer IS NOT INITIAL.
      INSERT zsap20_file_mgmt
      FROM TABLE zbp_i_attach_r=>gt_attach_buffer.
    ENDIF.

    "Insert Version
    IF zbp_i_attach_r=>gt_ver_buffer IS NOT INITIAL.
      INSERT zsap20_file_ver
      FROM TABLE zbp_i_attach_r=>gt_ver_buffer.
    ENDIF.
    " Code bình sửa, để tạm dùng thôi còn chương muốn sửa như nào cứ sửa nhé
    IF zbp_i_attach_r=>gt_audit_buffer IS NOT INITIAL.
      INSERT zsap20_att_audit
      FROM TABLE zbp_i_attach_r=>gt_audit_buffer ACCEPTING DUPLICATE KEYS.
    ENDIF.

    IF zbp_i_attach_r=>gt_link_buffer IS NOT INITIAL.
      INSERT zsap20_bo_att_lk
      FROM TABLE @zbp_i_attach_r=>gt_link_buffer ACCEPTING DUPLICATE KEYS.
    ENDIF.
  ENDMETHOD.
  "Sau sử dụng đối tượng gt,.. clear nó đi - Bình
  METHOD cleanup.

    CLEAR zbp_i_attach_r=>gt_attach_buffer.
    CLEAR zbp_i_attach_r=>gt_ver_buffer.
    CLEAR zbp_i_attach_r=>gt_audit_buffer.
    CLEAR zbp_i_attach_r=>gt_link_buffer.

  ENDMETHOD.

  "BÌnh
  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
