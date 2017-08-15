--------------------------------------------------------
--  DDL for Package Body IND_EXCEL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_EXCEL" IS

function getVarId (pRootCode varchar2) return number is

retour number;
begin
select f.hrm_elements_id into retour
from hrM_elements_family f,
       hrm_elements_root r
       where f.hrm_elements_root_id = r.hrm_elements_root_id
       and    r.elr_root_code = pRootCode
       and   F.HRM_ELEMENTS_PREFIXES_ID = 'EM';

return retour;

end getVarId;

function getConstId (pRootCode varchar2) return number is

retour number;
begin
select f.hrm_elements_id into retour
from hrM_elements_family f,
       hrm_elements_root r
       where f.hrm_elements_root_id = r.hrm_elements_root_id
       and    r.elr_root_code = pRootCode
       and   F.HRM_ELEMENTS_PREFIXES_ID = 'CONEM';

return retour;

end getConstId;

function getAcsCurId (pVAR_CURRENCY VARCHAR2) return number is
retour number ;

begin

select acs_financial_currency_id into retour
from acs_financial_currency f,
       pcs.pc_curr c
       where f.pc_curr_id = c.pc_curr_id
       and    c.currency = pVAR_CURRENCY ;

return retour;

end  getAcsCurId;

function GetCurrencyId(vCurrency varchar2) return number
-- Retourne l'id de la monnaie comptable
is
 retour acs_financial_currency.acs_financial_currency_id%type;
begin
  -- recherche de l'id de la monnaie de base
  select max(acs_financial_currency_id) into retour
  from acs_financial_currency a,
       pcs.pc_curr b
  where a.pc_curr_id=b.pc_curr_id
        and b.currency=vCurrency;

  return retour;
end GetCurrencyId;

procedure insert_variable (pEMP_NUMBER varchar2,pELR_ROOT_CODE  varchar2,pVAR_CURRENCY  varchar2,pVAR_VALFROM varchar2,pVAR_REMP varchar2,pFOREIGN_VALUE  varchar2,pEMPLOYEE_VALUE  varchar2,pVAR_COMMENT varchar2)
is
BEGIN

 INSERT INTO HRM_EMPLOYEE_ELEMENTS( HRM_EMPLOYEE_ELEMENTS_ID, HRM_EMPLOYEE_ID, HRM_ELEMENTS_ID, acs_financial_currency_id, EMP_VALUE, EMP_FROM, EMP_TO, EMP_VALUE_FROM, EMP_VALUE_TO, EMP_ACTIVE, A_DATECRE, A_IDCRE, EMP_NUM_VALUE, EMP_FOREIGN_VALUE, EMP_TEXT)
 select
     init_id_seq.nextval,
      (select hrm_person_id from hrm_person where emp_number = pEMP_NUMBER),
      ind_excel.getvarId(pELR_ROOT_CODE),
      ind_excel.GetAcsCurId(pVAR_CURRENCY),
      NVL(pEMPLOYEE_VALUE,0) ,
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      1,sysdate,'XLS',
      pEMPLOYEE_VALUE,
      NVL(pFOREIGN_VALUE,0),
      pVAR_COMMENT
    from DUAL;

end insert_variable ;

procedure insert_variable2 (pEMP_NUMBER varchar2,pELR_ROOT_CODE  varchar2,pVAR_CURRENCY  varchar2,pVAR_VALFROM varchar2,pVAR_VALTO varchar2,pVAR_REMP varchar2,pFOREIGN_VALUE  varchar2,pEMPLOYEE_VALUE  varchar2,pVAR_COMMENT varchar2)
is
BEGIN

 INSERT INTO HRM_EMPLOYEE_ELEMENTS( HRM_EMPLOYEE_ELEMENTS_ID, HRM_EMPLOYEE_ID, HRM_ELEMENTS_ID, acs_financial_currency_id, EMP_VALUE, EMP_FROM, EMP_TO, EMP_VALUE_FROM, EMP_VALUE_TO, EMP_ACTIVE, A_DATECRE, A_IDCRE, EMP_NUM_VALUE, EMP_FOREIGN_VALUE, EMP_TEXT)
 select
     init_id_seq.nextval,
      (select hrm_person_id from hrm_person where emp_number = pEMP_NUMBER),
      ind_excel.getvarId(pELR_ROOT_CODE),
      ind_excel.GetAcsCurId(pVAR_CURRENCY),
      NVL(pEMPLOYEE_VALUE,0) ,
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALTO,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALTO,'DD.MM.YYYY'),
      1,sysdate,'XLS',
      pEMPLOYEE_VALUE,
      NVL(pFOREIGN_VALUE,0),
      pVAR_COMMENT
    from DUAL;

