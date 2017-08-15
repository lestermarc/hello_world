--------------------------------------------------------
--  DDL for Package Body HRM_IND
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND" is

FUNCTION GETPERSCONSTCODE (vHRM_PERSON_ID number, vCon_code Varchar2 ) return varchar2
   is

   retour varchar2(100) ;

   begin
   select MAX(c.COD_CODE) INTO retour
   from hrM_employee_const a,
     hrm_constants b,
	 hrm_code_table c
	 where a.HRM_CONSTANTS_ID = b.HRM_CONSTANTS_ID
	 and a.HRM_EMPLOYEE_ID = vHRM_PERSON_ID
	 and b.CON_CODE = vCon_code
	 and a.HRM_CODE_TABLE_ID = c.hrm_code_table_id
	 and a.EMC_VALUE_FROM <= HRM_date.ACTIVEPERIOD
	 and a.EMC_VALUE_TO > HRM_DATE.ACTIVEPERIOD
	 and a.EMC_ACTIVE = 1 ;

  Return NVL(retour,'');

   end; --end function

FUNCTION GETPERSCONSTCHAR(vHRM_PERSON_ID number, vCon_code Varchar2 ) return varchar2
   is

   retour varchar2(100) ;

   begin
   select MAX(EMC_VALUE) INTO retour
   from hrM_employee_const a,
     hrm_constants b
	 where a.HRM_CONSTANTS_ID = b.HRM_CONSTANTS_ID
	 and a.HRM_EMPLOYEE_ID = vHRM_PERSON_ID
	 and b.CON_CODE = vCon_code
	 and a.EMC_VALUE_FROM <= HRM_date.ACTIVEPERIOD
	 and a.EMC_VALUE_TO > HRM_DATE.ACTIVEPERIOD
	 and a.EMC_ACTIVE = 1 ;

  Return NVL(retour,'');

   end; --end function

FUNCTION GETPERSCONSTNUM(vHRM_PERSON_ID number, vCon_code Varchar2 ) return NUMBER
   is

   retour NUMBER(15,6) ;

   begin
   select MAX(EMC_NUM_VALUE) INTO retour
   from hrM_employee_const a,
     hrm_constants b
	 where a.HRM_CONSTANTS_ID = b.HRM_CONSTANTS_ID
	 and a.HRM_EMPLOYEE_ID = vHRM_PERSON_ID
	 and b.CON_CODE = vCon_code
	 and a.EMC_VALUE_FROM <= HRM_date.ACTIVEPERIOD
	 and a.EMC_VALUE_TO > HRM_DATE.ACTIVEPERIOD
	 and a.EMC_ACTIVE = 1 ;

  Return NVL(retour,0);

   end; --end function




 FUNCTION GETPERSVARCHAR (vHRM_PERSON_ID number, vEle_code Varchar2 ) return varchar2
   is

   retour varchar2(100) ;

   begin
   select MAX(emp_value) INTO retour
   from hrM_employee_elements a,
     hrm_elements b
	 where a.HRM_elements_ID = b.HRM_elements_ID
	 and a.HRM_EMPLOYEE_ID = vHRM_PERSON_ID
	 and b.ELE_CODE = vEle_code
	 and a.EMP_VALUE_FROM <= HRM_date.ACTIVEPERIOD
	 and a.EMP_VALUE_TO > HRM_DATE.ACTIVEPERIOD
	 and a.EMP_ACTIVE = 1 ;

  Return retour;

   end; --end function

FUNCTION CHARELEM(vEmp_id number, vCode varchar2, vBeginDate date, vEndDate date) return varchar2
   is
   tmp varchar2(200);
   begin
   select replace(max(h.his_pay_value),'"','') into tmp
   from hrm_history_detail h, v_hrm_elements_short v
   where upper(v.code) = upper(vCode) and
    h.hrm_elements_id = v.elemId and
    h.hrm_employee_id = vEmp_id and
    h.his_pay_period between vBeginDate and vEndDate;
  if tmp is null then
    return '';
  else
    return tmp;
  end if;
  exception
    when others then return'';

	end CHARELEM;

function sumElemOnePeriod(vEmp_id number, vCode varchar2, vDate varchar2) return number is
  tmp number;
