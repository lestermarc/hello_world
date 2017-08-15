--------------------------------------------------------
--  DDL for Package Body HRM_BREAK_TRANSFER_ITX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_BREAK_TRANSFER_ITX" 
is

 -- Cusor for accessing Break (HRM_BREAK) fields
  cursor csBreak(IdBreak number) is
    select * from hrm_break where hrm_break_id = IdBreak;
  -- Record for accessing Break's fields
  rBreak csBreak%rowtype;

procedure set_BreakData(vBreakId IN hrm_break.hrm_break_id%TYPE)
is
begin
  open csBreak(vBreakId);
  fetch csBreak into rBreak;
  close csBreak;
end set_BreakData;


 procedure break_transfert(BreakID hrm_break.hrm_break_id%type)
 is
  VACIDOCID  aci_document.aci_document_id%type;
  VFINCURRID acs_financial_currency.acs_financial_currency_id%type;
 begin
 -- SET de l'id
  HRM_BREAK_TRANSFER.SET_BREAKDATA (BreakID) ; -- le set se fait dans le package HRM_BREAK_TRANSFER

  -- SET de l'id
  HRM_BREAK_TRANSFER_ITX.SET_BREAKDATA (BreakID) ; -- le set se fait dans le package HRM_BREAK_TRANSFER_ITX


 -- Avant de commencer: contr�le que la ventilation est en d�finitif et n'a pas d�j� �t� transf�r�e
 if rBreak.brk_status=0
 then raise_application_error(-20001,'La ventilation est provisoire, impossible d''effectuer le transfert');
 else if rBreak.brk_status=2
      then raise_application_error(-20001,'La ventilation � d�j� �t� transfer�e');
	  end if;
 end if;

  -- Monnaie de base Finance
  select
  acs_function.GetLocalCurrencyId into VFINCURRID
  from dual;

  -- contr�le de la ventilation
  HRM_BREAKDOWN.ControlBreak(BreakID, 0); -- Le param�tre 0 fait que le contr�le ne bloque pas sur l'erreur
  									      --"employ� manquant dans la ventilation

  -- SET de l'id
  HRM_BREAK_TRANSFER.SET_BREAKDATA (BreakID) ; -- le set se fait dans le package HRM_BREAK_TRANSFER

  -- cr�ation du document d'interface
  HRM_BREAK_TRANSFER.ACI_DOC_CREATE (VFINCURRID,VACIDOCID) ; -- VACIDOCID = param�tre OUT

  -- cr�ation des imputations
  HRM_BREAK_TRANSFER_ITX.ACI_TRANSFERT (VACIDOCID,VFINCURRID,BreakID) ;

  -- mise � jour des id des comptes
  HRM_BREAK_TRANSFER.ACI_UPDATEACCOUNTID (VACIDOCID) ;

  -- cr�ation du statut
  HRM_BREAK_TRANSFER.ACI_DOCSTATUS_CREATE (VACIDOCID) ;

  -- mise � jour du statut de la ventilation: Transf�r�
  update HRM_BREAK
  set BRK_STATUS = 2, A_DATEMOD = sysdate
  where
  hrm_break_id=BreakID;

  --dbms_OutPut.put_line('OK');
 end break_transfert;

procedure Aci_Transfert(vAciDocId IN aci_document.aci_document_id%TYPE,
 		   				vFinCurrId IN acs_financial_currency.acs_financial_currency_id%TYPE,
						vBreakID hrm_break.hrm_break_id%type) -- *MODIF* ajout� pour pouvoir "setter"
is
  cursor csToTransfert(pcBreakId hrm_break.hrm_break_id%TYPE, pcSameCurr number) is
  select  -- *MODIF* le curseur pointe sur aune nouvelle vue et retourne les champs en devise
    *
  from
    v_ind_hrm_break_cgan_grp
  where
    hrm_break_id = pcBreakId;

  rToTransfert csToTransfert%rowtype;
  AciImputationId aci_financial_imputation.aci_financial_imputation_id%TYPE;
  DefAccount aci_financial_imputation.acc_number%TYPE;
  eNoPrimary exception;
  nSameCurr number;
  strFinCurrName pcs.pc_curr.currency%TYPE;
  strBasicCurrName pcs.pc_curr.currency%TYPE;
  vImfDescr aci_financial_imputation.imf_description%TYPE; -- *MODIF* ajout� pour stocker le libell�
begin
  -- Initialisation des monnaies
  strBasicCurrName := acs_function.getCurrencyName(rBreak.acs_financial_currency_id);
  if rBreak.acs_financial_currency_id = vFinCurrID then
    nSameCurr := 1;
    strFinCurrName := strBasicCurrName;
  else
    nSameCurr := 0;
    strFinCurrName := acs_function.getCurrencyName(vFinCurrID);
  end if;

  -- 1.Ovrir un curseur sur la vue V_HRM_BREAK_CGAN_GRP (filtr� sur HRM_BREAK_ID)
  --   qui nous retourne les �critures CG et AN � transf�rer.
  open csToTransfert(rBreak.hrm_break_id, nSameCurr);
  loop
    fetch csToTransfert into rToTransfert;
    exit when csToTransfert%notfound;
    -- 2.Pour chaque "FETCH" de ces lignes,
    --   a) on cr�� une �criture financi�re dans ACI_FINANCIAL_IMPUTATION
    AciImputationId := 0;

/* Le libell� est d�sormais retourn� dans la vue
  -- *MODIF* ajout� pour stocker le libell�
	select max(to_char(rBreak.brk_value_date,'YYYY.MM')||' '||rToTransfert.div_number||' '||per_search_name)
	       into vImfDescr
	from hrm_person
	where emp_number=rToTransfert.div_number;
*/
    select aci_id_seq.nextval into AciImputationId from dual;
    insert into aci_financial_imputation
        (aci_financial_imputation_id,
         aci_document_id,
         imf_type,
         imf_genre,
         imf_primary,
         imf_description,
         imf_amount_lc_d,
         imf_amount_lc_c,
         imf_exchange_rate,
         imf_base_price,
         imf_amount_fc_d,
         imf_amount_fc_c,
         imf_transaction_date,
         imf_value_date,
         currency1,
         acs_financial_currency_id,
         currency2,
         acs_acs_financial_currency_id,
         acc_number,
         div_number,
         imf_number,
         imf_number2,
         imf_number3,
         imf_number4,
         imf_text1,
         imf_text2,
         imf_text3,
         imf_text4,
         rco_title,
         DIC_IMP_FREE1_ID,
         c_genre_transaction,
         a_datecre,
         a_idcre)
    values
        (AciImputationId,
         vAciDocId,
         'MAN',
         'STD',
         0,
         rToTransfert.ele_descr, --vImfDescr, -- *MODIF* au lieu de rbreak.brk_description,
         rToTransfert.ldebit_amount,
         rToTransfert.lcredit_amount,
         decode(rToTransfert.currency2,strFinCurrName,null,rToTransfert.rate2), -- *MODIF* au lieu de 0,
         decode(rToTransfert.currency2,strFinCurrName,null,1),
         decode(rToTransfert.currency2,strFinCurrName,null,rToTransfert.fdebit_amount),
         decode(rToTransfert.currency2,strFinCurrName,null,rToTransfert.fcredit_amount),
         rBreak.brk_document_cgdate,
         rBreak.brk_value_date,
         -- Monnaie de base RH
         rToTransfert.currency2, -- *MODIF* au lieu de strBasicCurrName,
         rToTransfert.acs_financial_currency_id2, -- *MODIF* rBreak.acs_financial_currency_id,
         -- Monnaie de base FIN
         strFinCurrName,
         vFinCurrId,
         rToTransfert.cg_number,
         rToTransfert.div_number,
         To_Number(rToTransfert.number1),
         To_Number(rToTransfert.number2),
         To_Number(rToTransfert.number3),
         To_Number(rToTransfert.number4),
         rToTransfert.text1,
         rToTransfert.text2,
         rToTransfert.text3,
         rToTransfert.text4,
         rToTransfert.rco_title,
         rToTransfert.DIC_DEPARTMENT_ID,
         '1',
         SysDate,
         pcs.pc_public.GetUserIni);

    -- b) Ecriture analytique dans ACI_MGM_IMPUTATION (si CPN Not Null)
    if rToTransfert.cpn_number is not null then
      insert into aci_mgm_imputation
         (aci_mgm_imputation_id,
          aci_document_id,
          aci_financial_imputation_id,
          imm_type,
          imm_genre,
          imm_primary,
          imm_description,
          imm_amount_lc_d,
          imm_amount_lc_c,
          imm_amount_fc_d,
          imm_amount_fc_c,
          imm_value_date,
          imm_transaction_date,
          currency1,
          acs_financial_currency_id,
          currency2,
          acs_acs_financial_currency_id,
          cda_number,
          cpn_number,
          pf_number,
          pj_number,
          imm_number,
          imm_number2,
          imm_number3,
          imm_number4,
          imm_text1,
          imm_text2,
          imm_text3,
          imm_text4,
          rco_title,
          per_no_period,
          a_datecre,
          a_idcre)
      values
          (aci_id_seq.nextval,
           vAciDocId,
           AciImputationId,
           'MAN',
           'STD',
           null,
           rBreak.brk_description,
           rToTransfert.ldebit_amount,
           rToTransfert.lcredit_amount,
           rToTransfert.fdebit_amount,
           rToTransfert.fcredit_amount,
           rBreak.brk_value_date,
           rBreak.brk_document_cgdate,
           -- Monnaie de base RH
           strBasicCurrName,
           rBreak.acs_financial_currency_id,
           -- Monnaie de base FIN
           strFinCurrName,
           vFinCurrId,
           rToTransfert.cda_number,
           rToTransfert.cpn_number,
           rToTransfert.pf_number,
           rToTransfert.pj_number,
           To_Number(rToTransfert.number1),
           To_Number(rToTransfert.number2),
           To_Number(rToTransfert.number3),
           To_Number(rToTransfert.number4),
           rToTransfert.text1,
           rToTransfert.text2,
           rToTransfert.text3,
           rToTransfert.text4,
           rToTransfert.rco_title,
           null,
           SysDate,
           pcs.pc_public.GetUserIni);
    end if;
  end loop;
  close csToTransfert;

  -- 3. Mise � jour de l'�criture primaire
  -- Recherche du compte de base
  select min(b.sab_account_name) into DefAccount
  from hrm_salary_breakdown b, hrm_elements e
  where b.hrm_break_id = rBreak.hrm_break_id and
    b.dic_account_type_id = 'CG' and
    b.hrm_elements_id = e.hrm_elements_id and
    e.ele_code = 'CemMontantPaye';

  -- Si on a pas trouv�, recherche du plus petit ACC_NUMBER
  if DefAccount is null then
    select min(acc_number) into DefAccount
    from aci_financial_imputation
    where aci_document_id = vAciDocId;
    if DefAccount is null then
      raise eNoPrimary;
    end if;
  end if;
  -- Mise � jour de l'�criture primaire
  update aci_financial_imputation set imf_primary = 1
  where aci_financial_imputation_id =
      (select min(aci_financial_imputation_id)
       from aci_financial_imputation
       where aci_document_id = vAciDocId and
         acc_number = DefAccount);
  exception
    when eNoPrimary then
    begin
      raise_application_error(-20064,'PCS-'||pcs.pc_functions.TranslateWord('Erreur lors de la mise � jour de l''�criture primaire.'));
      rollback;
    end;
    when others then
    begin
      raise_application_error(-20065,'PCS-'||pcs.pc_functions.TranslateWord('Impossible de transf�rer la ventilation.'));
      rollback;
    end;