end insert_variable2 ;

procedure update_variable (pEmpElemId number, pVAR_REMP varchar2,pFOREIGN_VALUE  varchar2,pEMPLOYEE_VALUE  varchar2,pVAR_COMMENT varchar2,pVAR_CURRENCY varchar2)
is

CurId number;
BEGIN

CurId := GetCurrencyId(pVAR_CURRENCY);

 --Remplacement
 IF pVAR_REMP  = 1 THEN
 UPDATE HRM_EMPLOYEE_ELEMENTS set EMP_VALUE =nvl(pEmployee_value,0) , EMP_NUM_VALUE = nvl(pEmployee_value,0),EMP_FOREIGN_VALUE= pForeign_value,EMP_TEXT=pVAR_COMMENT, ACS_FINANCIAL_CURRENCY_ID = CurId
   WHERE HRM_EMPLOYEE_ELEMENTS_ID = pEmpElemId;
  else
  --Cumul
  UPDATE HRM_EMPLOYEE_ELEMENTS set  EMP_VALUE =EMP_VALUE+nvl(pEmployee_value,0) , EMP_NUM_VALUE =EMP_NUM_VALUE+nvl(pEmployee_value,0),EMP_FOREIGN_VALUE= EMP_FOREIGN_VALUE+pForeign_value,EMP_TEXT=pVAR_COMMENT
   WHERE HRM_EMPLOYEE_ELEMENTS_ID = pEmpElemId;
  END IF;

end update_variable ;

procedure update_constant (pEmpElemId number, pELR_ROOT_CODE  varchar2, pVAR_REMP varchar2,pFOREIGN_VALUE  varchar2,pEMPLOYEE_VALUE varchar2, pVAR_VALFROM varchar2, pVAR_VALTO varchar2,pVAR_COMMENT varchar2,pVAR_CURRENCY varchar2)
is

 CurId number;
 CodeSoumId hrm_code_table.hrm_code_table_id%type;