begin
  select Sum(h.his_pay_sum_val) into tmp
  from hrm_history_detail h, v_hrm_elements_short v
  where upper(v.code) = upper(vCode) and
    h.hrm_elements_id = v.elemId and
    h.hrm_employee_id = vEmp_id and
    to_char(h.his_pay_period,'YYYYMM') = vDate;
  if tmp is null then
    return 0;
  else
    return tmp;
  end if;
  exception
    when others then return 0;
end sumElemOnePeriod;


function ind_calc(vPersonID number, CurrSoum number,CurrSoumAnnu number, CurrSoumNonAnnu number, CurrNbJour number,
		 		  GSSoum varchar2, GSSoumAnnu varchar2, GSSoumNonAnnu varchar2,GSNbJour varchar2,CurrDecompte number)
				  return number is
-- Retourne le montant de déduction impôt source total pour l'année en cours
-- en fonction des dates saisies dans les codes avec tabelle

pragma autonomous_transaction;



/* Paramètres de la fonction

CurrSoum = montant du Soumis résultant de la calculation en cours: CemSoumIS dans les paramètres du GS
CurrSoumAnnu = montant du Soumis à annualiser résultant de la calculation en cours: CemSouISAnnu
CurrSoumNonAnnu = montant du Soumis à ne pas annualiserrésultant de la calculation en cours: CemSouISNonAnnu
CurrNbJour = nombre de jours résultant de la calculation en cours: CemJDeTravIS

GSSoum = nom de l'ELE_CODE du soumis: "CemSouIS" dans les paramètres du GS
GSSoumAnnu = nom de l'ELE_CODE du soumis à annualiser: "CemSouISAnnu"
GSSoumNonAnnu = nom de l'ELE_CODE du soumis à ne pas annualiser: "CemSouISNonAnnu"
GSNbJour = onm de l'ELE_CODE du nombre de jours: "CemSJDeTravIS"

CurrDecompte = id du décompte en cours de calcul: emDécActif
*/

--Curseur affichant les différentes lignes de Tarification impôt source (Employés avec GS) pour L'ANNEE EN COURS
Cursor Cur_Barem is
select
cod_code TAX_CODE, -- Barème
GREATEST(emc_value_from,hrm_date.BEGINOFYEAR) TAX_BEGIN, -- MAX (Date début validité / Début année)
nvl(emc_value_to,hrm_date.ACTIVEPERIODENDDATE) TAX_END -- Date de fin de validité
from hrm_employee_const a,
	 hrm_constants b,
	 hrm_code_table c
where
 a.hrm_constants_id = b.hrm_constants_id and
 a.hrm_code_table_id = c.hrm_code_table_id and
 hrm_employee_id = vPersonId and
 (emc_value_to is null or emc_value_to > hrm_date.BEGINOFYEAR) and
 con_code = 'ConEmISCode';

-- Définition des variables
Deduction number(15,2);
DeductionTot number(15,2);
CodeGS varchar2(20);
SoumIS number(15,2);
SoumISAnnu number(15,2);
SoumISNonAnnu number(15,2);
SoumISMoy number(15,2);
nbjourIS number;
TaxRate number(15,5);
Mois varchar2(2);
Periode date;
DecDefinitif number;
Bareme varchar2(10);
BaremeDebut date;
BaremeFin date;
vCount integer;


begin
-- Initianlisation de la déduction
Deduction := 0;
DeductionTot := 0;
vCount:=0;

IF CurrSoum <> 0 THEN

-- Recherche du mois de la période active
select
to_char(per_end,'MM'), per_end into Mois, Periode
from
hrm_period
where
per_act=1;

-- Recherche si la case Décompte définitif est cochée
select
hrm_var.isFinalPay(vPersonId) into DecDefinitif
from
dual;

-- Suppression des records déjà existants pour l'employé dans la période en cours et sur le même décompte
    	delete from indiv_hrm_is_ctrl
    	where
    	HRM_EMPLOYEE_ID= vPersonID
    	and PERIOD = Periode
    	and SALARY_SHEET = CurrDecompte;
		commit;

