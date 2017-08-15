--------------------------------------------------------
--  DDL for Package Body HRM_IND_PAYSLIP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND_PAYSLIP" 
is

procedure extract_payslip_v11 (vPeriodFrom varchar2, vPeriodTo varchar2)
is

l_clob BLOB;
l_pos NUMBER := 1;
l_amount BINARY_INTEGER := 32760;
--v_lelen NUMBER;
v_raw RAW(32760);
v_x NUMBER;
v_bytelen NUMBER;
v_start NUMBER;

v_output utl_file.file_type;

vFileDir varchar2(2000);
vFileName varchar2(1000);

CpyCode varchar2(20);
vCount integer;

cursor CurPay is
select
h.hrm_person_id hrm_employee_id,
h.hps_pay_num hit_pay_num,
h.hps_pay_period,
to_char(h.hps_pay_period,'YYYYMM') period,
p.per_search_name,
p.per_last_name,
p.per_first_name,
p.emp_number,
p.emp_secondary_key,
dbms_lob.getlength(h.HPS_PAYSLIP) v_len,
h.HPS_PAYSLIP v_blob
from
--hrm_payslip h, hrm_person p, web_user u
hrm_payslip h, hrm_person p
where
h.hrm_person_id=p.hrm_person_id
and to_char(hps_pay_period,'YYYYMM')>=vPeriodFrom
and to_char(hps_pay_period,'YYYYMM')<=vPeriodTo;

BEGIN


vCount := 0;

select PCS.PC_INIT_SESSION.GETCOMPANYOWNER into CpyCode
from dual;

vFileDir := 'D:\PCSITX\Company\'||CpyCode||'\Export\Payslip\';

for RowPay in CurPay
loop

vCount := vCount + 1;

if      CpyCode='C_AGS'     then vFileName := '1'||RowPay.emp_secondary_key||'_'||substr(RowPay.period,1,4)||'_'||substr(RowPay.period,5,2)||'.PDF';
  elsif CpyCode='C_MPSEUR'  then vFileName := RowPay.per_search_name||'_BS '||substr(RowPay.period,5,2)||'.'||substr(RowPay.period,1,4)||'.PDF';
  elsif CpyCode='C_LEMS'
        or CpyCode='C_KBA'  then vFileName := replace(RowPay.per_search_name,' ','-')||'_'||RowPay.period||'_'||to_char(to_number(substr(RowPay.emp_number,2,99)))||'.PDF';
  elsif CpyCode='C_SSG'     then vFileName := replace(RowPay.per_search_name,' ','-')||'_'||RowPay.period||'_'||RowPay.emp_number||'.PDF';
  else                           vFileName := replace(RowPay.per_search_name,' ','-')||'_'||RowPay.period||'_'||RowPay.hit_pay_num||'.PDF';
end if;

-- define output directory
v_output := utl_file.fopen(vFileDir, vFileName,'wb', 32760);

v_x := RowPay.v_len;
v_start := 1;
v_bytelen := 2000;

WHILE v_start < RowPay.v_len AND v_bytelen > 0
      LOOP
         -- Lecture du contenu du BLOB par fragments

         DBMS_LOB.READ (RowPay.v_blob, v_bytelen, v_start, v_raw);
         -- Ecriture partielle du fichier sur le disque

         UTL_FILE.put_raw (v_output, v_raw);
         UTL_FILE.fflush (v_output);
         v_start := v_start + v_bytelen;
         v_x := v_x - v_bytelen;

         IF v_x < 2000
         THEN
            v_bytelen := v_x;
         END IF;
      END LOOP;

      UTL_FILE.fclose (v_output);

-- Fin Curseur Payslip
end loop;


if vCount = 0
then raise_application_error(-20001,'Aucun décompte à  exporter');
end if;

EXCEPTION  -- exception handlers begin
--    WHEN NO_DATA_FOUND THEN
--      dbms_output.put_line('Fin des donnÃ©es');
--      utl_file.fclose(l_output);
   WHEN OTHERS THEN
      utl_file.fclose(v_output);
     RAISE;

end extract_payslip_v11;

end hrm_ind_payslip;