BEGIN

 -- recherche s'il s'agit d'un code soumission
  select
  max(ct.hrm_code_table_id) into CodeSoumId
  from
  hrm_constants con,
  hrm_code_dic cd,
  hrm_code_table ct
  where
  con.hrm_code_dic_id=cd.hrm_code_dic_id
  and cd.hrm_code_dic_id=ct.hrm_code_dic_id
  and con.hrm_constants_id=ind_excel.getConstId(pELR_ROOT_CODE)
  and con.c_hrm_sal_const_type='2'
  and ct.cod_code=pEMPLOYEE_VALUE;

  CurId := GetCurrencyId(pVAR_CURRENCY);

 --Remplacement
 IF pVAR_REMP  = 1 THEN
   if CodeSoumId is null then
    UPDATE HRM_EMPLOYEE_CONST set EMC_VALUE =nvl(pEmployee_value,0) ,EMC_NUM_VALUE = nvl(pEmployee_value,0),EMC_FOREIGN_VALUE= pForeign_value,EMC_TEXT=pVAR_COMMENT, ACS_FINANCIAL_CURRENCY_ID = CurId, emc_value_from=to_date(pVAR_VALFROM,'DD.MM.YYYY'),  emc_value_to=to_date(pVAR_VALTO,'DD.MM.YYYY')
    WHERE HRM_EMPLOYEE_CONST_ID = pEmpElemId;
   else
    UPDATE HRM_EMPLOYEE_CONST set HRM_CODE_TABLE_ID=CodeSoumId, EMC_TEXT=pVAR_COMMENT, emc_value_from=to_date(pVAR_VALFROM,'DD.MM.YYYY'),  emc_value_to=to_date(pVAR_VALTO,'DD.MM.YYYY')
    WHERE HRM_EMPLOYEE_CONST_ID = pEmpElemId;
   end if;
  --Cumul
  elsif pVAR_REMP  = 2 THEN
   if CodeSoumId is null then
    UPDATE HRM_EMPLOYEE_CONST set  EMC_VALUE =EMC_VALUE+nvl(pEmployee_value,0) , EMC_NUM_VALUE =EMC_NUM_VALUE+nvl(pEmployee_value,0),EMC_FOREIGN_VALUE= EMC_FOREIGN_VALUE+pForeign_value,EMC_TEXT=pVAR_COMMENT, emc_value_from=to_date(pVAR_VALFROM,'DD.MM.YYYY'),  emc_value_to=to_date(pVAR_VALTO,'DD.MM.YYYY')
    WHERE HRM_EMPLOYEE_CONST_ID = pEmpElemId;
   else -- si code soumission, pas d'addition, reprise de l'update 1 remplace
    UPDATE HRM_EMPLOYEE_CONST set HRM_CODE_TABLE_ID=CodeSoumId, EMC_TEXT=pVAR_COMMENT, emc_value_from=to_date(pVAR_VALFROM,'DD.MM.YYYY'),  emc_value_to=to_date(pVAR_VALTO,'DD.MM.YYYY')
    WHERE HRM_EMPLOYEE_CONST_ID = pEmpElemId;
   end if;

  -- désactivation ancien record et insert du nouveau
  elsif pVAR_REMP  = 3 THEN
   UPDATE HRM_EMPLOYEE_CONST set  EMC_ACTIVE=0,EMC_VALUE_TO = to_date(pVAR_VALFROM,'DD.MM.YYYY')-1
   WHERE HRM_EMPLOYEE_CONST_ID = pEmpElemId;

    insert into hrm_employee_const (
    HRM_EMPLOYEE_CONST_ID,
    HRM_EMPLOYEE_ID,
    HRM_CONSTANTS_ID,
    EMC_VALUE,
    EMC_FOREIGN_VALUE,
    EMC_FROM,
    EMC_TO,
    EMC_VALUE_FROM,
    EMC_VALUE_TO,
    EMC_ACTIVE,
    A_DATECRE,
    A_IDCRE,
    EMC_NUM_VALUE,
    HRM_CODE_TABLE_ID,
    ACS_FINANCIAL_CURRENCY_ID)
    select
    init_id_seq.nextval,
    HRM_EMPLOYEE_ID,
    HRM_CONSTANTS_ID,
    decode(CodeSoumId,null,nvl(pEmployee_value,0),null),
    decode(CodeSoumId,null,pForeign_value,null),
    to_date(pVAR_VALFROM,'DD.MM.YYYY'),
    to_date(pVAR_VALTO,'DD.MM.YYYY'),
    to_date(pVAR_VALFROM,'DD.MM.YYYY'),
    to_date(pVAR_VALTO,'DD.MM.YYYY'),
    1,
    sysdate,
    'XLS',
    decode(CodeSoumId,null,nvl(pEmployee_value,0),null),
    CodeSoumId,
    decode(CodeSoumId,null,ACS_FUNCTION.GETCURRENCYID(pVAR_CURRENCY),null)
    from
    hrm_employee_const
    where
    hrm_employee_const_id=pEmpElemId;

    else raise_application_error(-20001, 'Remplace doit être 1,2 ou 3');
  END IF;

end update_constant ;

procedure insert_constant (pEMP_NUMBER varchar2,pELR_ROOT_CODE  varchar2,pVAR_CURRENCY  varchar2,pVAR_VALFROM varchar2,pVAR_VALTO varchar2,pVAR_REMP varchar2,pFOREIGN_VALUE  varchar2,pEMPLOYEE_VALUE  varchar2,pVAR_COMMENT varchar2)
is
 CodeSoumId hrm_code_table.hrm_code_table_id%type;
