--------------------------------------------------------
--  DDL for Package Body DOC_PRC_DOCUMENT_NUMBER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_DOCUMENT_NUMBER" 
is
  /**
  * procedure pInsertFreeNumber
  * Description
  *   Insertion d'un n� de document dans la table DOC_FREE_NUMBER si demand� par la num�rotation
  */
  procedure pInsertFreeNumber(
    iDmtNumber   in DOC_DOCUMENT.DMT_NUMBER%type
  , iNumberingID in DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type default null
  , iGaugeID     in DOC_GAUGE.DOC_GAUGE_ID%type default null
  , iCreating    in DOC_FREE_NUMBER.DOF_CREATING%type default 0
  , iSessionID   in varchar2 default null
  )
  is
    lnNumberingID  DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type   := null;
    lnFreeNumberID DOC_FREE_NUMBER.DOC_FREE_NUMBER_ID%type           := null;
    lvSessionID    DOC_FREE_NUMBER.DOF_SESSION_ID%type               := null;
    ltFreeNumber   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iDmtNumber is not null then
      -- ID de la num�rotation pass� en param
      if iNumberingID is not null then
        lnNumberingID  := iNumberingID;
      -- Recherche de l'id de la num�rotation sur le gabarit, si le gabarit g�re la num�rotation
      elsif     (iGaugeID is not null)
            and (FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_GAUGE', 'GAU_NUMBERING', iGaugeID) = 1) then
        lnNumberingID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_GAUGE', 'DOC_GAUGE_NUMBERING_ID', iGaugeID);
      end if;

      -- Num�rotation trouv�e et gestion des num�ros libres
      if     (lnNumberingID is not null)
         and (FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_GAUGE_NUMBERING', 'GAN_FREE_NUMBER', lnNumberingID) = 1) then
        -- V�rifier si le n� existe d�j� dans la table des num�ros libres
        select max(DOC_FREE_NUMBER_ID)
             , max(DOF_SESSION_ID)
          into lnFreeNumberID
             , lvSessionID
          from DOC_FREE_NUMBER
         where DOC_GAUGE_NUMBERING_ID = lnNumberingID
           and DOF_NUMBER = iDmtNumber;

        -- Insert
        if lnFreeNumberID is null then
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocFreeNumber, ltFreeNumber);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeNumber, 'DOC_GAUGE_NUMBERING_ID', lnNumberingID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeNumber, 'DOF_NUMBER', iDmtNumber);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeNumber, 'DOF_CREATING', iCreating);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeNumber, 'DOF_SESSION_ID', iSessionID);
          FWK_I_MGT_ENTITY.InsertEntity(ltFreeNumber);
          FWK_I_MGT_ENTITY.Release(ltFreeNumber);
        else
          -- Update

          -- V�rifier si la session qui a ins�re ce num�ro est toujours active
          if     (lvSessionID is not null)
             and (COM_FUNCTIONS.IS_SESSION_ALIVE(lvSessionID) = 1)
             and (DBMS_SESSION.UNIQUE_SESSION_ID <> lvSessionID) then
            PCS.RA(PCS.PC_FUNCTIONS.TranslateWord('Ce num�ro est d�j� r�serv� par un autre utilisateur !') );
          else
            FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocFreeNumber, ltFreeNumber);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeNumber, 'DOC_FREE_NUMBER_ID', lnFreeNumberID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeNumber, 'DOF_CREATING', iCreating);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeNumber, 'DOF_SESSION_ID', iSessionID);
            FWK_I_MGT_ENTITY.UpdateEntity(ltFreeNumber);
            FWK_I_MGT_ENTITY.Release(ltFreeNumber);
          end if;
        end if;
      end if;
    end if;
  end pInsertFreeNumber;

  /**
  * procedure ReserveFreeNumber
  * Description
  *   R�servation d'un n� de document (insertion dans la table DOC_FREE_NUMBER)
  *     Cette m�thode doit �tre utilis� lorsque l'obtention du nouveau n� s'effectue
  *     au d�but de la cr�ation d'un nouvel �l�ment (document, dossier SAV) au cas ou
  *     la cr�ation est abandonn�e abruptement
  */
  procedure ReserveFreeNumber(
    iDmtNumber   in DOC_DOCUMENT.DMT_NUMBER%type
  , iNumberingID in DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type default null
  , iGaugeID     in DOC_GAUGE.DOC_GAUGE_ID%type default null
  )
  is
  begin
    pInsertFreeNumber(iDmtNumber     => iDmtNumber
                    , iNumberingID   => iNumberingID
                    , iGaugeID       => iGaugeID
                    , iCreating      => 1
                    , iSessionID     => DBMS_SESSION.UNIQUE_SESSION_ID
                     );
  end ReserveFreeNumber;

  /**
  * procedure AddFreeNumber
  * Description
  *   Ajout d'un n� de document (insertion dans la table DOC_FREE_NUMBER)
  *     Cette m�thode doit �tre utilis� lors de l'effacement d'un �l�ment li� � la num�roation (document, dossier SAV, etc.)
  */
  procedure AddFreeNumber(
    iDmtNumber   in DOC_DOCUMENT.DMT_NUMBER%type
  , iNumberingID in DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type default null
  , iGaugeID     in DOC_GAUGE.DOC_GAUGE_ID%type default null
  )
  is
  begin
    -- iSessionID est pass� � 0 � cause du trigger DOC_DOF_BI_SESSION qui initialise la session se ce param est null
    --  par la suite (apr�s l'effacement de ce trigger) repasser le param iSessionID � null
    pInsertFreeNumber(iDmtNumber => iDmtNumber, iNumberingID => iNumberingID, iGaugeID => iGaugeID, iCreating => 0, iSessionID => 0);
  end AddFreeNumber;

  /**
  * procedure AddFreeNumber_AutoTrans
  * Description
  *   Appel � la m�thode AddFreeNumber ci-dessus mais avec une transaction autonome
  */
  procedure AddFreeNumber_AutoTrans(
    iNumber      in DOC_DOCUMENT.DMT_NUMBER%type
  , iNumberingID in DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type default null
  , iGaugeID     in DOC_GAUGE.DOC_GAUGE_ID%type default null
  )
  is
    pragma autonomous_transaction;
  begin
    DOC_PRC_DOCUMENT_NUMBER.AddFreeNumber(iDmtNumber => iNumber, iNumberingID => iNumberingID, iGaugeID => iGaugeID);
    commit;
  end AddFreeNumber_AutoTrans;
end DOC_PRC_DOCUMENT_NUMBER;