end Aci_Transfert;

function transfert_validation (main_id in number, context in varchar2, message out varchar2) return integer
   /* Proc�dure de validation dans l'objet Ventilation qui remplace le bouton "Transfert en comptabilit�"
   * Le d�clanchement se fait via Gestion des indiv/Contr�le de validations globales
   * La ventilation est transf�r�e � la validation si:
   *    Le statut = 1 (BRK_STATUS)
   *    Les champs Num�ro de document Transfert CG et Date comptabilisation <> NULL (BRK_DOCUMENT_CG, BRK_DOCUMENT_CGDATE)
   *    La config soci�t� HRM_BREAK_TARGET = 0 (vers la comptabilit� ProConcept)
   */

   is
    retour integer;
    DocName HRM_BREAK.BRK_DOCUMENT_CG%type;
    DocDate HRM_BREAK.BRK_DOCUMENT_CGDATE%type;
    BreakStatus HRM_BREAK.BRK_STATUS%type;
    ConfigValue PCS.PC_COCOM.COCOCVAL%type;
   begin
    -- Donn�es de la ventilation
    select
    brk_document_cg, brk_document_cgdate, brk_status
    into DocName, DocDate, BreakStatus
    from
    hrm_break
    where
    hrm_break_id=main_id;

    -- Config soci�t�
    select
    a.cococval into ConfigValue
    from
    pcs.pc_cocom a,
    pcs.pc_cbase b
    where
    a.pc_cbase_id=b.pc_cbase_id
    and b.cbacname='HRM_BREAK_TARGET'
    and pc_comp_id=PCS.PC_INIT_SESSION.GetCompanyId;

    --tests
    --message := 'Doc: '||nvl(DocName,'null')||' / Date: '||nvl(to_char(DocDate,'DD.MM.YYYY'),'null')||' / Statut: '||nvl(to_char(BreakStatus),'null')||' / Config: '||nvl(ConfigValue,'null');
    --retour  :=  pcs.pc_ctrl_validate.e_warning;

    if DocName is not null
       and DocDate is not null
       and BreakStatus=1
       and ConfigValue='0'
    then -- lancement de la proc�dure de transfert
         hrm_break_transfer_itx.break_transfert(main_id);
         commit;
         message := 'La ventilation � �t� transf�r�e en comptabilit�';
         retour  :=  pcs.pc_ctrl_validate.e_warning;
    else message := '';
         retour  :=  pcs.pc_ctrl_validate.e_success;
    end if;

    RETURN retour;

   end transfert_validation;

end hrm_break_transfer_itx;