BEGIN

 -- recherche s'il s'agit d'un code soumission
  select
  max(ct.hrm_code_table_id) into CodeSoumId
  from
  hrm_constants con,
  hrm_code_dic cd,
  hrm_code_table ct
  where
  con.hrm_code_dic_id=cd.hrm_code_dic_id
  and cd.hrm_code_dic_id=ct.hrm_code_dic_id
  and con.hrm_constants_id=ind_excel.getConstId(pELR_ROOT_CODE)
  and con.c_hrm_sal_const_type='2'
  and ct.cod_code=pEMPLOYEE_VALUE;

 INSERT INTO HRM_EMPLOYEE_CONST( HRM_EMPLOYEE_CONST_ID, HRM_EMPLOYEE_ID, HRM_CONSTANTS_ID, acs_financial_currency_id, EMC_VALUE, EMC_FROM, EMC_TO, EMC_VALUE_FROM, EMC_VALUE_TO, EMC_ACTIVE, A_DATECRE, A_IDCRE, EMC_NUM_VALUE, EMC_FOREIGN_VALUE, HRM_CODE_TABLE_ID, EMC_TEXT)
 select
     init_id_seq.nextval,
      (select hrm_person_id from hrm_person where emp_number = pEMP_NUMBER),
      ind_excel.getConstId(pELR_ROOT_CODE),
      decode(CodeSoumId,null,ind_excel.GetAcsCurId(pVAR_CURRENCY),null),
      decode(CodeSoumId,null,NVL(pEMPLOYEE_VALUE,0),null),
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALTO,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALFROM,'DD.MM.YYYY'),
      TO_DATE(pVAR_VALTO,'DD.MM.YYYY'),
      1,sysdate,'XLS',
      decode(CodeSoumId,null,pEMPLOYEE_VALUE,null),
      decode(CodeSoumId,null,NVL(pFOREIGN_VALUE,0),null),
      decode(CodeSoumId,null,null,CodeSoumId),
      pVAR_COMMENT
    from DUAL;

end insert_constant ;


PROCEDURE IND_IMPORT_VARIABLE (
pEMP_NUMBER varchar2,
pELR_ROOT_CODE  varchar2,
pVAR_CURRENCY  varchar2,
pVAR_VALFROM varchar2,
pVAR_REMP varchar2,
pFOREIGN_VALUE  varchar2,
pEMPLOYEE_VALUE  varchar2 DEFAULT '0',
pVAR_COMMENT varchar2 DEFAULT NULL)


is
new_id number;
erreur varchar2(4000);
var_exist number;
vold_currency varchar2(10);
vold_foreign_value number(15,6);
vold_employee_value number(15,6);
NotNDF number;
error_retour varchar2(200);

begin

select nvl(count(*),0) into NotNDF
from hrm_elements_root r,
        hrm_elements_family f
        where r.hrm_elements_root_id = f.hrm_elements_root_id
        and r. DIC_GROUP4_ID = 'NDF'
        and  r.elr_root_code = pELR_ROOT_CODE;

if   NotNDF > 0 then
    error_retour := 'variable de type NDF';
    end if;


select init_id_seq.nextval into new_id from dual;

insert into ind_hrm_var_interface (INTERFACE_ID, USE_NAME,A_DATECRE,EMP_NUMBER, ELR_ROOT_CODE, VAR_CURRENCY, FOREIGN_VALUE, EMPLOYEE_VALUE,VAR_VALFROM, VAR_COMMENT, import_error )
select new_id,USER,sysdate,pEMP_NUMBER,pELR_ROOT_CODE, pVAR_CURRENCY, pFOREIGN_VALUE, pEMPLOYEE_VALUE, pVAR_VALFROM, pVAR_COMMENT, error_retour
from dual;

