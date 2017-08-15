--------------------------------------------------------
--  DDL for Package Body IND_ACT_VALIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_ACT_VALIDATION" 
is
  function ctrl_doc_record (ActDocId act_document.act_document_id%type) return varchar2
  -- Contrôle que le dossier a été saisi lorsqu'il est obligatoire sur un compte (Code libre 3 de la Gestion des comptes)
  is
   AccNumber acs_account.acc_number%type;
   retour varchar2(400);
  begin
    -- recherche compte sans dossier alors que le dossier est obligatoire
    SELECT
    max(acc_number) into AccNumber
    FROM
    ACT_FINANCIAL_IMPUTATION imp,
    act_document doc,
    acs_financial_account fin_acc,
    acs_account acs_acc
    where
    imp.act_document_id = doc.act_document_id
    and imp.acs_financial_account_id = fin_acc.ACS_FINANCIAL_ACCOUNT_ID
    and fin_acc.ACS_FINANCIAL_ACCOUNT_ID = acs_acc.acs_account_id
    and fin_acc.DIC_FIN_ACC_CODE_3_ID = 'OUI'
    and imp.doc_record_id is null
    and doc.ACT_DOCUMENT_ID = ActDocId;

    if AccNumber is null
     then retour := '';
     else retour:= 'Un dossier doit être renseigné pour le compte '||AccNumber||'[ABORT]';
  end if;

  return retour;
    --dbms_output.put_line('OK');
  end ctrl_doc_record;

  function ctrl_division (ActDocId act_document.act_document_id%type) return varchar2
  -- Contrôle que la division "A renseigner" a bien été remplacée lors de la saisie (Code libre 1 de la Gestion des comptes/divisions)
  is
   Cursor CurAcc is
    SELECT
    acs_acc.acc_number,
    acs_acc2.acc_number div_number,
    imp.imf_amount_lc_d,
    imp.imf_amount_lc_c
    FROM
    ACT_FINANCIAL_IMPUTATION imp,
    act_document doc,
    acs_financial_account fin_acc,
    acs_account acs_acc,
    acs_division_account div_acc,
    acs_account acs_acc2
    where
    imp.act_document_id = doc.act_document_id
    and imp.acs_financial_account_id = fin_acc.ACS_FINANCIAL_ACCOUNT_ID
    and fin_acc.ACS_FINANCIAL_ACCOUNT_ID = acs_acc.acs_account_id
    and imp.imf_acs_division_account_id=div_acc.acs_division_account_id
    and div_acc.acs_division_account_id=acs_acc2.acs_account_id
    and doc.ACT_DOCUMENT_ID = ActDocId
    -- Division à Remplacer: "E"
    and (div_acc.DIC_DIV_ACC_CODE_1_ID='01'
    -- Division obligatoire + Division "E00000"
        or (fin_acc.DIC_FIN_ACC_CODE_4_ID='OUI'
           and div_acc.DIC_DIV_ACC_CODE_1_ID='02')
         )
    ;

   msg varchar2(2000);
   vCount number;
   retour varchar2(2000);
  begin
   vCount := 0;
   msg := '';

   for RowAcc in CurAcc
   loop
    msg := msg||RowAcc.acc_number||chr(9)||RowAcc.div_number||chr(9)||RowAcc.imf_amount_lc_d||chr(9)||RowAcc.imf_amount_lc_c||chr(10);

    vCount := vCount + 1;
   end loop;

    if vCount = 0
     then retour := '';
     else retour:= 'La division des lignes suivantes doit être remplacée'||chr(10)||chr(10)||
                   'Comte / Division / Débit (MB) / Crédit (MB)'||chr(10)||
                    msg||'[ABORT]';
  end if;

  return retour;
    --dbms_output.put_line('OK');
  end ctrl_division;

end ind_act_validation;