-- *** Ouverture du curseur *** --
for RowBarem in cur_Barem loop
vCount:=vCount+1;
--DBMS_OUTPUT.PUT_LINE('LIGNE '||to_char(vCount)||' -----------------------');

    --Recherche du SoumIS selon intervale de temps pour un code barème
    -- Dans l'historique
    select nvl(sum(Soum),0)
    into SoumIS
    from
    (select sum(his_pay_sum_val) Soum
    from hrm_history_detail a,
    hrm_elements b
    where a.hrm_employee_id = vPersonId
    and a.hrm_elements_id = b.hrm_elements_id
    and ele_code = GSSoum
    and to_char(his_pay_period,'YYYY') =
    to_char(hrm_date.ACTIVEPERIOD,'YYYY')
    and his_pay_period between RowBarem.Tax_begin and RowBarem.Tax_end
    union all
    -- Dans les montants en cours de calculation
    select CurrSoum Soum
    from dual
    where hrm_date.ACTIVEPERIODENDDATE between RowBarem.Tax_begin
    and RowBarem.Tax_end);

    --Recherche du SoumIS à annualiser selon intervale de temps pour un code barème
    -- Dans l'historique
    select nvl(sum(Soum),0)
    into SoumISAnnu
    from
    (select sum(his_pay_sum_val) Soum
    from hrm_history_detail a,
    hrm_elements b
    where a.hrm_employee_id = vPersonId
    and a.hrm_elements_id = b.hrm_elements_id
    and ele_code = GSSoumAnnu
    and to_char(his_pay_period,'YYYY') =
    to_char(hrm_date.ACTIVEPERIOD,'YYYY')
    and his_pay_period between RowBarem.Tax_begin and RowBarem.Tax_end
    union all
    -- Dans les montants en cours de calculation
    select CurrSoumAnnu Soum
    from dual
    where hrm_date.ACTIVEPERIODENDDATE between RowBarem.Tax_begin
    and RowBarem.Tax_end);

    --Recherche du SoumIS à ne pas annualiser selon intervale de temps pour un code barème
    -- Dans l'historique
    select nvl(sum(Soum),0)
    into SoumISNonAnnu
    from
    (select sum(his_pay_sum_val) Soum
    from hrm_history_detail a,
    hrm_elements b
    where a.hrm_employee_id = vPersonId
    and a.hrm_elements_id = b.hrm_elements_id
    and ele_code = GSSoumNonAnnu
    and to_char(his_pay_period,'YYYY') =
    to_char(hrm_date.ACTIVEPERIOD,'YYYY')
    and his_pay_period between RowBarem.Tax_begin and RowBarem.Tax_end
    union all
    -- Dans les montants en cours de calculation
    select CurrSoumNonAnnu Soum
    from dual
    where hrm_date.ACTIVEPERIODENDDATE between RowBarem.Tax_begin
    and RowBarem.Tax_end);


    --Recherche du Nombre de jours selon intervale de temps pour un code barème
    -- Dans l'historique
    select nvl(sum(nbjour),0)
    into nbjourIS
    from
    (select sum(his_pay_sum_val) nbjour
    from hrm_history_detail a,
    hrm_elements b
    where a.hrm_employee_id = vPersonId
    and a.hrm_elements_id = b.hrm_elements_id
    and ele_code = GSNbJour
    and to_char(his_pay_period,'YYYY') =
    to_char(hrm_date.ACTIVEPERIOD,'YYYY')
    and his_pay_period between RowBarem.Tax_begin and RowBarem.Tax_end
    union all
    -- Dans les montants en cours de calculation
    select CurrNbJour nbjour
    from dual
    where hrm_date.ACTIVEPERIODENDDATE between RowBarem.Tax_begin
    and RowBarem.Tax_end);

    --affichages
    --DBMS_OUTPUT.PUT_LINE('Soum is : '||to_char(SoumIS));
    --DBMS_OUTPUT.PUT_LINE('Soum is annu : '||to_char(SoumISAnnu));
    --DBMS_OUTPUT.PUT_LINE('Soum is Non annu : '||to_char(SoumISNonAnnu));
    --DBMS_OUTPUT.PUT_LINE('Jours is : '||to_char(nbjourIS));

    --Recherche du SoumIS Moyen


    If DecDefinitif=1 or Mois='12'
    then
      SoumISMoy := SoumIS/nbjourIS*30;
      DBMS_OUTPUT.PUT_LINE('Soum is moy en sortie : '||to_char(SoumISMoy));
    else
	  if nbjourIS <> 0
	  then
        SoumISMoy := ((SoumISAnnu/nbjourIS*360)+SoumISNonAnnu)/12;
	  else SoumISMoy := 0;
	  end if;
      --DBMS_OUTPUT.PUT_LINE('Soum is moy en cours d''annee : '||to_char(SoumISMoy));
    end if;


    -- Recherche du taux dans la tabelle en fonction du SoumIS Moyen
    TaxRate:=hrm_functions.TAXRATE(SoumISMoy,Substr(RowBarem.tax_code,1,2),RowBarem.tax_code);
    --DBMS_OUTPUT.PUT_LINE('Rate : '||to_char(TaxRate));

    -- Recherche de la déduction totale
    Deduction := SoumIS*TaxRate/100;
    --DBMS_OUTPUT.PUT_LINE('Deduction : '||to_char(Deduction));
    DeductionTot := DeductionTot + Deduction;

    	-- Insertion dans la table INDIV
    	--pragma autonomous_transaction;


    	--Insertion dans la table sur laquelle se base le rapport de contrôle
    	insert into indiv_hrm_is_ctrl
    	values (
    	vPersonID,
    	RowBarem.tax_code,
    	RowBarem.tax_begin,
    	RowBarem.tax_end,
    	SoumIS,
    	SoumISNonAnnu,
    	SoumISAnnu,
    	nbjourIS,
    	SoumISMoy,
    	TaxRate,
    	Deduction,
    	Periode,
    	CurrDecompte,
    	DecDefinitif);
		commit;