if NotNDF = 0 then

    var_exist :=null;
       begin
       --Teste de l'existance de la variable
        select hrm_employee_elements_id, fin.currency, emp_foreign_value, emp_num_value INTO var_exist, vOLD_CURRENCY, vOLD_FOREIGN_VALUE, vOLD_EMPLOYEE_VALUE
        from hrm_employee_elements a,
               hrm_elements_root b,
               hrm_elements_family c,
               hrm_person d  ,
               (select acs_financial_currency_id,currency
                   from acs_financial_currency fc, pcs.pc_curr cu where fc.pc_curr_id = cu.pc_curr_id) fin
        where a.hrm_elements_id = c.hrm_elements_id
        and    c.hrm_elements_root_id = b.hrm_elements_root_id
        and   d.hrm_person_id = a.hrm_employee_id
        and   emp_number = pEMP_NUMBER
        and   b.elr_root_code = pELR_root_code
        and   a.acs_financial_currency_id = fin.acs_financial_currency_id (+) ;
        exception when NO_DATA_FOUND then
           var_exist:=null;
        end;



if var_exist is null then
  insert_variable (pEMP_NUMBER,pELR_ROOT_CODE,pVAR_CURRENCY,pVAR_VALFROM,pVAR_REMP,pFOREIGN_VALUE,pEMPLOYEE_VALUE,pVAR_COMMENT);
 -- RAISE_APPLICATION_ERROR(-20000,'ICI');
 else
 update_variable (var_exist, pVAR_REMP,pFOREIGN_VALUE,pEMPLOYEE_VALUE,pVAR_COMMENT, pVAR_CURRENCY);
 update ind_hrM_var_interface set old_currency = vOLD_CURRENCY, old_foreign_value = vOLD_FOREIGN_VALUE, old_employee_value = vOLD_EMPLOYEE_VALUE
  where interface_id = new_id;
   --RAISE_APPLICATION_ERROR(-20000,'LA');
 end if;

end if;


 exception when others then
  erreur :=sqlcode||' - '||sqlerrm;
  --RAISE;
  update ind_hrm_var_interface set import_error = erreur where interface_id = new_id;



end IND_IMPORT_VARIABLE;

PROCEDURE IND_IMPORT_VAR_CONST (
pEMP_NUMBER varchar2,
pELR_ROOT_CODE  varchar2,
pVAR_CURRENCY  varchar2,
pVAR_VALFROM varchar2,
pVAR_VALTO varchar2,
pVAR_REMP varchar2,
pFOREIGN_VALUE  varchar2,
pEMPLOYEE_VALUE  varchar2 DEFAULT '0',
pVAR_COMMENT varchar2 DEFAULT NULL,
pIS_VAR_CONST varchar2)

is
new_id number;
erreur varchar2(4000);
var_exist number;
const_exist number;
vold_currency varchar2(10);
vold_foreign_value number(15,6);
vold_employee_value number(15,6);
vold_value_from date;
vold_value_to date;
NotNDF number;
error_retour varchar2(200);
vVAR_REMP varchar2(1);
vOLD_VAR_VALFROM date;
vOLD_VAR_VALTO date;

begin

select nvl(count(*),0) into NotNDF
from hrm_elements_root r,
        hrm_elements_family f
        where r.hrm_elements_root_id = f.hrm_elements_root_id
        and r. DIC_GROUP4_ID = 'NDF'
        and  r.elr_root_code = pELR_ROOT_CODE;

if   NotNDF > 0 then
    error_retour := 'variable de type NDF';
    end if;


select init_id_seq.nextval into new_id from dual;

insert into ind_hrm_var_const_interface (INTERFACE_ID, USE_NAME,A_DATECRE,EMP_NUMBER, ELR_ROOT_CODE, VAR_CURRENCY, FOREIGN_VALUE, EMPLOYEE_VALUE,VAR_VALFROM, VAR_VALTO, VAR_COMMENT, IS_VAR_CONST, import_error )
select new_id,USER,sysdate,pEMP_NUMBER,pELR_ROOT_CODE, pVAR_CURRENCY, pFOREIGN_VALUE, pEMPLOYEE_VALUE, pVAR_VALFROM, pVAR_VALTO, pVAR_COMMENT, pIS_VAR_CONST, error_retour
from dual;

if NotNDF = 0 then

