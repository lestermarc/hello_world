--------------------------------------------------------
--  DDL for Procedure RPT_HRM_LPP_ANNUAL_DECLARATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_LPP_ANNUAL_DECLARATION" (
   arefcursor       in out   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       NUMBER,
   procuser_lanid   in       pcs.pc_lang.lanid%type

)
IS
/**
 Description - used for the report HRM_ANNUAL_DECLARATION


 @parameter_0: hrm_elm_transmission_id (1: full, 2: personal)

 @author VHA 24.06.2011
 @public
*/
vpc_lang_id   pcs.pc_lang.pc_lang_id%type;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR

      SELECT    t.c_elm_transmission_type,
          ELM_VALID_AS_OF effective_date,
          t.elm_year,
          c.lpp_yearly_amount,
          d.c_hrm_lpp_ref_type,
          d.lpp_factor,
          d.lpp_monthly_amount,
          d.lpp_ref_amount,
          p.per_last_name,
          p.per_first_name,
          p.emp_number,
          hrm_elm_recipient_id,
          (SELECT cod_code
              FROM  hrm_employee_const c,
                hrm_control_elements e,
                hrm_code_table t
              WHERE c.hrm_employee_id = p.hrm_person_id
                AND emc_active = 1
                AND c.hrm_code_table_id = t.hrm_code_table_id(+)
                AND sysdate BETWEEN emc_value_from
                AND emc_value_to
                AND e.hrm_control_elements_id = c.hrm_constants_id
                AND coe_box = 'CODE'
                AND RE.HRM_CONTROL_LIST_ID = e.HRM_CONTROL_LIST_ID) coe_code,
          (SELECT cod_code
              FROM  hrm_employee_const c,
                hrm_control_elements e,
                hrm_code_table t
              WHERE c.hrm_employee_id = p.hrm_person_id
                AND emc_active = 1
                AND c.hrm_code_table_id = t.hrm_code_table_id(+)
                AND sysdate BETWEEN emc_value_from
                AND emc_value_to
                AND e.hrm_control_elements_id = c.hrm_constants_id
                AND coe_box = 'CODE2'
                AND RE.HRM_CONTROL_LIST_ID = e.HRM_CONTROL_LIST_ID) coe_code2,
          p.per_activity_rate,
          greatest(io.ino_in,trunc(trunc(elm_valid_as_of,'year')-1,'year')) ino_in,
          least(nvl(io.ino_out, elm_valid_as_of), trunc(elm_valid_as_of,'year')-1) ino_out,
          de.erd_descr,
          r.elr_root_code,
          i.ins_name,
          i.ins_contract_nr,
          c.lpp_valid_on
      FROM  hrm_lpp_emp_calc c,
          hrm_lpp_emp_calc_detail d,
          hrm_elements_root r,
          hrm_elements_root_descr de,
          hrm_person p,
          hrm_in_out io,
          hrm_elm_recipient re,
          hrm_insurance i,
          hrm_elm_transmission t
      WHERE   d.hrm_elements_root_id = r.hrm_elements_root_id
          AND r.hrm_elements_root_id = de.hrm_elements_root_id
          AND de.pc_lang_id = vpc_lang_id
          AND p.hrm_person_id = c.hrm_person_id
          AND c.hrm_lpp_emp_calc_id = d.hrm_lpp_emp_calc_id
          AND d.hrm_in_out_id = io.hrm_in_out_id (+)
          AND p.hrm_person_id = c.hrm_person_id
          AND c.hrm_elm_transmission_id = re.hrm_elm_transmission_id
          AND re.hrm_insurance_id(+) = i.hrm_insurance_id
          AND c.hrm_elm_transmission_id = t.hrm_elm_transmission_id
          AND c.hrm_elm_transmission_id = parameter_0
          AND elm_valid_as_of is not null
          AND c_hrm_insurance = '07'
          AND elm_selected = 1
          AND EXISTS(SELECT 1
              FROM hrm_employee_const c,
                   hrm_control_elements e
              WHERE hrm_employee_id =  p.hrm_person_id
                AND hrm_constants_id = hrm_control_elements_id
                AND re.hrm_control_list_id = e.hrm_control_list_id
                AND coe_box = 'CODE')
      ORDER BY
          p.per_last_name,
          p.per_first_name;


END rpt_hrm_lpp_annual_declaration;
