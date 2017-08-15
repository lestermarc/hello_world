--------------------------------------------------------
--  DDL for Package Body IND_ACS_VALIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_ACS_VALIDATION" 
is
  function update_dossier_allocation(main_id IN NUMBER,context IN VARCHAR2,message OUT VARCHAR2) RETURN INTEGER
  -- Si le Dossier est obligatoire sur un compte (DIC_FIN_ACC_CODE_3_ID)
    -- -> recherche dans les méthodes de ventilation si le dossier est présent, sinon insert
  -- Si le Dossier n'est pas obligatoire sur un compte (DIC_FIN_ACC_CODE_3_ID)
    -- -> recherche dans les méthodes de ventilation si le dossier n'est pas présent, sinon delete
  is
  Cursor CurInsertDossier is
    SELECT
	e.hrm_allocation_id,
    e.all_code,
	e.all_descr,
	c.ald_rate
    FROM
    acs_account a,
	acs_financial_account b,
	hrm_allocation_detail c,
	hrm_allocation e
	where a.acs_account_id=b.acs_financial_account_id
	and a.acc_number=c.ALD_ACC_NAME
	and c.hrm_allocation_id=e.hrm_allocation_id
	and a.acs_account_id=main_id
	and b.DIC_FIN_ACC_CODE_3_ID='OUI'
	AND C.DIC_ACCOUNT_TYPE_ID='CG'
	and not exists (select 1
				    from hrm_allocation_detail d
					where DIC_ACCOUNT_TYPE_ID='DOC_RECORD'
					and c.hrm_allocation_id=d.hrm_allocation_id
					and c.ald_rate=d.ald_rate);

  Cursor CurDeleteDossier is
    SELECT
	e.hrm_allocation_id,
    e.all_code,
	e.all_descr,
	c.ald_rate
    FROM
    acs_account a,
	acs_financial_account b,
	hrm_allocation_detail c,
	hrm_allocation e
	where a.acs_account_id=b.acs_financial_account_id
	and a.acc_number=c.ALD_ACC_NAME
	and c.hrm_allocation_id=e.hrm_allocation_id
	and a.acs_account_id=main_id
	and nvl(b.DIC_FIN_ACC_CODE_3_ID,'NON')='NON'
	AND C.DIC_ACCOUNT_TYPE_ID='CG'
	and exists (select 1
				    from hrm_allocation_detail d
					where DIC_ACCOUNT_TYPE_ID='DOC_RECORD'
					and c.hrm_allocation_id=d.hrm_allocation_id
					and c.ald_rate=d.ald_rate);

   msg1 varchar2(2000);
   msg2 varchar2(2000);
   vCount1 number;
   vCount2 number;
   retour integer;
  begin
   vCount1 := 0;
   vCount2 := 0;
   msg1 := '';
   msg2 := '';

   for RowInsertDossier in CurInsertDossier
   loop
    msg1 := msg1||RowInsertDossier.all_code||' ('||RowInsertDossier.all_descr||')'||chr(10);

	insert into hrm_allocation_detail (
	HRM_ALLOCATION_ID,
	HRM_ALLOCATION_DETAIL_ID,
	HRM_BREAK_SHIFT_ID,
	DIC_ACCOUNT_TYPE_ID,
	ALD_RATE)
	select
	RowInsertDossier.HRM_ALLOCATION_ID,
	init_id_seq.nextval HRM_ALLOCATION_DETAIL_ID,
	(select max(HRM_BREAK_SHIFT_ID) from HRM_BREAK_SHIFT where brs_code='DOSSIER') HRM_BREAK_SHIFT_ID,
	'DOC_RECORD' DIC_ACCOUNT_TYPE_ID,
	RowInsertDossier.ALD_RATE
	from dual;
	commit;

    vCount1 := vCount1 + 1;
   end loop;

   for RowDeleteDossier in CurDeleteDossier
   loop
    msg2 := msg2||RowDeleteDossier.all_code||' ('||RowDeleteDossier.all_descr||')'||chr(10);

	delete from hrm_allocation_detail
	where
	hrm_allocation_id=RowDeleteDossier.hrm_allocation_id
	and ald_rate=RowDeleteDossier.ald_rate
	and DIC_ACCOUNT_TYPE_ID='DOC_RECORD';
	commit;

    vCount2 := vCount2 + 1;
   end loop;

    if vCount1=0 and vCount2=0
     then message := '';
      	  retour  :=  pcs.pc_ctrl_validate.e_success;
     else if vCount1>0
	      then message:= 'Le dossier a été ajouté aux méthodes de ventilations suivantes :'||chr(10)||chr(10)||
                         msg1;
		  	   retour :=pcs.pc_ctrl_validate.e_warning;
		   else if vCount2>0
     	   		then message:= 'Le dossier a été supprimé des méthodes de ventilations suivantes :'||chr(10)||chr(10)||
                     		   msg2;
		  			retour :=pcs.pc_ctrl_validate.e_warning;
		        end if;
           end if;
	 end if;

  RETURN retour;
    --dbms_output.put_line('OK');
  end update_dossier_allocation;

  function mise_a_plat(main_id IN NUMBER,context IN VARCHAR2,message OUT VARCHAR2) RETURN INTEGER
  --mise à plat des la classifications
  is
   cursor CurClassif is
   select
   classification_id
   from
   classification;

   retour integer;
   msg varchar2(2000);
   chk_classif integer;
   vCount integer;
  begin

  vCount := 0;

   for RowClassif in CurClassif
   loop
     CLA_FUNCTIONS.FLAT_CLASSIFICATION(RowClassif.classification_id);

     vCount := vCount + 1;
   end loop;

  message := 'Mise à plat des classifications effectuée';

    -- recherche si le compte créé est hors classification
    select count(*) into chk_classif
    from classif_flat
    where classif_leaf_id=main_id;

    if chk_classif = 0 and vCount > 0
    then message := 'Le compte créé n''entre dans aucune classification';
    end if;

  retour  :=  pcs.pc_ctrl_validate.e_warning;

  RETURN retour;

  end mise_a_plat;

end ind_acs_validation;
