--------------------------------------------------------
--  DDL for Package Body CML_CONTRACT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "CML_CONTRACT_FUNCTIONS" 
is
  /**
  * Description
  *    Cr�ation des positions d'un nouveau contrat � partir des positions du mod�le
  */
  procedure DuplicatePosition(
    aNewContractID in     CML_DOCUMENT.CML_DOCUMENT_ID%type
  , aSrcPosID      in     CML_POSITION.CML_POSITION_ID%type
  , aCopyModel     in     number
  , aCpyOnlyOnePos in     number default 0
  , aNewPosID      in out CML_POSITION.CML_POSITION_ID%type
  )
  is
    vNewPosServiceID CML_POSITION_SERVICE.CML_POSITION_SERVICE_ID%type;
    vNewDetailID     CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type;
    vNewPosMachineID CML_POSITION_MACHINE.CML_POSITION_MACHINE_ID%type;
    ltplPos          CML_POSITION%rowtype;
    lnSrcContractID  CML_DOCUMENT.CML_DOCUMENT_ID%type;
  begin
    -- ID de la nouvelle position
    if nvl(aNewPosID, 0) = 0 then
      select init_id_seq.nextval
        into aNewPosID
        from dual;
    end if;

    -- ID du contrat de la position source
    lnSrcContractID                        := FWK_I_LIB_ENTITY.getNumberFieldFromPk('CML_POSITION', 'CML_DOCUMENT_ID', aSrcPosID);

    -- Copie toutes les donn�es de la position source
    select *
      into ltplPos
      from CML_POSITION
     where CML_POSITION_ID = aSrcPosID;

    -- Initialiser les donn�es de la nouvelle position
    ltplPos.CML_POSITION_ID                := aNewPosID;
    ltplPos.CML_DOCUMENT_ID                := aNewContractID;
    ltplPos.C_CML_POS_STATUS               := '01';

    -- Reprendre le lien sur la position mod�le si en copie pour cr�ation de mod�le
    --   Si pas en copie de mod�le, laisser le lien vers un �ventuel mod�le de la position source
    --    (ne rien faire car c'est d�j� repris dans le select de copie ci-dessus)
    if FWK_I_LIB_ENTITY.getNumberFieldFromPk('CML_DOCUMENT', 'CCO_MODEL', lnSrcContractID) = 1 then
      ltplPos.CML_CML_POSITION_ID  := aSrcPosID;
    end if;

    -- Copie d'une position -> N� s�quence
    if (aCpyOnlyOnePos = 1) then
      select max(CPO_SEQUENCE) + PCS.PC_CONFIG.GetConfig('CML_POSITION_INCREMENT')
        into ltplPos.CPO_SEQUENCE
        from CML_POSITION
       where CML_DOCUMENT_ID = aNewContractID;
    end if;

    -- Copie de plusieurs positions
    if (aCpyOnlyOnePos = 0) then
      -- Date de conclusion du contrat init avec la date initiale du contrat
      select CCO_INITDATE
        into ltplPos.CPO_CONCLUSION_DATE
        from CML_DOCUMENT
       where CML_DOCUMENT_ID = aNewContractID;

      -- Date de mise en service
      ltplPos.CPO_BEGIN_SERVICE_DATE  := null;
    end if;

    -- Ne pas reprendre les procs si pas en copie de mod�le (En vue de cr�er un nouveau mod�le)
    if FWK_I_LIB_ENTITY.getNumberFieldFromPk('CML_DOCUMENT', 'CCO_MODEL', aNewContractID) = 0 then
      ltplPos.CPO_PROC_BEFORE_VALIDATE    := null;
      ltplPos.CPO_PROC_AFTER_VALIDATE     := null;
      ltplPos.CPO_PROC_BEFORE_EDIT        := null;
      ltplPos.CPO_PROC_AFTER_EDIT         := null;
      ltplPos.CPO_PROC_BEFORE_DELETE      := null;
      ltplPos.CPO_PROC_AFTER_DELETE       := null;
      ltplPos.CPO_PROC_BEFORE_ACTIVATE    := null;
      ltplPos.CPO_PROC_AFTER_ACTIVATE     := null;
      ltplPos.CPO_PROC_BEFORE_HOLD        := null;
      ltplPos.CPO_PROC_AFTER_HOLD         := null;
      ltplPos.CPO_PROC_BEFORE_REACTIVATE  := null;
      ltplPos.CPO_PROC_AFTER_REACTIVATE   := null;
      ltplPos.CPO_PROC_BEFORE_CANCEL      := null;
      ltplPos.CPO_PROC_AFTER_CANCEL       := null;
      ltplPos.CPO_PROC_BEFORE_END         := null;
      ltplPos.CPO_PROC_AFTER_END          := null;
    end if;

    -- Vider certaines donn�es de la position source
    ltplPos.CPO_POSITION_AMOUNT            := 0;
    ltplPos.CPO_BEGIN_CONTRACT_DATE        := null;
    ltplPos.CPO_END_CONTRACT_DATE          := null;
    ltplPos.CPO_END_EXTENDED_DATE          := null;
    ltplPos.CPO_RESILIATION_DATE           := null;
    ltplPos.CPO_SUSPENSION_DATE            := null;
    ltplPos.CPO_EFFECTIV_END_DATE          := null;
    ltplPos.CPO_FIRST_POSITION_DATE        := null;
    ltplPos.CPO_LAST_POSITION_DATE         := null;
    ltplPos.CPO_NEXT_DATE                  := null;
    ltplPos.CPO_LAST_PERIOD_BEGIN          := null;
    ltplPos.CPO_LAST_PERIOD_END            := null;
    ltplPos.CPO_EXTENSION_TIME             := null;
    ltplPos.CPO_PC_USER_ID                 := null;
    ltplPos.DIC_CML_RESILIATION_DEMAND_ID  := null;
    ltplPos.DIC_CML_RESILIATION_REASON_ID  := null;
    ltplPos.DIC_CML_SUSPENSION_REASON_ID   := null;
    ltplPos.CPO_EXT_PERIOD_NB_DONE         := null;
    ltplPos.CPO_EFFECTIV_MONTHES           := null;
    ltplPos.CPO_PROTECTED                  := 0;
    ltplPos.CML_INVOICING_JOB_ID           := null;
    ltplPos.CPO_SESSION_ID                 := null;
    -- A_CONFIRM : permet de ne pas passer dans le trigger d'insertion CML_CPO_AI_PROCESSING
    ltplPos.A_CONFIRM                      := 1;
    ltplPos.A_DATECRE                      := sysdate;
    ltplPos.A_IDCRE                        := pcs.PC_I_LIB_SESSION.GetUserIni;
    ltplPos.A_DATEMOD                      := null;
    ltplPos.A_IDMOD                        := null;

    -- Nouvelle position
    insert into CML_POSITION
         values ltplPos;

    -- Copie des codes de traitement de la position d'origine
    insert into CML_PROCESSING
                (CML_PROCESSING_ID
               , CML_POSITION_ID
               , C_CML_PROCESSING_TYPE
               , CPR_JANUARY
               , CPR_FEBRUARY
               , CPR_MARCH
               , CPR_APRIL
               , CPR_MAY
               , CPR_JUNE
               , CPR_JULY
               , CPR_AUGUST
               , CPR_SEPTEMBER
               , CPR_OCTOBER
               , CPR_NOVEMBER
               , CPR_DECEMBER
               , A_DATECRE
               , A_IDCRE
                )
      select init_id_seq.nextval
           , aNewPosID
           , C_CML_PROCESSING_TYPE
           , CPR_JANUARY
           , CPR_FEBRUARY
           , CPR_MARCH
           , CPR_APRIL
           , CPR_MAY
           , CPR_JUNE
           , CPR_JULY
           , CPR_AUGUST
           , CPR_SEPTEMBER
           , CPR_OCTOBER
           , CPR_NOVEMBER
           , CPR_DECEMBER
           , sysdate   -- A_DATECRE
           , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from CML_PROCESSING
       where CML_POSITION_ID = aSrcPosID;

    update CML_POSITION
       set A_CONFIRM = null
     where CML_POSITION_ID = aNewPosID;

    -- Copie des prestations de la position du mod�le
    for cr_PosService in (select CML_POSITION_SERVICE_ID
                               , GCO_CML_SERVICE_ID
                               , CPS_LONG_DESCRIPTION
                               , CPS_FREE_DESCRIPTION
                            from CML_POSITION_SERVICE
                           where CML_POSITION_ID = aSrcPosID) loop
      -- ID de la nouvelle association Avenant/Prestation
      select init_id_seq.nextval
        into vNewPosServiceID
        from dual;

      -- Copie de l'association
      insert into CML_POSITION_SERVICE
                  (CML_POSITION_SERVICE_ID
                 , CML_POSITION_ID
                 , GCO_CML_SERVICE_ID
                 , CPS_LONG_DESCRIPTION
                 , CPS_FREE_DESCRIPTION
                 , A_DATECRE
                 , A_IDCRE
                 , A_CONFIRM
                  )
           values (vNewPosServiceID   -- CML_POSITION_SERVICE_ID
                 , aNewPosID   -- CML_POSITION_ID
                 , cr_PosService.GCO_CML_SERVICE_ID
                 , cr_PosService.CPS_LONG_DESCRIPTION
                 , cr_PosService.CPS_FREE_DESCRIPTION
                 , sysdate   -- A_DATECRE
                 , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                 , 1   -- A CONFIRM : permet de ne pas passer dans le trigger d'insertion CML_CPS_AI_DETAIL
                  );

      update CML_POSITION_SERVICE
         set A_CONFIRM = null
       where CML_POSITION_SERVICE_ID = vNewPosServiceID;

      -- Copie des d�tails de prestation
      for cr_Detail in (select *
                          from CML_POSITION_SERVICE_DETAIL
                         where CML_POSITION_SERVICE_ID = cr_PosService.CML_POSITION_SERVICE_ID) loop
        -- ID du nouveau d�tail
        select init_id_seq.nextval
          into vNewDetailID
          from dual;

        -- Copie du d�tail de la prestation
        insert into CML_POSITION_SERVICE_DETAIL
                    (CML_POSITION_SERVICE_DETAIL_ID
                   , CML_POSITION_SERVICE_ID
                   , GCO_GOOD_ID
                   , ASA_COUNTER_TYPE_ID
                   , C_SERVICE_RENEWAL
                   , C_CML_TIME_UNIT
                   , DIC_TARIFF_ID
                   , CPD_SQL_CONDITION
                   , CPD_RENEWABLE_QTY
                   , CPD_PERIOD_QTY
                   , CPD_CONSUMED_QTY
                   , CPD_BALANCE_QTY
                   , CPD_EXPIRY_DATE
                   , CPD_PRORATA
                   , CPD_UNIT_VALUE
                   , A_DATECRE
                   , A_IDCRE
                   , A_CONFIRM
                    )
             values (vNewDetailID   -- CML_POSITION_SERVICE_DETAIL_ID
                   , vNewPosServiceID   -- CML_POSITION_SERVICE_ID
                   , cr_Detail.GCO_GOOD_ID
                   , cr_Detail.ASA_COUNTER_TYPE_ID
                   , cr_Detail.C_SERVICE_RENEWAL
                   , cr_Detail.C_CML_TIME_UNIT
                   , cr_Detail.DIC_TARIFF_ID
                   , cr_Detail.CPD_SQL_CONDITION
                   , cr_Detail.CPD_RENEWABLE_QTY
                   , cr_Detail.CPD_PERIOD_QTY
                   , cr_Detail.CPD_CONSUMED_QTY
                   , cr_Detail.CPD_BALANCE_QTY
                   , cr_Detail.CPD_EXPIRY_DATE
                   , cr_Detail.CPD_PRORATA
                   , cr_Detail.CPD_UNIT_VALUE
                   , sysdate   -- A_DATECRE
                   , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                   , 1   -- A CONFIRM : permet de ne pas passer dans le trigger d'insertion CML_CPD_AI_PROCESSING
                    );

        update CML_POSITION_SERVICE_DETAIL
           set A_CONFIRM = null
         where CML_POSITION_SERVICE_DETAIL_ID = vNewDetailID;

        -- Copie des codes de traitement du d�tail
        insert into CML_PROCESSING
                    (CML_PROCESSING_ID
                   , C_CML_PROCESSING_TYPE
                   , CML_POSITION_SERVICE_DETAIL_ID
                   , CPR_JANUARY
                   , CPR_FEBRUARY
                   , CPR_MARCH
                   , CPR_APRIL
                   , CPR_MAY
                   , CPR_JUNE
                   , CPR_JULY
                   , CPR_AUGUST
                   , CPR_SEPTEMBER
                   , CPR_OCTOBER
                   , CPR_NOVEMBER
                   , CPR_DECEMBER
                   , A_DATECRE
                   , A_IDCRE
                    )
          select init_id_seq.nextval
               , C_CML_PROCESSING_TYPE
               , vNewDetailID   -- CML_POSITION_SERVICE_DETAIL_ID
               , CPR_JANUARY
               , CPR_FEBRUARY
               , CPR_MARCH
               , CPR_APRIL
               , CPR_MAY
               , CPR_JUNE
               , CPR_JULY
               , CPR_AUGUST
               , CPR_SEPTEMBER
               , CPR_OCTOBER
               , CPR_NOVEMBER
               , CPR_DECEMBER
               , sysdate   -- A_DATECRE
               , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
            from CML_PROCESSING
           where CML_POSITION_SERVICE_DETAIL_ID = cr_Detail.CML_POSITION_SERVICE_DETAIL_ID;

        -- Copie de la structure de ventilation du d�tail
        insert into CML_PRICE_STRUCTURE
                    (CML_PRICE_STRUCTURE_ID
                   , CML_POSITION_SERVICE_DETAIL_ID
                   , C_CML_STRUCTURE_CODE
                   , GCO_GOOD_ID
                   , PST_WEIGHT
                   , A_DATECRE
                   , A_IDCRE
                    )
          select init_id_seq.nextval
               , vNewDetailID
               , C_CML_STRUCTURE_CODE
               , GCO_GOOD_ID
               , PST_WEIGHT
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GETUSERINI   -- A_IDCRE
            from CML_PRICE_STRUCTURE
           where CML_POSITION_SERVICE_DETAIL_ID = cr_Detail.CML_POSITION_SERVICE_DETAIL_ID;
      end loop;
    end loop;

    -- Copie des installations de la position du mod�le
    for cr_PosMachine in (select CML_POSITION_MACHINE_ID
                               , DOC_RCO_MACHINE_ID
                               , CPM_WEIGHT
                            from CML_POSITION_MACHINE
                           where CML_POSITION_ID = aSrcPosID) loop
      -- ID de la nouvelle association Avenant/Prestation
      select init_id_seq.nextval
        into vNewPosMachineID
        from dual;

      insert into CML_POSITION_MACHINE
                  (CML_POSITION_MACHINE_ID
                 , CML_POSITION_ID
                 , DOC_RCO_MACHINE_ID
                 , CPM_WEIGHT
                 , A_DATECRE
                 , A_IDCRE
                 , A_CONFIRM
                  )
           values (vNewPosMachineID
                 , aNewPosID
                 , cr_PosMachine.DOC_RCO_MACHINE_ID
                 , cr_PosMachine.CPM_WEIGHT
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GETUSERINI   -- A_IDCRE
                 , 1   -- A CONFIRM : permet de ne pas passer dans le trigger d'insertion CML_CPM_AI_DETAIL
                  );

      -- le d�tail des installations est cr�� dans le trigger CML_CPM_AI_DETAIL
      -- mise � jour des �tats compteurs du d�tail des installations selon �tat compteur
      update CML_POSITION_MACHINE
         set A_CONFIRM = null
       where CML_POSITION_MACHINE_ID = vNewPosMachineID;

      insert into CML_POSITION_MACHINE_DETAIL
                  (CML_POSITION_MACHINE_DETAIL_ID
                 , CML_POSITION_MACHINE_ID
                 , ASA_COUNTER_ID
                 , CMD_INITIAL_STATEMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , vNewPosMachineID
             , COU.ASA_COUNTER_ID
             , (select nvl(CMD_LAST_INVOICE_STATEMENT, CMD_INITIAL_STATEMENT)
                  from CML_POSITION_MACHINE_DETAIL
                 where CML_POSITION_MACHINE_ID = cr_PosMachine.CML_POSITION_MACHINE_ID
                   and ASA_COUNTER_ID = COU.ASA_COUNTER_ID)   -- CMD_INITIAL_STATEMENT
             , sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni
          from ASA_COUNTER COU
         where COU.DOC_RECORD_ID = cr_PosMachine.DOC_RCO_MACHINE_ID;
    end loop;

    -- Copie de la structure de ventilation de la position source
    insert into CML_PRICE_STRUCTURE
                (CML_PRICE_STRUCTURE_ID
               , CML_POSITION_ID
               , C_CML_STRUCTURE_CODE
               , GCO_GOOD_ID
               , PST_WEIGHT
               , A_DATECRE
               , A_IDCRE
                )
      select init_id_seq.nextval
           , aNewPosID
           , C_CML_STRUCTURE_CODE
           , GCO_GOOD_ID
           , PST_WEIGHT
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GETUSERINI   -- A_IDCRE
        from CML_PRICE_STRUCTURE
       where CML_POSITION_ID = aSrcPosId;
  end DuplicatePosition;

  /**
  * Description
  *    Contr�le de coh�rence des codes de traitement de l'avenant
  */
  function CtrlProcessCode(aPositionID in CML_POSITION.CML_POSITION_ID%type)
    return number
  is
    vResult number;
  begin
    select sign(count(*) )
      into vResult
      from CML_POSITION CPO
         , CML_PROCESSING CPR_DET
         , CML_PROCESSING CPR_POS
         , CML_POSITION_SERVICE CPS
         , CML_POSITION_SERVICE_DETAIL CPD
     where CPO.CML_POSITION_ID = aPositionID
       and nvl(CPO.C_CML_POS_TREATMENT, '00') <> '00'
       and CPR_DET.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID
       and CPS.CML_POSITION_SERVICE_ID = CPD.CML_POSITION_SERVICE_ID
       and CPR_POS.CML_POSITION_ID = CPO.CML_POSITION_ID
       and CPS.CML_POSITION_ID = CPO.CML_POSITION_ID
       and CPR_DET.C_CML_PROCESSING_TYPE = '200'
       and CheckList(CPR_DET.CPR_MONTHS, CPR_POS.CPR_MONTHS, ',') = 0;

    return vResult;
  end CtrlProcessCode;

  /**
  * Description
  *    Protection ou d�protection de la position d'un contrat dans une transaction autonome
  */
  procedure PositionProtect_AutoTrans(
    iPositionID in     number
  , iProtect    in     number
  , iSessionID  in     varchar2 default null
  , iShowError  in     number default 1
  , iInvJobID   in     number default null
  , oUpdated    out    number
  )
  is
    pragma autonomous_transaction;
    lPositionId CML_POSITION.CML_POSITION_ID%type;
    lSessionId  CML_POSITION.CPO_SESSION_ID%type;
    lProtected  CML_POSITION.CPO_PROTECTED%type;
  begin
    if iProtect = 1 then
      -- teste si la position n'est pas d�j� prot�g�e par quelqu'un d'autre
      select CML_POSITION_ID
        into lPositionId
        from CML_POSITION
       where CML_POSITION_ID = iPositionId
         and not(    CPO_SESSION_ID <> iSessionId
                 and nvl(CPO_PROTECTED, 0) = 1
                 and iProtect = 1);

      select CML_POSITION_ID
        into lPositionId
        from CML_POSITION
       where CML_POSITION_ID = iPositionId
         and CML_INVOICING_JOB_ID is null;

      declare
        lPositionId CML_POSITION.CML_POSITION_ID%type;
      begin
        -- teste si la position n'est pas d�j� dans l'�tat que l'on demande
        select CML_POSITION_ID
          into lPositionId
          from CML_POSITION
         where CML_POSITION_ID = iPositionId
           and nvl(CPO_PROTECTED, 0) <> 1;

        /* M�j du flag de protection de la position */
        update CML_POSITION
           set CPO_PROTECTED = 1
             , CPO_SESSION_ID = iSessionID
             , CML_INVOICING_JOB_ID = iInvJobID
         where CML_POSITION_ID = iPositionID;
      exception
        when no_data_found then
          null;
      end;

      oUpdated  := 1;
    else
      -- teste si la position n'est pas d�j� prot�g�e par quelqu'un d'autre
      select CML_POSITION_ID
           , CPO_SESSION_ID
           , CPO_PROTECTED
        into lPositionId
           , lSessionId
           , lProtected
        from CML_POSITION
       where CML_POSITION_ID = iPositionId;

      if lSessionId = iSessionId then
        -- position prot�g�e par la session en cours
        oUpdated  := 1;
      elsif COM_FUNCTIONS.Is_Session_Alive(lSessionId) = 0 then
        -- d�protection manuelle (outil de d�protection) d'une position dont la session n'est pas vivante
        oUpdated  := 1;
      elsif     lProtected = 0
            and lSessionId is null then
        -- position d�j� d�prot�g�e
        oUpdated  := 0;
      else
        if iShowError = 1 then
          raise_application_error
                                 (-20000
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Vous essayez de d�prot�ger une position qui a �t� prot�g�e par un autre utilisateur.')
                                 );
        else
          oUpdated  := 0;
        end if;
      end if;

      if oUpdated = 1 then
        /* M�j du flag de protection de la position */
        update CML_POSITION
           set CPO_PROTECTED = 0
             , CPO_SESSION_ID = null
             , CML_INVOICING_JOB_ID = iInvJobID
         where CML_POSITION_ID = iPositionID;
      end if;
    end if;

    commit;   /* Car on utilise une transaction autonome */
  exception
    when no_data_found then
      if iShowError = 1 then
        if iProtect = 1 then
          raise_application_error
                                (-20000
                               , PCS.PC_FUNCTIONS.TranslateWord('PCS - Vous essayez de prot�ger une position qui est d�j� prot�g�e par un autre utilisateur.')
                                );
        else
          raise_application_error
                                 (-20000
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Vous essayez de d�prot�ger une position qui a �t� prot�g�e par un autre utilisateur.')
                                 );
        end if;
      else
        oUpdated  := 0;
      end if;
  end PositionProtect_AutoTrans;

  /**
  * Description
  *    Indique si la position est prot�g�e ou non
  */
  procedure isPositionProtect(iPositionID number, iSessionID varchar2 default null, oProtect out number)
  is
  begin
    -- �tat de la protection de la position en excluant le verrouillage par la
    -- session fournie
    select 1
      into oProtect
      from CML_POSITION
     where CML_POSITION_ID = iPositionId
       and CPO_SESSION_ID <> iSessionId
       and CPO_PROTECTED = 1;
  exception
    when no_data_found then
      oProtect  := 0;
  end isPositionProtect;

  /**
  * Description
  *   Mise � jour des avoirs de prestation apr�s activation de la position
  */
  procedure ServiceRenewalAfterActivate(aPositionID in CML_POSITION.CML_POSITION_ID%type)
  is
    vCPD_PERIOD_QTY    CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vCOEFF             CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vNextRenewalPeriod date;
  begin
    for tplService in (select CPD.CML_POSITION_SERVICE_DETAIL_ID
                            , nvl(CPD.CPD_RENEWABLE_QTY, 0) CPD_RENEWABLE_QTY
                            , CPD.CPD_PERIOD_QTY
                            , CPD.CPD_PRORATA
                            , CPD.C_CML_TIME_UNIT
                            , CPD.CPD_EXPIRY_DATE
                            , CPO.CPO_BEGIN_CONTRACT_DATE
                            , CPO.CPO_END_CONTRACT_DATE
                            , CPO.CPO_END_EXTENDED_DATE
                            , SER.GOO_NUMBER_OF_DECIMAL
                         from CML_POSITION_SERVICE_DETAIL CPD
                            , CML_POSITION_SERVICE CPS
                            , CML_POSITION CPO
                            , CML_PROCESSING CPR
                            , GCO_GOOD SER
                        where CPD.CML_POSITION_SERVICE_ID = CPS.CML_POSITION_SERVICE_ID
                          and CPS.CML_POSITION_ID = CPO.CML_POSITION_ID
                          and CPO.CML_POSITION_ID = aPositionID
                          and CPR.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID
                          and CPR.C_CML_PROCESSING_TYPE = '200'
                          and CPS.GCO_CML_SERVICE_ID = SER.GCO_GOOD_ID
                          and SER.C_SERVICE_KIND in('1', '2', '4')
                          and CPD.C_SERVICE_RENEWAL <> '3') loop
      -- Rechercher la date d�but de la prochaine p�riode de renouvellement
      vNextRenewalPeriod  :=
             GetRenewalPeriodDate(aDate              => tplService.CPO_BEGIN_CONTRACT_DATE, aServiceDetailID => tplService.CML_POSITION_SERVICE_DETAIL_ID
                                , aBackPeriod        => 0);
      -- Calcul de la date du prochain renouvellement ou fin de contrat ou fin prolong. contrat
      vNextRenewalPeriod  := least(vNextRenewalPeriod, nvl(tplService.CPO_END_EXTENDED_DATE, tplService.CPO_END_CONTRACT_DATE) + 1);

      if tplService.CPD_PRORATA = 1 then
        -- Unit� prorata = Jour
        vCOEFF           := CmlMonthsBetween(tplService.CPO_BEGIN_CONTRACT_DATE, vNextRenewalPeriod);

        -- Unit� prorata = Mois
        --  Utilisation de la fonction CmlMonthsBetween pour trouver les mois entre les 2 p�riodes
        --  Pour la date de d�part on va toujours prendre le 1er du mois
        if tplService.C_CML_TIME_UNIT = '2' then
          vCOEFF  := ceil(vCOEFF);
        end if;

        -- Qt� p�riode
        vCPD_PERIOD_QTY  := (tplService.CPD_RENEWABLE_QTY / 12) * vCOEFF;
      else
        vCPD_PERIOD_QTY  := nvl(tplService.CPD_PERIOD_QTY, tplService.CPD_RENEWABLE_QTY);
      end if;

      vCPD_PERIOD_QTY     := nvl(ACS_FUNCTION.RoundNear(vCPD_PERIOD_QTY, 1 / power(10, tplService.GOO_NUMBER_OF_DECIMAL), 0), 0);

      -- Mise � jour des avoirs de prestation de la position
      update CML_POSITION_SERVICE_DETAIL
         set CPD_PERIOD_QTY = vCPD_PERIOD_QTY
           , CPD_BALANCE_QTY = vCPD_PERIOD_QTY
           , CPD_CONSUMED_QTY = 0
           , CPD_EXPIRY_DATE = last_day(vNextRenewalPeriod)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_SERVICE_DETAIL_ID = tplService.CML_POSITION_SERVICE_DETAIL_ID;
    end loop;
  end ServiceRenewalAfterActivate;

  /**
  * Description
  *   Mise � jour des avoirs de prestation apr�s prolongation de la position
  */
  procedure ServiceRenewalAfterExtend(aPositionID in CML_POSITION.CML_POSITION_ID%type)
  is
    vCPD_PERIOD_QTY    CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vCOEFF             CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vNextRenewalPeriod date;
  begin
    for tplService in (select CPD.CML_POSITION_SERVICE_DETAIL_ID
                            , nvl(CPD.CPD_RENEWABLE_QTY, 0) CPD_RENEWABLE_QTY
                            , nvl(CPD.CPD_CONSUMED_QTY, 0) CPD_CONSUMED_QTY
                            , nvl(CPD.CPD_PERIOD_QTY, 0) CPD_PERIOD_QTY
                            , CPD.CPD_PRORATA
                            , CPD.C_CML_TIME_UNIT
                            , CPD.CPD_EXPIRY_DATE
                            , CPO.CPO_BEGIN_CONTRACT_DATE
                            , nvl(CPO.CPO_END_EXTENDED_DATE, CPO.CPO_END_CONTRACT_DATE) CPO_END_CONTRACT_DATE
                            , add_months(nvl(CPO.CPO_END_EXTENDED_DATE, CPO.CPO_END_CONTRACT_DATE), CPO.CPO_EXTENDED_MONTHES) NEW_END_EXTENDED_DATE
                            , SER.GOO_NUMBER_OF_DECIMAL
                         from CML_POSITION_SERVICE_DETAIL CPD
                            , CML_POSITION_SERVICE CPS
                            , CML_POSITION CPO
                            , CML_PROCESSING CPR
                            , GCO_GOOD SER
                        where CPD.CML_POSITION_SERVICE_ID = CPS.CML_POSITION_SERVICE_ID
                          and CPS.CML_POSITION_ID = CPO.CML_POSITION_ID
                          and CPO.CML_POSITION_ID = aPositionID
                          and CPR.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID
                          and CPR.C_CML_PROCESSING_TYPE = '200'
                          and CPS.GCO_CML_SERVICE_ID = SER.GCO_GOOD_ID
                          and SER.C_SERVICE_KIND in('1', '2', '4')
                          and CPD.C_SERVICE_RENEWAL in('1', '4') ) loop
      -- Rechercher la date d�but de la prochaine p�riode de renouvellement
      vNextRenewalPeriod  :=
               GetRenewalPeriodDate(aDate              => tplService.CPO_END_CONTRACT_DATE, aServiceDetailID => tplService.CML_POSITION_SERVICE_DETAIL_ID
                                  , aBackPeriod        => 0);
      -- Calcul de la date du prochain renouvellement ou fin prolong. contrat
      vNextRenewalPeriod  := least(vNextRenewalPeriod, tplService.NEW_END_EXTENDED_DATE + 1);
      -- A la prolongation et r�siliation on calcule toujours au prorata, ind�pendamment du flag
      -- Unit� prorata = Jour
      vCOEFF              := greatest(0, CmlMonthsBetween(tplService.CPO_END_CONTRACT_DATE, vNextRenewalPeriod - 1) );

      -- Unit� prorata = Mois
      --  Utilisation de la fonction CmlMonthsBetween pour trouver les mois entre les 2 p�riodes
      --  Pour la date de d�part on va toujours prendre le 1er du mois
      if tplService.C_CML_TIME_UNIT = '2' then
        vCOEFF  := ceil(vCOEFF);
      end if;

      -- Qt� p�riode
      vCPD_PERIOD_QTY     := tplService.CPD_PERIOD_QTY + (tplService.CPD_RENEWABLE_QTY / 12) * vCOEFF;
      vCPD_PERIOD_QTY     := ACS_FUNCTION.RoundNear(vCPD_PERIOD_QTY, 1 / power(10, tplService.GOO_NUMBER_OF_DECIMAL), 0);

      -- Mise � jour des avoirs de prestation de la position
      update CML_POSITION_SERVICE_DETAIL
         set CPD_PERIOD_QTY = vCPD_PERIOD_QTY
           , CPD_BALANCE_QTY = vCPD_PERIOD_QTY - tplService.CPD_CONSUMED_QTY
           , CPD_EXPIRY_DATE = last_day(vNextRenewalPeriod)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_SERVICE_DETAIL_ID = tplService.CML_POSITION_SERVICE_DETAIL_ID;
    end loop;
  end ServiceRenewalAfterExtend;

  /**
  * Description
  *   Mise � jour des avoirs de prestation apr�s r�siliation de la position
  */
  procedure ServiceRenewalAfterResiliate(aPositionID in CML_POSITION.CML_POSITION_ID%type)
  is
    vCPD_PERIOD_QTY    CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vCPD_BALANCE_QTY   CML_POSITION_SERVICE_DETAIL.CPD_BALANCE_QTY%type;
    vCOEFF             CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vNextRenewalPeriod date;
  begin
    for tplService in (select CPD.CML_POSITION_SERVICE_DETAIL_ID
                            , nvl(CPD.CPD_RENEWABLE_QTY, 0) CPD_RENEWABLE_QTY
                            , nvl(CPD.CPD_CONSUMED_QTY, 0) CPD_CONSUMED_QTY
                            , nvl(CPD.CPD_PERIOD_QTY, 0) CPD_PERIOD_QTY
                            , nvl(CPD.CPD_BALANCE_QTY, 0) CPD_BALANCE_QTY
                            , CPD.CPD_PRORATA
                            , CPD.C_CML_TIME_UNIT
                            , CPD.CPD_EXPIRY_DATE
                            , CPO.CPO_NEXT_DATE
                            , CPO.CPO_RESILIATION_DATE
                            , CPO.CPO_EFFECTIV_END_DATE
                            , SER.GOO_NUMBER_OF_DECIMAL
                         from CML_POSITION_SERVICE_DETAIL CPD
                            , CML_POSITION_SERVICE CPS
                            , CML_POSITION CPO
                            , CML_PROCESSING CPR
                            , GCO_GOOD SER
                        where CPD.CML_POSITION_SERVICE_ID = CPS.CML_POSITION_SERVICE_ID
                          and CPS.CML_POSITION_ID = CPO.CML_POSITION_ID
                          and CPO.CML_POSITION_ID = aPositionID
                          and CPR.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID
                          and CPR.C_CML_PROCESSING_TYPE = '200'
                          and CPS.GCO_CML_SERVICE_ID = SER.GCO_GOOD_ID
                          and SER.C_SERVICE_KIND in('1', '2', '4')
                          and CPD.C_SERVICE_RENEWAL <> '3'
                          and CPO.CPO_RESILIATION_DATE <= CPD.CPD_EXPIRY_DATE) loop
      -- Recherche la date d�but de prochaine p�riode de renouvellement
      vNextRenewalPeriod  :=
                GetRenewalPeriodDate(aDate              => tplService.CPO_RESILIATION_DATE, aServiceDetailID => tplService.CML_POSITION_SERVICE_DETAIL_ID
                                   , aBackPeriod        => 0);

      -- S'il rest un solde, il faut r�adapter la qt� selon la r�siliation
      if (tplService.CPD_BALANCE_QTY > 0) then
        vCOEFF            := greatest(CmlMonthsBetween(tplService.CPO_RESILIATION_DATE, vNextRenewalPeriod), 0);

        -- Unit� prorata = Mois
        --  Utilisation de la fonction CmlMonthsBetween pour trouver les mois entre les 2 p�riodes
        --  Pour la date de d�part on va toujours prendre le 1er du mois
        if tplService.C_CML_TIME_UNIT = '2' then
          vCOEFF  := trunc(vCOEFF);
        end if;

        -- Qt� p�riode
        vCPD_PERIOD_QTY   := greatest(0, tplService.CPD_PERIOD_QTY - (tplService.CPD_RENEWABLE_QTY / 12) * vCOEFF);
        vCPD_PERIOD_QTY   := ACS_FUNCTION.RoundNear(vCPD_PERIOD_QTY, 1 / power(10, tplService.GOO_NUMBER_OF_DECIMAL), 0);
        -- Qt� solde
        vCPD_BALANCE_QTY  := greatest(0, vCPD_PERIOD_QTY - tplService.CPD_CONSUMED_QTY);
      else
        vCPD_BALANCE_QTY  := tplService.CPD_BALANCE_QTY;
        vCPD_PERIOD_QTY   := tplService.CPD_PERIOD_QTY;
      end if;

      -- Mise � jour des avoirs de prestation de la position
      update CML_POSITION_SERVICE_DETAIL
         set CPD_PERIOD_QTY = vCPD_PERIOD_QTY
           , CPD_BALANCE_QTY = vCPD_BALANCE_QTY
           , CPD_EXPIRY_DATE = tplService.CPO_EFFECTIV_END_DATE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_SERVICE_DETAIL_ID = tplService.CML_POSITION_SERVICE_DETAIL_ID;
    end loop;
  end ServiceRenewalAfterResiliate;

  /**
  * function GetRenewalPeriodDate
  * Description
  *    Retrouve la date de d�but ou de fin d'une p�riode de renouvellement des avoirs
  *    La variable aBackPeriod indique si la p�riode doit �tre recherch�e avant la
  *    date pass�e en param
  */
  function GetRenewalPeriodDate(
    aDate             in date
  , aServiceDetailID  in CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type
  , aBackPeriod       in integer default 1
  , aCounterStmtMarge in integer default 0
  )
    return date
  is
    vReturnDate date;
  begin
    -- Trouver la date de d�but de la p�riode de renouvellement actuelle
    -- Exemple :
    -- Si p�riode de renouvellement en janvier et juillet
    -- Date pass�e en param 15.04.2006
    -- Valeur de retour = 01.01.2006
    if aBackPeriod = 1 then
      select max(CURRENT_RENEWAL_PERIOD)
        into vReturnDate
        from (select to_date('01.' || MTH.MONTH_NUMBER || '.' || YEA.YEAR_NUMBER, 'DD.MM.YYYY') - aCounterStmtMarge CURRENT_RENEWAL_PERIOD
                from CML_PROCESSING CPR
                   , (select lpad(to_char(no), 2, '0') MONTH_NUMBER
                        from PCS.PC_NUMBER
                       where no <= 12) MTH
                   , (select no YEAR_NUMBER
                        from PCS.PC_NUMBER
                       where no = to_number(to_char(aDate, 'YYYY') )
                          or no = to_number(to_char(aDate, 'YYYY') ) - 1) YEA
               where CPR.CML_POSITION_SERVICE_DETAIL_ID = aServiceDetailID
                 and CPR.C_CML_PROCESSING_TYPE = '200'
                 and instr(CPR.CPR_MONTHS, MTH.MONTH_NUMBER) > 0)
       where CURRENT_RENEWAL_PERIOD <= aDate;
    else
      -- Rechercher la date du prochain renouvellement
      -- Trouver la date de fin de la prochaine p�riode de renouvellement
      -- Exemple :
      -- Si p�riode de renouvellement en janvier et juillet
      -- Date pass�e en param 15.04.2006
      -- Valeur de retour = 01.07.2006
      select min(NEXT_RENEWAL_PERIOD)
        into vReturnDate
        from (select to_date('01.' || MTH.MONTH_NUMBER || '.' || YEA.YEAR_NUMBER, 'DD.MM.YYYY') NEXT_RENEWAL_PERIOD
                from CML_PROCESSING CPR
                   , (select lpad(to_char(no), 2, '0') MONTH_NUMBER
                        from PCS.PC_NUMBER
                       where no <= 12) MTH
                   , (select no YEAR_NUMBER
                        from PCS.PC_NUMBER
                       where no = to_number(to_char(aDate, 'YYYY') )
                          or no = to_number(to_char(aDate, 'YYYY') ) + 1) YEA
               where CPR.CML_POSITION_SERVICE_DETAIL_ID = aServiceDetailID
                 and CPR.C_CML_PROCESSING_TYPE = '200'
                 and instr(CPR.CPR_MONTHS, MTH.MONTH_NUMBER) > 0)
       where NEXT_RENEWAL_PERIOD > aDate;
    end if;

    return vReturnDate;
  end GetRenewalPeriodDate;

  /**
  * procedure RecalcContractAmounts
  * Description
  *    Recalcul des montants :
  *      Montant factur�
  *      Montant suppl�mentaire position
  *      Perte position
  */
  procedure RecalcContractAmounts(
    aContractID in     CML_DOCUMENT.CML_DOCUMENT_ID%type default null
  , aPositionID in     CML_POSITION.CML_POSITION_ID%type default null
  , aPosError   out    number
  )
  is
    vPosAmount       CML_POSITION.CPO_POSITION_AMOUNT%type;
    vAddedAmount     CML_POSITION.CPO_POSITION_ADDED_AMOUNT%type;
    vLossAmount      CML_POSITION.CPO_POSITION_LOSS%type;
    lPositionProtect number;
  begin
    aPosError  := 0;

    if nvl(aContractID, aPositionID) is not null then
      for tplPos in (select   CML_POSITION_ID
                            , CPO_PROTECTED
                         from CML_POSITION
                        where CML_DOCUMENT_ID = nvl(aContractID, CML_DOCUMENT_ID)
                          and CML_POSITION_ID = nvl(aPositionID, CML_POSITION_ID)
                     order by 1) loop
        if tplPos.CPO_PROTECTED = 1 then
          -- Nbr de positions prot�g�es
          aPosError  := aPosError + 1;
        else
          -- Protection de la position pendant le traitement
          PositionProtect_AutoTrans(iPositionId   => tplPos.CML_POSITION_ID
                                  , iProtect      => 1
                                  , iSessionId    => DBMS_SESSION.unique_session_id
                                  , iShowError    => 0
                                  , oUpdated      => lPositionProtect
                                   );

          -- Rechercher le montant factur� des forfaits.
          -- Multiplier ce montant par -1 si le document est une Note de cr�dit
          select nvl(sum(POS.POS_GROSS_VALUE *(case
                                                 when GAS.C_GAUGE_TITLE = '9' then -1
                                                 else 1
                                               end) ), 0)
            into vPosAmount
            from DOC_POSITION POS
               , DOC_DOCUMENT DMT
               , DOC_GAUGE_STRUCTURED GAS
           where POS.CML_POSITION_ID = tplPos.CML_POSITION_ID
             and POS.CML_EVENTS_ID is null
             and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
             and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

          -- Rechercher le montant factur� des �venements.
          select nvl(sum(case
                           when CEV.C_CML_EVENT_TYPE = '1' then CEV.CEV_AMOUNT
                           when CEV.C_CML_EVENT_TYPE = '2' then CEV.CEV_AMOUNT
                           when CEV.C_CML_EVENT_TYPE = '3' then CEV.CEV_AMOUNT * -1
                           else 0
                         end
                        )
                   , 0
                    )
               , nvl(sum(case
                           when CEV.C_CML_EVENT_TYPE = '4' then CEV.CEV_AMOUNT
                           else 0
                         end), 0)
            into vAddedAmount
               , vLossAmount
            from DOC_POSITION POS
               , CML_EVENTS CEV
           where POS.CML_POSITION_ID = tplPos.CML_POSITION_ID
             and POS.CML_EVENTS_ID = CEV.CML_EVENTS_ID
             and CEV.C_CML_EVENT_TYPE in('1', '2', '3', '4');

          -- M�j des montants sur la position de contrat
          -- D�protection de la position
          update CML_POSITION
             set CPO_POSITION_AMOUNT = vPosAmount
               , CPO_POSITION_ADDED_AMOUNT = vAddedAmount
               , CPO_POSITION_LOSS = vLossAmount
               , CPO_PROTECTED = 0
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where CML_POSITION_ID = tplPos.CML_POSITION_ID;
        end if;
      end loop;
    end if;
  end RecalcContractAmounts;

  /**
  * function CmlMonthsBetween
  * Description
  *    Renvoi le nbre de mois (en valeur fractionnaire) entre 2 dates en tenant
  *    compte de la config cml pour le nbre de jours par mois pour les calculs
  */
  function CmlMonthsBetween(aDateBegin in date, aDateEnd in date)
    return number
  is
    vStart       number(12, 6);
    vEnd         number(12, 6);
    vInterval    number(12, 6);
    vBeginDay    integer;
    vEndDay      integer;
    vNbDaysBegin integer;
    vNbDaysEnd   integer;
    vDateBegin   date;
    vDateEnd     date;
  begin
    -- Initialiser les variables avec la plus petite date dans la date de d�part et
    -- la plus grande date dans la date de fin
    vDateBegin  := least(aDateBegin, aDateEnd);
    vDateEnd    := greatest(aDateBegin, aDateEnd);
    -- Le jour de la date de d�part et de la date de fin
    vBeginDay   := to_number(to_char(vDateBegin, 'DD') );
    vEndDay     := to_number(to_char(vDateEnd, 'DD') );

    -- Config CML_MONTHS_TYPE = 1 -> Calcul avec mois � 30 jours
    if nvl(PCS.PC_CONFIG.GetConfig('CML_MONTHS_TYPE'), '0') = '1' then
      vNbDaysBegin  := 30;
      vNbDaysEnd    := 30;
    else
      -- Config CML_MONTHS_TYPE <> 1 -> Calcul avec le nbr de jours effectif du mois
      vNbDaysBegin  := to_number(to_char(last_day(vDateBegin), 'DD') );
      vNbDaysEnd    := to_number(to_char(last_day(vDateEnd), 'DD') );
    end if;

    -- Date de d�but dans le m�me mois/ann�e que la date de fin
    if last_day(vDateBegin) = last_day(vDateEnd) then
      -- Calcul de l'Intervalle
      -- Intervalle = ((Jour Fin - Jour D�but) + 1) / Nbr de jours du mois
      vInterval  := least( (vEndDay - vBeginDay + 1) / vNbDaysBegin, 1);
    else
      -- Calcul de l'Intervalle de d�but (jours entre la date et la fin du mois)
      -- Intervalle = ((Nbr de jours du mois - Jour D�but) + 1) / Nbr de jours du mois
      vStart     := least( (to_number(to_char(last_day(vDateBegin), 'DD') ) - vBeginDay + 1) / vNbDaysBegin, 1);
      -- Calcul de l'Intervalle de fin (jours entre le 1er du mois et la date de fin)
      -- Intervalle = Jour Fin / Nbr de jours du mois
      vEnd       := least(vEndDay / vNbDaysEnd, 1);
      -- Calcul de l'Intervalle du nbre de mois entre la date de d�but et la date de fin
      -- Intervalle = Nbre de mois entre (Dernier jour du moi pr�c�dent la date de fin) ET (Le 1er jour du mois suivant la date de d�but)
      --               si valeur inf�rieure � 1 -> alors 0
      --               sinon -> valeur arrondie � l'entier sup�rieur
      vInterval  := ceil(greatest(months_between( (add_months(last_day(vDateEnd), -1) ),(last_day(vDateBegin) + 1) ), 0) );
      --
      vInterval  := vStart + vInterval + vEnd;
    end if;

    -- Si la date de d�but est plus grande que la date de fin, inverser la valeur de l'intervalle
    if aDateBegin > aDateEnd then
      vInterval  := vInterval * -1;
    end if;

    return vInterval;
  end CmlMonthsBetween;
end CML_CONTRACT_FUNCTIONS;
