CLASS zbp_i_biz_obj_r DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF z_i_biz_obj_r.
  PUBLIC SECTION.
    CLASS-DATA:
      gt_bo_create   TYPE STANDARD TABLE OF zsap20_biz_obj,
      gt_bo_update   TYPE STANDARD TABLE OF zsap20_biz_obj,
      gt_bo_delete   TYPE STANDARD TABLE OF zsap20_biz_obj,
      gt_link_buffer TYPE STANDARD TABLE OF zsap20_bo_att_lk,
      gt_link_delete TYPE STANDARD TABLE OF zsap20_bo_att_lk,

      " store ID for update time (aedat, aezet)
      gt_bo_touch    TYPE STANDARD TABLE OF zsap20_biz_obj-bo_id,
      gt_file_touch  TYPE STANDARD TABLE OF zsap20_file_mgmt-file_id.
ENDCLASS.

CLASS zbp_i_biz_obj_r IMPLEMENTATION.
ENDCLASS.
