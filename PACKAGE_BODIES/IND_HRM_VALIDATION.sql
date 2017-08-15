--------------------------------------------------------
--  DDL for Package Body IND_HRM_VALIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_HRM_VALIDATION" 
AS

 FUNCTION test_emp_number (main_id IN NUMBER,context IN VARCHAR2,message OUT VARCHAR2) RETURN INTEGER
 -- Contr�le du no d'employ�
 IS
   EmpNum   varchar2(20);
   IsEmployee integer;
   vCount number;
   retour integer;
 BEGIN
  -- recherche du no d'employ� + s'il s'agit d'un employ�
  SELECT nvl(emp_number,'0'),nvl(per_is_employee,0)
  INTO EmpNum,IsEmployee
  FROM hrm_person
  WHERE hrm_person_id = main_id;

  -- contr�le qu'il n'existe qu'un no d'employ� (le no n'existe pas d�j�)
  select count(*) into vCount
  from hrm_person
  where emp_number=EmpNum;

  if vCount>1
   then message := 'Contr�le de validation'||chr(10)||chr(10)||
   				   'Le No d''employ� "'||EmpNum||'" existe d�j�';
   	    retour :=pcs.pc_ctrl_validate.e_fatal;
   else
       IF (EmpNum not like 'E%' or length(EmpNum) <> 6)  and IsEmployee=1 THEN
        BEGIN message := 'Contr�le de validation'||chr(10)||chr(10)||
                         'Veuillez contr�ler le num�ro d''employ�. Celui-ci doit commencer par "E" et �tre compos� de 6 positions';
              retour  :=  pcs.pc_ctrl_validate.e_warning;
        END;
       ELSE
        BEGIN message := '';
              retour  :=  pcs.pc_ctrl_validate.e_success;
        END;
       END IF;
  end if;

 RETURN retour;

END test_emp_number;

FUNCTION test_price_currency (main_id IN NUMBER,context IN VARCHAR2,message OUT VARCHAR2) RETURN INTEGER
 /* Contr�le du cours saisi dans la Gestion des cours
  * Pour �viter les probl�mes de diff�rence de change et d'arrondi dans les salaires
  * Les valeurs dans HRM_HISTORY_DETAIL sont stock�es avec 5 d�cimales, mais le cours peut �tre saisi
  * avec 6 d�cimales,. Donc le premier calcul se fait avec 6 d�cimales et on stocke le cours avec 5.
  * Lors de la conversion suivante, le r�sultat n'est plus le m�me.
  * NB: le cours peut �tre saisi avec un diviseur 1 ou 100. Avec 100 c'est encore pire.
 */
 IS
   Diviseur number;
   InitI number;
   i integer;
   Decimale number;
   DecByPrice1 number;
   DecByPrice2 number;
   DecByPrice3 number;
   DecByPrice4 number;
   DecByPrice5 number;
   DecByPrice6 number;
   retour integer;
 BEGIN
  -- recherche du Diviseur
  select
  max(pcu_base_price) into Diviseur
  from
  acs_price_currency
  where
  acs_price_currency_id=main_id;

  -- D�cimale � partir de laquelle il faut tester (en fonction du diviseur)
  -- Si diviseur=1 -> la d�cimale 6 doit �tre � z�ro (5 d�cimales autoris�es)
  -- Si diviseur=100 -> les d�cimales 4 - 6 doivent �tre � z�ro (3 d�cimales autoris�es)
  if Diviseur=1
   then InitI:=6;
   else InitI:=4;
  end if;

  Decimale:=0;

  for i in InitI..6
  loop
   -- cours du jours
   select
   to_number(substr(pcs.extractline(to_char(pcu_dayly_price,'0.00000000'),2,'.'),i,1)),
   to_number(substr(pcs.extractline(to_char(PCU_VALUATION_PRICE,'0.00000000'),2,'.'),i,1)),
   to_number(substr(pcs.extractline(to_char(PCU_INVENTORY_PRICE,'0.00000000'),2,'.'),i,1)),
   to_number(substr(pcs.extractline(to_char(PCU_CLOSING_PRICE,'0.00000000'),2,'.'),i,1)),
   to_number(substr(pcs.extractline(to_char(PCU_INVOICE_PRICE,'0.00000000'),2,'.'),i,1)),
   to_number(substr(pcs.extractline(to_char(PCU_VAT_PRICE,'0.00000000'),2,'.'),i,1))
   into DecByPrice1,DecByPrice2,DecByPrice3,DecByPrice4,DecByPrice5,DecByPrice6
   from
   acs_price_currency
   where
   acs_price_currency_id=main_id;

   Decimale:=Decimale+DecByPrice1+DecByPrice2+DecByPrice3+DecByPrice4+DecByPrice5+DecByPrice6;

  end loop;

  if Decimale <> 0
   then message := 'Le nombre de d�cimales saisi est trop �lev� et peut poser probl�me lors du calcul des salaires'||chr(10)||chr(10)||
				   'R�gle de saisie:'||chr(10)||
				   'Si le diviseur est 1 -> 5 d�cimales'||chr(10)||
				   'Si le diviseur est 100 -> 3 d�cimales';
   	    retour :=pcs.pc_ctrl_validate.e_warning;
   else message := '';
        retour	:=  pcs.pc_ctrl_validate.e_success;
  end if;

 RETURN retour;

END test_price_currency;

function test_charges_management (main_id in number, context in varchar2, message out varchar2) return integer
   -- Frais de gestion des r�f�rences financi�res:
   --si le type de r�frence fin <> 3 (cash), alors les fraisd e gestion devraient �tre � 0 (donneur d'ordre)
   is
    retour integer;
   begin
    select
    count(*) into retour
    from
    hrm_financial_ref
    where
    hrm_employee_id=main_id
    and C_FINANCIAL_REF_TYPE <> '3'
    and (C_CHARGES_MANAGEMENT <> '0'
        or C_CHARGES_MANAGEMENT is null);

    if retour > 0
    then message := 'R�f�rences financi�res : Les frais ne sont pas pour le Donneur d''ordre. Veuillez contr�ler cette donn�e';
         retour  :=  pcs.pc_ctrl_validate.e_warning;
    else message := '';
         retour  :=  pcs.pc_ctrl_validate.e_success;
    end if;

    RETURN retour;

   end test_charges_management;

FUNCTION test_alloc_doc_record (main_id IN NUMBER,context IN VARCHAR2,message OUT VARCHAR2) RETURN INTEGER
 -- M�thodes de ventilation: contr�le que le dossier est renseign� pour les comptes sur lesquels il est n�cessaire (code libre 3 Gestion des comptes)
 IS
   vAccount varchar2(20);
   retour integer;
 BEGIN
  select
  max(d.ALD_ACC_NAME) into vAccount
  from
  hrm_allocation_detail d,
  acs_account a,
  acs_financial_account f
  where
  d.ALD_ACC_NAME=a.acc_number
  and a.acs_account_id=f.acs_financial_account_id
  and DIC_FIN_ACC_CODE_3_ID='OUI'
  and d.hrm_allocation_id=main_id
  and not exists (select 1
                  from hrm_allocation_detail d2
                  where d.hrm_allocation_id=d2.hrm_allocation_id
                  and d.ald_rate=d2.ald_rate
                  and d2.DIC_ACCOUNT_TYPE_ID='DOC_RECORD');

  if vAccount is not null
   then message := 'Le compte '||vAccount||' doit �tre rattach� � un dossier';
        retour :=pcs.pc_ctrl_validate.e_warning;
   else
       message := '';
      retour  :=  pcs.pc_ctrl_validate.e_success;
  end if;

 RETURN retour;

END test_alloc_doc_record;

function test_code_soum (main_id in number, context in varchar2, message out varchar2) return integer
 -- Calcul des d�comptes: test que les codes soumission "Monnaie du d�compte" et "Taux de change de la monnaie du d�compte" soient renseign�s
 IS
  Cursor CurError is
  select
  f.hrm_elements_id,
  d.erd_descr
  from
  hrm_elements_root r,
  hrm_elements_family f,
  hrm_elements_root_descr d
  where
  r.hrm_elements_root_id=f.hrm_elements_root_id
  and r.hrm_elements_root_id=d.hrm_elements_root_id
  and r.elr_root_name in ('MonnaieD�c','MonnaieD�cTypeTaux')
  and f.HRM_ELEMENTS_PREFIXES_ID='CONEM'
  and d.pc_lang_id=1
  and not exists (select 1
                  from hrm_employee_const ec
                  where f.hrm_elements_id=ec.hrm_constants_id
                  and hrm_employee_id=main_id
                  and emc_value_from <= hrm_date.ACTIVEPERIODENDDATE
                  and emc_value_to >= hrm_date.ACTIVEPERIOD
                  and emc_active=1);

   msg varchar2(2000);
   vCount integer;
   retour integer;
 BEGIN

  vCount:=0;

  for RowError in CurError
  loop
   insert into hrm_errors_log (
               HRM_EMPLOYEE_ID,
               HRM_ELEMENTS_ID,
               ELO_MESSAGE,
               ELO_DATE,
               ELO_TYPE)
               values
               (main_id,
               RowError.hrm_elements_id,
               'Code soumission manquant',
               sysdate,
               1);
   vCount:=vCount+1;
  end loop;

  if vCount > 0
   then message := 'Codes soumissions obligatoires non renseign�s';
        retour :=pcs.pc_ctrl_validate.e_fatal;
   else
       message := '';
      retour  :=  pcs.pc_ctrl_validate.e_success;
  end if;

 RETURN retour;

END test_code_soum;

FUNCTION test_emp_div (main_id IN NUMBER,context IN VARCHAR2,message OUT VARCHAR2) RETURN INTEGER
 -- Contr�le que la division de l'employ� = matricule (pour les soci�t�s utilisant la comptabilit� PCS)
 IS
   Ctrl integer;
   ComptaPCS pcs.pc_cocom.cococval%type;
   retour integer;
 BEGIN
  -- recherche des divisions <> du matricule
  select count(*) into Ctrl
  from hrm_person a, hrm_employee_break b
  where a.hrm_person_id=b.hrm_employee_id
  and a.hrm_person_id = main_id
  and a.emp_number <> b.heb_div_number;

  -- recherche de la config soci�t� HRM_BREAK_TARGET -> comptabilit� PCS
  select max(cococval) into ComptaPCS
  from pcs.pc_cocom
  where cbacname_upper='HRM_BREAK_TARGET'
  and pc_comp_id=pcs.pc_init_session.getcompanyid;

  if Ctrl > 0 and ComptaPCS = 0
   then message := 'La division comptable doit correspondre au matricule du salari�. Veuillez contr�ler cette donn�e';
        retour  :=  pcs.pc_ctrl_validate.e_warning;
   else message := '';
        retour  :=  pcs.pc_ctrl_validate.e_success;
  end if;

 RETURN retour;

END test_emp_div;

function test_break_curr (main_id in number, context in varchar2, message out varchar2) return integer
 -- Calcul des d�comptes: test que les codes soumission "Monnaie du d�compte" et "Taux de change de la monnaie du d�compte" soient renseign�s
 IS
  Cursor CurError is
  select
  per.hrm_person_id,
  per.per_search_name per_fullname,
  per.emp_number,
  b.CPD_TEXT1 heb_shift_descr,
  c.cod_code
  from
  hrm_person per,
  (select
   emb.hrm_employee_id,
   emb.heb_shift,
   cg3.CPD_TEXT1
   from hrm_employee_break emb, COM_CPY_CODES_VALUE cg1, COM_CPY_CODES cg2, COM_CPY_CODES_VALUE_DESCR cg3
   where emb.heb_shift=cg1.CPV_NAME
   and cg1.COM_CPY_CODES_ID=cg2.COM_CPY_CODES_ID
   and cg2.CPC_NAME='DEV_SHIFT'
   and cg1.COM_CPY_CODES_VALUE_ID=cg3.COM_CPY_CODES_VALUE_ID
   and cg3.pc_lang_id=1
   ) b,
  (select
   emc.hrm_employee_id,
   cta.cod_code
   from hrm_employee_const emc, hrm_code_table cta
   where emc.hrm_code_table_id= cta.hrm_code_table_id
   and emc_active=1
   and exists (select 1
             from hrm_constants con
             where emc.hrm_constants_id=con.hrm_constants_id
             and con.con_code='ConEmMonnaieD�c')
  ) c
  where
  per.hrm_person_id= b.hrm_employee_id(+)
  and per.hrm_person_id=c.hrm_employee_id(+)
  and nvl(b.CPD_TEXT1,'null') <> nvl(c.cod_code,'null')
  and exists (select 1
              from hrm_history hit, hrm_break bre
              where hit.hit_pay_period=bre.brk_value_date
              and bre.hrm_break_id=main_id
              and per.hrm_person_id= hit.hrm_employee_id)
  ORDER BY PER_SEARCH_NAME;

   msg varchar2(2000);
   vCount integer;
   retour integer;
 BEGIN

  vCount:=0;
  msg:='Monnaie du d�compte (code soumission) diff�rente de la monnaie de comptabilisation (Gestion des employ�s)'
  ||chr(10)||chr(10);
  for RowError in CurError
  loop
  /* insert into hrm_errors_log (
               HRM_EMPLOYEE_ID,
               HRM_ELEMENTS_ID,
               ELO_MESSAGE,
               ELO_DATE,
               ELO_TYPE)
               values
               (RowError.hrm_person_id,
               null,
               'La monnaie du d�compte (code soumission) est diff�rente de la monnaie de comptabilisation (Gestion des employ�s)',
               sysdate,
               3);
   */
   msg := msg||RowError.per_fullname||' ('||RowError.emp_number||')'||'   -   '||'code soumission '||RowError.cod_code||' et ventilation '||RowError.heb_shift_descr||chr(10);
   vCount:=vCount+1;
  end loop;

  if vCount > 0
   then message := msg;
        retour :=pcs.pc_ctrl_validate.e_fatal;
   else
       message := '';
      retour  :=  pcs.pc_ctrl_validate.e_success;
  end if;

 RETURN retour;

END test_break_curr;

FUNCTION test_break_tax (main_id in number, context in varchar2, message out varchar2) return integer
   -- Contr�le de validation � la ventilation
   -- Rempli la table HRM_PERSON_TAX si des records sont manquant
   is
    retour integer;
   begin
   
    insert into hrm_person_tax (HRM_PERSON_ID, C_HRM_TAX_CERTIF_TYPE, EMP_TAX_YEAR, A_DATECRE, A_IDCRE)
    select hrm_person_id, '01', to_char(hrm_date.activeperiod,'YYYY'), sysdate, 'CTRL'
    from hrm_person a
    where emp_status='ACT'
    and not exists (select 1
                    from hrm_person_tax b
                    where a.hrm_person_id=b.hrm_person_id
                    and EMP_TAX_YEAR=to_char(hrm_date.activeperiod,'YYYY'));
    commit;
    

    message := '';
    retour  :=  pcs.pc_ctrl_validate.e_success;         
    
    RETURN retour;
   
END test_break_tax;

FUNCTION test_emp_group_entry (main_id in number, context in varchar2, message out varchar2) return integer
   -- Contr�le de validation d�tail sur HRM_IN_OUT
   -- Contr�le de la date entr�e groupe (pour contrer l'automatisme de remplacement de la date d'entr�e groupe par la date d'entr�e en cas de nouvelle saisie)
   -- D�clenchement uniquement sur le 1er record HRM_IN_OUT
   is
    EmpId hrm_person.hrm_person_id%type;
    GroupEntry hrm_person.emp_group_entry%type;
    EmpEntry hrm_in_out.ino_in%type;
    InoCount integer;
    retour integer;
   begin
   
  -- Id de l'employ�
  select max(hrm_employee_id) into EmpId
  from hrm_in_out
  where hrm_in_out_id=main_id;
   
   -- recherche si record existe d�j� (avant cet insert)
   select count(*) into InoCount
   from hrm_in_out
   where hrm_employee_id=EmpId
   and hrm_in_out_id<>main_id;
   
   if InoCount=0
   then -- recherche date d'entr�e groupe
        select max(emp_group_entry) into GroupEntry
        from hrm_person
        where hrm_person_id=EmpId;
        
        -- recherche date d'entr�e
        select max(ino_in) into EmpEntry
        from hrm_in_out
        where hrm_in_out_id=main_id;
   
        if nvl(GroupEntry,to_date('01.01.2000','DD.MM.YYYY')) = nvl(EmpEntry,to_date('01.01.2000','DD.MM.YYYY'))
        then 
              message := 'La date d''entr�e de l''employ� est identique � la date d''ent�re dans le groupe ('||to_char(GroupEntry,'DD.MM.YYYY')||').'||chr(10)||
                         'La date d''entr�e groupe a potentiellement �t� �cras�e.'||chr(10)||
                         'Merci de contr�ler cette donn�e.';
              retour  :=  pcs.pc_ctrl_validate.e_warning; 
        else  
              message := '';
              retour  := pcs.pc_ctrl_validate.e_success;
        end if;
   
   else message := '';
        retour  := pcs.pc_ctrl_validate.e_success;
   
   end if;     
    
   RETURN retour;
   
END test_emp_group_entry;

END ind_hrm_validation;