end loop;
-- *** Fermeture du curseur *** --

END IF;

Return DeductionTot;



/*
GS à créer

Jours de travail IS (JDeTravIS): IF(ConEmIS,IF(emJDeTravIS<>0,emJDeTravIS,CemJDeTrav),0)
Soumis impôt source (SoumIS): IF(ConEmIS,CemSalBrut,0)
Soumis impôt source à ne pas annualiser (SoumISNonAnnu): =IF(ConEmIS,CemPrimeR,0)
Soumis impôt source à annualiser (SoumISAnnu): =IF(ConEmIS,(CemSoumIS-Cem13ème+CemProv13ème)-CemSoumISNonAnnu,0)
Impôt à la source (déduction totale) (DédISTot): Retourne la valeur de la fonction
Impôt source (DédIS): IF(emDédIS<>0,emDédIS,IF(ConEmDédIS<>0,ConEmDédIS,-DivDédISTot-CumCemDédIS))

Barème

Saisie dans les codes avec tabelle / Tarification impôt à la source
Prise en compte des dates de validités
*/

end ind_calc;


procedure get_line_plus(file_in in UTL_FILE.FILE_TYPE, line_out OUT varchar2, eof_out OUT boolean) is

begin
UTL_FILE.GET_LINE(file_in, line_out);
 eof_out := false;

Exception
  When no_data_found then
     dbms_output.put_line('Plus de ligne à traiter');
	 line_out := null;
	 eof_out := true;

end get_line_plus;



/*
###
### Procédure d'importation et de validation les variables fichiers divers
### ______________________________________________________________________
*/
procedure import_divers_elements(PersonPosition number, ElementPosition number, ValuePosition number, vFileName varchar2,vFilePath varchar2,transferDate Date, transferName Varchar, structureId Integer)
is
ImportDocId number;
ImportLogId number;
CountError number;
PersonID number;
ElementID number;
IsVar number;
ModImport number;

-- variable du read_file
vl_FilePath varchar2(200) ;
vl_FileName varchar2(100) := vFileName;
vl_Import_file UTL_FILE.FILE_TYPE;
vl_Numero_ligne integer;
vl_count integer;
vl_import_record varchar(32767);
vl_eof boolean;


-- variable de l'importation
Step Varchar2(10);


  -- sous fonction de recherche de l'employé
  function GetPersonID (vEmp_number varchar2) return number is
  ReturnValue number;
  begin
  select max(hrm_person_id) into ReturnValue
  from hrm_person
  where emp_number = vEmp_number;

  Return ReturnValue;
  end GetPersonID;


  procedure SetElementData (vEle_stat_code varchar2) is
  begin
  select max(a.hrm_elements_id),max(a.EIM_TRANSFER_MODE),nvl(max(ELE_VARIABLE),0)
  into ElementID,ModImport,IsVar
  from hrm_elements_import_code a,
       hrm_elements b
  where a.hrm_elements_id = b.hrm_elements_id (+)
  and EIM_IMPORT_CODE = vEle_stat_code
  and pc_import_data_id = structureId  ;

  end SetElementData;


  function GetElementID (vEle_stat_code varchar2) return number is
  ReturnValue number;
  begin
  select max(hrm_elements_id) into ReturnValue
  from hrm_elements_import_code
  where EIM_IMPORT_CODE = vEle_stat_code
  and pc_import_data_id = structureId  ;

  Return ReturnValue;
  end GetElementID;