-- VARIABLE
if upper(pIS_VAR_CONST)='V'
then
    var_exist :=null;
       begin
       --Teste de l'existance de la variable
        select hrm_employee_elements_id, fin.currency, emp_foreign_value, emp_num_value, emp_value_from, emp_value_to INTO var_exist, vOLD_CURRENCY, vOLD_FOREIGN_VALUE, vOLD_EMPLOYEE_VALUE, vOLD_VAR_VALFROM, vOLD_VAR_VALTO
        from hrm_employee_elements a,
               hrm_elements_root b,
               hrm_elements_family c,
               hrm_person d  ,
               (select acs_financial_currency_id,currency
                   from acs_financial_currency fc, pcs.pc_curr cu where fc.pc_curr_id = cu.pc_curr_id) fin
        where a.hrm_elements_id = c.hrm_elements_id
        and    c.hrm_elements_root_id = b.hrm_elements_root_id
        and   d.hrm_person_id = a.hrm_employee_id
        and   emp_number = pEMP_NUMBER
        and   b.elr_root_code = pELR_root_code
        and   a.acs_financial_currency_id = fin.acs_financial_currency_id (+) ;
        exception when NO_DATA_FOUND then
           var_exist:=null;
        end;

if var_exist is null then
  insert_variable2 (pEMP_NUMBER,pELR_ROOT_CODE,pVAR_CURRENCY,pVAR_VALFROM,pVAR_VALTO,pVAR_REMP,pFOREIGN_VALUE,pEMPLOYEE_VALUE,pVAR_COMMENT);
 -- RAISE_APPLICATION_ERROR(-20000,'ICI');
 else
 update_variable (var_exist, pVAR_REMP,pFOREIGN_VALUE,pEMPLOYEE_VALUE,pVAR_COMMENT, pVAR_CURRENCY);
 update ind_hrM_var_const_interface set old_currency = vOLD_CURRENCY, old_foreign_value = vOLD_FOREIGN_VALUE, old_employee_value = vOLD_EMPLOYEE_VALUE, OLD_VAR_VALFROM = vOLD_VAR_VALFROM, OLD_VAR_VALTO=vOLD_VAR_VALTO
  where interface_id = new_id;
   --RAISE_APPLICATION_ERROR(-20000,'LA');
 end if;

elsif upper(pIS_VAR_CONST)='C'
then
      const_exist :=null;
       begin
       --Teste de l'existance de la constante
       select hrm_employee_const_id, fin.currency, emc_foreign_value, emc_num_value, emc_value_from, emc_value_to INTO const_exist, vOLD_CURRENCY, vOLD_FOREIGN_VALUE, vOLD_EMPLOYEE_VALUE, vOLD_VALUE_FROM, vOLD_VALUE_TO
       from hrm_employee_const emc,
            (select acs_financial_currency_id,currency
             from acs_financial_currency fc, pcs.pc_curr cu where fc.pc_curr_id = cu.pc_curr_id) fin
       where emc.acs_financial_currency_id = fin.acs_financial_currency_id (+)
       and   hrm_employee_const_id =
                                    (select max(hrm_employee_const_id)
                                    from hrm_employee_const a,
                                           hrm_elements_root b,
                                           hrm_elements_family c,
                                           hrm_person d
                                    where a.hrm_constants_id = c.hrm_elements_id
                                    and    c.hrm_elements_root_id = b.hrm_elements_root_id
                                    and   d.hrm_person_id = a.hrm_employee_id
                                    and   emp_number = pEMP_NUMBER
                                    and   b.elr_root_code = pELR_root_code
                                    and   a.emc_value_from <= nvl(last_day(to_date(pVAR_VALTO,'DD.MM.YYYY')),to_date('31.12.2022','DD.MM.YYYY'))
                                    and   a.emc_value_to >= trunc(to_date(pVAR_VALFROM,'DD.MM.YYYY'),'MM')
                                    );
        exception when NO_DATA_FOUND then
           const_exist:=null;
        end;

  if const_exist is null then
  insert_constant (pEMP_NUMBER,pELR_ROOT_CODE,pVAR_CURRENCY,pVAR_VALFROM,nvl(pVAR_VALTO,to_date('31.12.2022','DD.MM.YYYY')),pVAR_REMP,pFOREIGN_VALUE,pEMPLOYEE_VALUE,pVAR_COMMENT);

  else

    -- mode 3 "fin de validité + nouveau" devient mode 1 "remplace" si la date de début de l'ancien record est plus grand  que la date de début du nouveau record
    if vOLD_VALUE_FROM >= nvl(to_date(pVAR_VALFROM,'DD.MM.YYYY'),to_date('31.12.2022','DD.MM.YYYY')) and pVAR_REMP='3'
     then vVAR_REMP:='1';
     else vVAR_REMP:=pVAR_REMP;
    end if;

  update_constant (const_exist, pELR_ROOT_CODE,vVAR_REMP,pFOREIGN_VALUE,pEMPLOYEE_VALUE, pVAR_VALFROM, pVAR_VALTO, pVAR_COMMENT, pVAR_CURRENCY);
  update ind_hrM_var_const_interface set old_currency = vOLD_CURRENCY, old_foreign_value = vOLD_FOREIGN_VALUE, old_employee_value = vOLD_EMPLOYEE_VALUE, OLD_VAR_VALFROM=vOLD_VALUE_FROM, OLD_VAR_VALTO=vOLD_VALUE_TO
  where interface_id = new_id;

 end if;

