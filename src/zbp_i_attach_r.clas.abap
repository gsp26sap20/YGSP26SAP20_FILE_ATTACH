CLASS zbp_i_attach_r DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF z_i_attach_r.

  PUBLIC SECTION.
    CLASS-DATA:
      "Buffer attach
      gt_attach_buffer        TYPE STANDARD TABLE OF zsap20_file_mgmt,
      gt_attach_update_buffer TYPE STANDARD TABLE OF zsap20_file_mgmt,
      "Buffer version
      gt_ver_buffer           TYPE STANDARD TABLE OF zsap20_file_ver,
      gt_audit_buffer         TYPE STANDARD TABLE OF zsap20_att_audit,
      gt_link_buffer          TYPE STANDARD TABLE OF zsap20_bo_att_lk.

ENDCLASS.



CLASS zbp_i_attach_r IMPLEMENTATION.
ENDCLASS.