begin


vl_FilePath := vFilePath;

Step := '[001]';
dbms_output.put_line('ouverture du fichier : '||vl_FilePath||vl_FileName);
vl_Import_file := UTL_FILE.FOPEN(vl_FilePath,vl_fileName,'R');
dbms_output.put_line('fichier ouvert');
vl_Numero_ligne := 0;

Step := '[002]';

CountError := 0;
select init_id_seq.nextval into ImportDocId from dual;
insert into hrm_import_doc (HRM_IMPORT_DOC_ID, PC_IMPORT_DATA_ID, IMD_DESCR, IMD_VALIDATED, IMD_TRANSFERRED, A_DATECRE, A_IDCRE)
values(ImportDocId,structureId,transferName,0,0,sysdate,'proc');
Get_line_plus(vl_Import_file, vl_import_record, vl_eof);
Step := '[003]';
while not(vl_eof)
  loop
  vl_Numero_ligne := vl_Numero_ligne+1;
  PersonID := GetPersonID(PCS.ExtractLine(vl_import_record,PersonPosition,';'));
  SetElementData(PCS.ExtractLine(vl_import_record,ElementPosition,';'));
  --ElementID := GetElementID(PCS.ExtractLine(vl_import_record,ElementPosition,';'));
  select init_id_seq.nextval into ImportLogId from dual;
  insert into hrm_import_log(HRM_IMPORT_LOG_ID
  		 	  				,PC_IMPORT_DATA_ID
							,HRM_IMPORT_DOC_ID
							,IML_TRANSFER_CODE
							,IML_EMP_CODE
							,HRM_EMPLOYEE_ID
							,IML_ELEM_CODE
							,HRM_ELEMENTS_ID
							,IML_VALUE_FROM
							,IML_VALUE_TO
							,IML_VALUE
							,IML_TEXT
							,IML_IMPORT_DATE
							,IML_IMP_ERROR_CODE
							,IML_IS_VAR)
  values					(ImportLogId
  							,structureId
							,ImportDocId
							,ModImport
							,PCS.ExtractLine(vl_import_record,PersonPosition,';')
							,PersonID
							,PCS.ExtractLine(vl_import_record,ElementPosition,';')
							,ElementID
							,hrm_date.ACTIVEPERIOD
							,hrm_date.ACTIVEPERIODENDDATE
							,to_number(PCS.ExtractLine(vl_import_record,ValuePosition,';'))
							,''
							,sysdate
							,decode(PersonID,null,2,decode(ElementID,null,1))
							,IsVar);

  Get_line_plus(vl_Import_file, vl_import_record, vl_eof);
  end loop;

  select count(*) into CountError
  from hrm_import_log
  where hrm_import_doc_id = ImportDocId
  and iml_imp_error_code is not null;

  update hrm_import_doc set IMD_VALIDATED = 1, IMD_VAL_ERROR_NUM = CountError
  where hrm_import_doc_id = ImportDocId ;

dbms_output.put_line('Nombre de lignes traitées : '||to_char(vl_Numero_ligne));

Step := '[004]';
dbms_output.put_line('Fermeture du fichier');
UTL_FILE.FCLOSE(vl_Import_file);
dbms_output.put_line('Fichier fermé');

Step := '[005]';
dbms_output.put_line('Déplacement du fichier dans old');
UTL_FILE.FRENAME(vl_FilePath,vl_FileName,vl_FilePath||'old\',to_char(sysdate,'YYYYMMDDHH24MISS')||vl_FileName);

Exception
  when others then
    dbms_output.put_line(Step||' '||'Erreur inconnu'||chr(10)||sqlcode||' : '||sqlerrm);
	UTL_FILE.FCLOSE(vl_Import_file);
	dbms_output.put_line('fichier fermé');
	raise_application_error(-20000,Step||' '||'Erreur inconnu'||chr(10)||'Répertoire de fichier : '||vl_FilePath||chr(10)||sqlcode||' : '||sqlerrm);

end import_divers_elements;


procedure start_traitement is

begin
dbms_output.put_line('start');
end start_traitement;



end hrm_ind;