end if; --- VARIABLE / CONST

end if; -- NDF


 exception when others then
  erreur :=sqlcode||' - '||sqlerrm;
  --RAISE;
  update ind_hrm_var_const_interface set import_error = erreur where interface_id = new_id;


end IND_IMPORT_VAR_CONST;


PROCEDURE IND_IMPORT_CHANGE (pCHAN_CURRENCY varchar2, pCHAN_VALCONV varchar2, pCHAN_VALFROM varchar2, pCHAN_COURS varchar2) is

new_id number;
ERREUR VARCHAR2(4000);
FinancialCurrency number;
begin
select init_id_seq.nextval into new_id from dual;

    begin
    insert into ind_hrm_change_interface (INTERFACE_ID, USE_NAME, A_DATECRE, CHAN_CURRENCY, CHAN_VALCONV, CHAN_VALFROM, CHAN_COURS)
    select new_id,USER,sysdate,pCHAN_CURRENCY, pCHAN_VALCONV, pCHAN_VALFROM, pCHAN_COURS
    from dual;
    end ;

    begin

   select  acs_financial_currency_id into FinancialCurrency
    from acs_financial_currency ac,
            pcs.pc_curr cur
    where CUR.CURRENCY = pCHAN_CURRENCY
     and    cur.pc_curr_id = ac.pc_curr_id;

   insert into ACS_PRICE_CURRENCY (ACS_PRICE_CURRENCY_ID, ACS_BETWEEN_CURR_ID, ACS_AND_CURR_ID, PCU_DAYLY_PRICE, PCU_VALUATION_PRICE, PCU_INVENTORY_PRICE, PCU_CLOSING_PRICE, PCU_BASE_PRICE, PCU_START_VALIDITY, A_DATECRE, A_IDCRE, PCU_INVOICE_PRICE, PCU_VAT_PRICE)
   select new_id,
            FinancialCurrency,
           10086,
           pCHAN_COURS,
           pCHAN_COURS,
           pCHAN_COURS,
           pCHAN_COURS,
           pCHAN_VALCONV,
           to_date(pCHAN_VALFROM,'DD.MM.YYYY'),
           sysdate,
           (SELECT USE_INI
                FROM PCS.PC_USER
                WHERE USE_NAME = USER),
            pCHAN_COURS,
            pCHAN_COURS
        FROM DUAL
        WHERE NOT EXISTS (
        SELECT 1
        FROM ACS_PRICE_CURRENCY
        where ACS_BETWEEN_CURR_ID = FinancialCurrency
        and     PCU_START_VALIDITY =to_date(pCHAN_VALFROM,'DD.MM.YYYY')) ;

        EXCEPTION WHEN OTHERS then
           ERREUR := SQLCODE||' - '||SQLERRM;
           UPDATE  ind_hrm_change_interface SET IMPORT_ERROR = ERREUR WHERE INTERFACE_ID = new_id;

        end;

end ind_import_change;


END;
