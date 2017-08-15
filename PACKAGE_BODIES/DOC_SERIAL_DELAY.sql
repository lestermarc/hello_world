--------------------------------------------------------
--  DDL for Package Body DOC_SERIAL_DELAY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_SERIAL_DELAY" 
is
  vLocalFilter TSerialDelayFilter;

  /**
  * Description
  *   Mise à jour des délais
  */
  procedure UpdateDelay(aMode in varchar2, aSAV in number, aFail out number)
  is
    cursor detail
    is
      select DOC_POSITION_DETAIL_ID
        from DOC_TMP_POSITION_DETAIL
       where DTP_MODIFY = 1
         and DTP_FAIL = 0
         and DTP_SESSION_ID = userenv('SESSIONID')
         and aSAV = 1;

    cursor position
    is
      select PDE.DOC_POSITION_DETAIL_ID
        from DOC_TMP_POSITION_DETAIL DTP
           , DOC_POSITION POS
           , DOC_GAUGE_POSITION GAP
           , DOC_POSITION_DETAIL PDE
       where DTP.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and POS.C_DOC_POS_STATUS in('01', '02', '03')
         and GAP.GAP_DELAY = 1
         and DTP.DTP_MODIFY = 1
         and DTP.DTP_FAIL = 0
         and DTP.DTP_SESSION_ID = userenv('SESSIONID')
         and aSAV = 1;

    cursor document
    is
      select D.DOC_POSITION_DETAIL_ID
        from DOC_TMP_POSITION_DETAIL A
           , DOC_POSITION B
           , DOC_GAUGE_POSITION C
           , DOC_POSITION_DETAIL D
       where A.DOC_DOCUMENT_ID = B.DOC_DOCUMENT_ID
         and D.DOC_POSITION_ID = B.DOC_POSITION_ID
         and B.DOC_GAUGE_POSITION_ID = C.DOC_GAUGE_POSITION_ID
         and B.C_DOC_POS_STATUS in('01', '02', '03')
         and C.GAP_DELAY = 1
         and A.DTP_MODIFY = 1
         and A.DTP_FAIL = 0
         and A.DTP_SESSION_ID = userenv('SESSIONID')
         and aSAV = 1;

    position_detail_id DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    -- reset du flag d'erreur
    update DOC_TMP_POSITION_DETAIL
       set DTP_FAIL = 0
     where DTP_SESSION_ID = userenv('SESSIONID');

    -- Met le flag d'échec à 1 pour les DOCUMENTs qu'on voudrait mettre
    -- à jour mais qui sont protégés
    update DOC_TMP_POSITION_DETAIL MAIN
       set DTP_FAIL = 1
     where DTP_MODIFY = 1
       and DTP_SESSION_ID = userenv('SESSIONID')
       and exists(select A.DOC_DOCUMENT_ID
                    from DOC_DOCUMENT A
                   where A.DOC_DOCUMENT_ID = MAIN.DOC_DOCUMENT_ID
                     and A.DMT_PROTECTED = 1);

    if sql%found then
      aFail  := 1;
    else
      aFail  := 0;
    end if;

    commit;

    -- Protéger les documents que l'on va mettre à jour
    update DOC_DOCUMENT
       set DMT_PROTECTED = 1
         , DMT_SESSION_ID = DBMS_SESSION.unique_session_id
     where DOC_DOCUMENT_ID in(select DOC_DOCUMENT_ID
                                from DOC_TMP_POSITION_DETAIL
                               where DTP_MODIFY = 1
                                 and DTP_FAIL = 0
                                 and DTP_SESSION_ID = userenv('SESSIONID') );

    commit;

    if aMode = 'DETAIL' then
      update DOC_POSITION_DETAIL MAIN
         set (PDE_BASIS_DELAY, PDE_INTERMEDIATE_DELAY, PDE_FINAL_DELAY, PDE_SQM_ACCEPTED_DELAY, DIC_DELAY_UPDATE_TYPE_ID, PDE_DELAY_UPDATE_TEXT
            , DIC_PDE_FREE_TABLE_1_ID, DIC_PDE_FREE_TABLE_2_ID, DIC_PDE_FREE_TABLE_3_ID, PDE_TEXT_1, PDE_TEXT_2, PDE_TEXT_3) =
               (select nvl(A.DTP_NEW_BASIS_DELAY, B.PDE_BASIS_DELAY) PDE_BASIS_DELAY
                     , nvl(A.DTP_NEW_INTERMEDIATE_DELAY, B.PDE_INTERMEDIATE_DELAY) PDE_INTERMEDIATE_DELAY
                     , nvl(A.DTP_NEW_FINAL_DELAY, B.PDE_FINAL_DELAY) PDE_FINAL_DELAY
                     , nvl(A.DTP_NEW_SQM_ACCEPTED_DELAY, B.PDE_SQM_ACCEPTED_DELAY) PDE_SQM_ACCEPTED_DELAY
                     , decode(A.DIC_DELAY_UPDATE_TYPE_ID, '-', null, nvl(A.DIC_DELAY_UPDATE_TYPE_ID, B.DIC_DELAY_UPDATE_TYPE_ID) ) DIC_DELAY_UPDATE_TYPE_ID
                     , decode(A.PDE_DELAY_UPDATE_TEXT, '-', null, nvl(A.PDE_DELAY_UPDATE_TEXT, B.PDE_DELAY_UPDATE_TEXT) ) PDE_DELAY_UPDATE_TEXT
                     , decode(A.DIC_PDE_FREE_TABLE_1_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_1_ID, B.DIC_PDE_FREE_TABLE_1_ID) ) DIC_PDE_FREE_TABLE_1_ID
                     , decode(A.DIC_PDE_FREE_TABLE_2_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_2_ID, B.DIC_PDE_FREE_TABLE_2_ID) ) DIC_PDE_FREE_TABLE_2_ID
                     , decode(A.DIC_PDE_FREE_TABLE_3_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_3_ID, B.DIC_PDE_FREE_TABLE_3_ID) ) DIC_PDE_FREE_TABLE_3_ID
                     , decode(A.PDE_TEXT_1, '-', null, nvl(A.PDE_TEXT_1, B.PDE_TEXT_1) ) PDE_TEXT_1
                     , decode(A.PDE_TEXT_2, '-', null, nvl(A.PDE_TEXT_2, B.PDE_TEXT_2) ) PDE_TEXT_2
                     , decode(A.PDE_TEXT_3, '-', null, nvl(A.PDE_TEXT_3, B.PDE_TEXT_3) ) PDE_TEXT_3
                  from DOC_TMP_POSITION_DETAIL A
                     , DOC_POSITION_DETAIL B
                 where A.DOC_POSITION_DETAIL_ID = B.DOC_POSITION_DETAIL_ID
                   and A.DOC_POSITION_DETAIL_ID = MAIN.DOC_POSITION_DETAIL_ID
                   and A.DTP_SESSION_ID = userenv('SESSIONID')
                   and A.DTP_MODIFY = 1
                   and A.DTP_FAIL = 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_DETAIL_ID in(select DOC_POSITION_DETAIL_ID
                                         from DOC_TMP_POSITION_DETAIL
                                        where DTP_MODIFY = 1
                                          and DTP_FAIL = 0
                                          and DTP_SESSION_ID = userenv('SESSIONID') );

      /* Mise à jour des délais des composants liés:
         si type pos = '7', mise à jour des composants liés du type '71'
         dito pour '8' - '81', '9' - '91' et '10' - '101'
      */
      update DOC_POSITION_DETAIL MAIN
         set (PDE_BASIS_DELAY, PDE_INTERMEDIATE_DELAY, PDE_FINAL_DELAY, PDE_SQM_ACCEPTED_DELAY, DIC_DELAY_UPDATE_TYPE_ID, PDE_DELAY_UPDATE_TEXT
            , DIC_PDE_FREE_TABLE_1_ID, DIC_PDE_FREE_TABLE_2_ID, DIC_PDE_FREE_TABLE_3_ID, PDE_TEXT_1, PDE_TEXT_2, PDE_TEXT_3) =
               (select DET_PT.PDE_BASIS_DELAY
                     , DET_PT.PDE_INTERMEDIATE_DELAY
                     , DET_PT.PDE_FINAL_DELAY
                     , DET_PT.PDE_SQM_ACCEPTED_DELAY
                     , DET_PT.DIC_DELAY_UPDATE_TYPE_ID
                     , DET_PT.PDE_DELAY_UPDATE_TEXT
                     , DET_PT.DIC_PDE_FREE_TABLE_1_ID
                     , DET_PT.DIC_PDE_FREE_TABLE_2_ID
                     , DET_PT.DIC_PDE_FREE_TABLE_3_ID
                     , DET_PT.PDE_TEXT_1
                     , DET_PT.PDE_TEXT_2
                     , DET_PT.PDE_TEXT_3
                  from DOC_POSITION_DETAIL DET_CPT
                     , DOC_POSITION POS_CPT
                     , DOC_POSITION_DETAIL DET_PT
                 where DET_CPT.DOC_POSITION_DETAIL_ID = MAIN.DOC_POSITION_DETAIL_ID
                   and DET_CPT.DOC_POSITION_ID = POS_CPT.DOC_POSITION_ID
                   and POS_CPT.DOC_DOC_POSITION_ID = DET_PT.DOC_POSITION_ID)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_DETAIL_ID in(
               select PDE_CPT.DOC_POSITION_DETAIL_ID
                 from DOC_POSITION POS_PT
                    , DOC_POSITION POS_CPT
                    , DOC_POSITION_DETAIL PDE_CPT
                where POS_CPT.DOC_POSITION_ID = PDE_CPT.DOC_POSITION_ID
                  and POS_PT.DOC_POSITION_ID = POS_CPT.DOC_DOC_POSITION_ID
                  and POS_PT.DOC_POSITION_ID in(
                                     select DOC_POSITION_ID
                                       from DOC_TMP_POSITION_DETAIL
                                      where DTP_MODIFY = 1
                                        and DTP_FAIL = 0
                                        and C_GAUGE_TYPE_POS in('7', '8', '9', '10')
                                        and DTP_SESSION_ID = userenv('SESSIONID') ) );

      open detail;

      fetch detail
       into position_detail_id;

      while detail%found loop
        FAL_PRC_SUBCONTRACTO.updateCstDelay(position_detail_id);

        fetch detail
         into position_detail_id;
      end loop;

      close detail;
    elsif aMode = 'POSITION' then
      update DOC_POSITION_DETAIL MAIN
         set (PDE_BASIS_DELAY, PDE_INTERMEDIATE_DELAY, PDE_FINAL_DELAY, PDE_SQM_ACCEPTED_DELAY, DIC_DELAY_UPDATE_TYPE_ID, PDE_DELAY_UPDATE_TEXT
            , DIC_PDE_FREE_TABLE_1_ID, DIC_PDE_FREE_TABLE_2_ID, DIC_PDE_FREE_TABLE_3_ID, PDE_TEXT_1, PDE_TEXT_2, PDE_TEXT_3) =
               (select nvl(A.DTP_NEW_BASIS_DELAY, B.PDE_BASIS_DELAY) PDE_BASIS_DELAY
                     , nvl(A.DTP_NEW_INTERMEDIATE_DELAY, B.PDE_INTERMEDIATE_DELAY) PDE_INTERMEDIATE_DELAY
                     , nvl(A.DTP_NEW_FINAL_DELAY, B.PDE_FINAL_DELAY) PDE_FINAL_DELAY
                     , nvl(A.DTP_NEW_SQM_ACCEPTED_DELAY, B.PDE_SQM_ACCEPTED_DELAY) PDE_SQM_ACCEPTED_DELAY
                     , decode(A.DIC_DELAY_UPDATE_TYPE_ID, '-', null, nvl(A.DIC_DELAY_UPDATE_TYPE_ID, B.DIC_DELAY_UPDATE_TYPE_ID) ) DIC_DELAY_UPDATE_TYPE_ID
                     , decode(A.PDE_DELAY_UPDATE_TEXT, '-', null, nvl(A.PDE_DELAY_UPDATE_TEXT, B.PDE_DELAY_UPDATE_TEXT) ) PDE_DELAY_UPDATE_TEXT
                     , decode(A.DIC_PDE_FREE_TABLE_1_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_1_ID, B.DIC_PDE_FREE_TABLE_1_ID) ) DIC_PDE_FREE_TABLE_1_ID
                     , decode(A.DIC_PDE_FREE_TABLE_2_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_2_ID, B.DIC_PDE_FREE_TABLE_2_ID) ) DIC_PDE_FREE_TABLE_2_ID
                     , decode(A.DIC_PDE_FREE_TABLE_3_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_3_ID, B.DIC_PDE_FREE_TABLE_3_ID) ) DIC_PDE_FREE_TABLE_3_ID
                     , decode(A.PDE_TEXT_1, '-', null, nvl(A.PDE_TEXT_1, B.PDE_TEXT_1) ) PDE_TEXT_1
                     , decode(A.PDE_TEXT_2, '-', null, nvl(A.PDE_TEXT_2, B.PDE_TEXT_2) ) PDE_TEXT_2
                     , decode(A.PDE_TEXT_3, '-', null, nvl(A.PDE_TEXT_3, B.PDE_TEXT_3) ) PDE_TEXT_3
                  from DOC_TMP_POSITION_DETAIL A
                     , DOC_POSITION_DETAIL B
                     , DOC_POSITION C
                     , DOC_GAUGE_POSITION D
                 where A.DOC_POSITION_ID = B.DOC_POSITION_ID
                   and B.DOC_POSITION_ID = C.DOC_POSITION_ID
                   and B.DOC_POSITION_DETAIL_ID = MAIN.DOC_POSITION_DETAIL_ID
                   and D.DOC_GAUGE_POSITION_ID = C.DOC_GAUGE_POSITION_ID
                   and D.GAP_DELAY = 1
                   and A.DTP_SESSION_ID = userenv('SESSIONID')
                   and A.DTP_MODIFY = 1
                   and A.DTP_FAIL = 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID in(
               select B.DOC_POSITION_ID
                 from DOC_TMP_POSITION_DETAIL A
                    , DOC_POSITION B
                    , DOC_GAUGE_POSITION C
                where A.DOC_POSITION_ID = B.DOC_POSITION_ID
                  and B.DOC_GAUGE_POSITION_ID = C.DOC_GAUGE_POSITION_ID
                  and B.C_DOC_POS_STATUS in('01', '02', '03')
                  and C.GAP_DELAY = 1
                  and A.DTP_MODIFY = 1
                  and A.DTP_FAIL = 0
                  and A.DTP_SESSION_ID = userenv('SESSIONID') );

      /* Mise à jour des délais des composants liés:
         si type pos = '7', mise à jour des composants liés du type '71'
         dito pour '8' - '81', '9' - '91' et '10' - '101'
      */
      update DOC_POSITION_DETAIL MAIN
         set (PDE_BASIS_DELAY, PDE_INTERMEDIATE_DELAY, PDE_FINAL_DELAY, PDE_SQM_ACCEPTED_DELAY, DIC_DELAY_UPDATE_TYPE_ID, PDE_DELAY_UPDATE_TEXT
            , DIC_PDE_FREE_TABLE_1_ID, DIC_PDE_FREE_TABLE_2_ID, DIC_PDE_FREE_TABLE_3_ID, PDE_TEXT_1, PDE_TEXT_2, PDE_TEXT_3) =
               (select DET_PT.PDE_BASIS_DELAY
                     , DET_PT.PDE_INTERMEDIATE_DELAY
                     , DET_PT.PDE_FINAL_DELAY
                     , DET_PT.PDE_SQM_ACCEPTED_DELAY
                     , DET_PT.DIC_DELAY_UPDATE_TYPE_ID
                     , DET_PT.PDE_DELAY_UPDATE_TEXT
                     , DET_PT.DIC_PDE_FREE_TABLE_1_ID
                     , DET_PT.DIC_PDE_FREE_TABLE_2_ID
                     , DET_PT.DIC_PDE_FREE_TABLE_3_ID
                     , DET_PT.PDE_TEXT_1
                     , DET_PT.PDE_TEXT_2
                     , DET_PT.PDE_TEXT_3
                  from DOC_POSITION_DETAIL DET_CPT
                     , DOC_POSITION POS_CPT
                     , DOC_POSITION_DETAIL DET_PT
                 where DET_CPT.DOC_POSITION_DETAIL_ID = MAIN.DOC_POSITION_DETAIL_ID
                   and DET_CPT.DOC_POSITION_ID = POS_CPT.DOC_POSITION_ID
                   and POS_CPT.DOC_DOC_POSITION_ID = DET_PT.DOC_POSITION_ID)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_DETAIL_ID in(
               select PDE_CPT.DOC_POSITION_DETAIL_ID
                 from DOC_POSITION POS_PT
                    , DOC_POSITION POS_CPT
                    , DOC_POSITION_DETAIL PDE_CPT
                where POS_CPT.DOC_POSITION_ID = PDE_CPT.DOC_POSITION_ID
                  and POS_PT.DOC_POSITION_ID = POS_CPT.DOC_DOC_POSITION_ID
                  and POS_PT.DOC_POSITION_ID in(
                                     select DOC_POSITION_ID
                                       from DOC_TMP_POSITION_DETAIL
                                      where DTP_MODIFY = 1
                                        and DTP_FAIL = 0
                                        and C_GAUGE_TYPE_POS in('7', '8', '9', '10')
                                        and DTP_SESSION_ID = userenv('SESSIONID') ) );

      open position;

      fetch position
       into position_detail_id;

      while position%found loop
        FAL_PRC_SUBCONTRACTO.updateCstDelay(position_detail_id);

        fetch position
         into position_detail_id;
      end loop;

      close position;
    else   -- MODE = 'DOCUMENT'
      update DOC_POSITION_DETAIL MAIN
         set (PDE_BASIS_DELAY, PDE_INTERMEDIATE_DELAY, PDE_FINAL_DELAY, PDE_SQM_ACCEPTED_DELAY, DIC_DELAY_UPDATE_TYPE_ID, PDE_DELAY_UPDATE_TEXT
            , DIC_PDE_FREE_TABLE_1_ID, DIC_PDE_FREE_TABLE_2_ID, DIC_PDE_FREE_TABLE_3_ID, PDE_TEXT_1, PDE_TEXT_2, PDE_TEXT_3) =
               (select nvl(A.DTP_NEW_BASIS_DELAY, B.PDE_BASIS_DELAY) PDE_BASIS_DELAY
                     , nvl(A.DTP_NEW_INTERMEDIATE_DELAY, B.PDE_INTERMEDIATE_DELAY) PDE_INTERMEDIATE_DELAY
                     , nvl(A.DTP_NEW_FINAL_DELAY, B.PDE_FINAL_DELAY) PDE_FINAL_DELAY
                     , nvl(A.DTP_NEW_SQM_ACCEPTED_DELAY, B.PDE_SQM_ACCEPTED_DELAY) PDE_SQM_ACCEPTED_DELAY
                     , decode(A.DIC_DELAY_UPDATE_TYPE_ID, '-', null, nvl(A.DIC_DELAY_UPDATE_TYPE_ID, B.DIC_DELAY_UPDATE_TYPE_ID) ) DIC_DELAY_UPDATE_TYPE_ID
                     , decode(A.PDE_DELAY_UPDATE_TEXT, '-', null, nvl(A.PDE_DELAY_UPDATE_TEXT, B.PDE_DELAY_UPDATE_TEXT) ) PDE_DELAY_UPDATE_TEXT
                     , decode(A.DIC_PDE_FREE_TABLE_1_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_1_ID, B.DIC_PDE_FREE_TABLE_1_ID) ) DIC_PDE_FREE_TABLE_1_ID
                     , decode(A.DIC_PDE_FREE_TABLE_2_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_2_ID, B.DIC_PDE_FREE_TABLE_2_ID) ) DIC_PDE_FREE_TABLE_2_ID
                     , decode(A.DIC_PDE_FREE_TABLE_3_ID, '-', null, nvl(A.DIC_PDE_FREE_TABLE_3_ID, B.DIC_PDE_FREE_TABLE_3_ID) ) DIC_PDE_FREE_TABLE_3_ID
                     , decode(A.PDE_TEXT_1, '-', null, nvl(A.PDE_TEXT_1, B.PDE_TEXT_1) ) PDE_TEXT_1
                     , decode(A.PDE_TEXT_2, '-', null, nvl(A.PDE_TEXT_2, B.PDE_TEXT_2) ) PDE_TEXT_2
                     , decode(A.PDE_TEXT_3, '-', null, nvl(A.PDE_TEXT_3, B.PDE_TEXT_3) ) PDE_TEXT_3
                  from DOC_TMP_POSITION_DETAIL A
                     , DOC_POSITION_DETAIL B
                     , DOC_POSITION C
                     , DOC_GAUGE_POSITION D
                 where A.DOC_DOCUMENT_ID = C.DOC_DOCUMENT_ID
                   and B.DOC_POSITION_ID = C.DOC_POSITION_ID
                   and B.DOC_POSITION_DETAIL_ID = MAIN.DOC_POSITION_DETAIL_ID
                   and D.DOC_GAUGE_POSITION_ID = C.DOC_GAUGE_POSITION_ID
                   and D.GAP_DELAY = 1
                   and A.DTP_SESSION_ID = userenv('SESSIONID')
                   and A.DTP_MODIFY = 1
                   and A.DTP_FAIL = 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID in(
               select B.DOC_POSITION_ID
                 from DOC_TMP_POSITION_DETAIL A
                    , DOC_POSITION B
                    , DOC_GAUGE_POSITION C
                where A.DOC_DOCUMENT_ID = B.DOC_DOCUMENT_ID
                  and B.DOC_GAUGE_POSITION_ID = C.DOC_GAUGE_POSITION_ID
                  and B.C_DOC_POS_STATUS in('01', '02', '03')
                  and C.GAP_DELAY = 1
                  and A.DTP_MODIFY = 1
                  and A.DTP_FAIL = 0
                  and A.DTP_SESSION_ID = userenv('SESSIONID') );

      open document;

      fetch document
       into position_detail_id;

      while document%found loop
        FAL_PRC_SUBCONTRACTO.updateCstDelay(position_detail_id);

        fetch document
         into position_detail_id;
      end loop;

      close document;
    end if;

    -- Supression des documents protégés par le processus
    ClearProtections;

    -- Efface les délais mis à jour et ne laisse que ceux qui n'ont pas pû être mis à jour
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_FAIL = 0
            and DTP_SESSION_ID = userenv('SESSIONID');
  end UpdateDelay;

  /**
  * Description
  *   Supression des documents protégés par le processus
  *   pour appel externe en cas d'exception
  */
  procedure ClearProtections
  is
  begin
    -- Supprime l'indicateur de mise à jour du délai de l'opération
    update DOC_POSITION
       set POS_UPDATE_OP = 0
     where DOC_POSITION_ID in(select DOC_POSITION_ID
                                from DOC_TMP_POSITION_DETAIL
                               where DTP_MODIFY = 1
                                 and DTP_FAIL = 0
                                 and DTP_SESSION_ID = userenv('SESSIONID') );

    -- Déprotéger les documents que l'on vient de mettre à jour
    update DOC_DOCUMENT
       set DMT_PROTECTED = 0
         , DMT_SESSION_ID = null
     where DOC_DOCUMENT_ID in(select DOC_DOCUMENT_ID
                                from DOC_TMP_POSITION_DETAIL
                               where DTP_MODIFY = 1
                                 and DTP_FAIL = 0
                                 and DTP_SESSION_ID = userenv('SESSIONID') );

    commit;
  end ClearProtections;

  /**
  * procedure ExtractData_DOC
  * Description
  *   Extraction des données pour le mode de saisie - DOCUMENT
  */
  procedure ExtractData_DOC
  is
  begin
    -- Pas de filtre sur les produits en mode de saisie - DOCUMENT
    vLocalFilter                := vGlobalFilter;
    vLocalFilter.GOOD_JOB_ID    := null;
    vLocalFilter.DTP_GOOD_FROM  := null;
    vLocalFilter.DTP_GOOD_TO    := null;

    insert into DOC_TMP_POSITION_DETAIL
                (DTP_SESSION_ID
               , DOC_DOCUMENT_ID
               , DOC_POSITION_DETAIL_ID
               , DTP_NUMBER
               , DTP_PER_NAME
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , PDE_BASIS_DELAY
               , PDE_BASIS_DELAY_W
               , PDE_BASIS_DELAY_M
               , PDE_SQM_ACCEPTED_DELAY
               , DTP_NEW_SQM_ACCEPTED_DELAY
               , CRG_SELECT
               , DTP_MODIFY
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      (select   userenv('SESSIONID')
              , DMT.DOC_DOCUMENT_ID
              , 0
              , DMT.DMT_NUMBER
              , PER.PER_NAME || ' ' || PER.PER_FORENAME
              , DMT.PAC_THIRD_ACI_ID
              , DMT.PAC_THIRD_DELIVERY_ID
              , min(PDE.PDE_BASIS_DELAY)
              , '' PDE_BASIS_DELAY_W
              , '' PDE_BASIS_DELAY_M
              , '' PDE_SQM_ACCEPTED_DELAY
              , decode(vLocalFilter.TRANSFERT_SQM_DELAY, 1, min(PDE.PDE_SQM_ACCEPTED_DELAY), null)
              , 0
              , 0
              , min(DMT.A_DATECRE)
              , min(DMT.A_DATEMOD)
              , min(DMT.A_IDCRE)
              , min(DMT.A_IDMOD)
              , min(DMT.A_RECLEVEL)
              , min(DMT.A_RECSTATUS)
           from table(GetFilteredDetailID) FLT
              , DOC_DOCUMENT DMT
              , DOC_POSITION POS
              , DOC_POSITION_DETAIL PDE
              , PAC_PERSON PER
          where FLT.column_value = PDE.DOC_POSITION_DETAIL_ID
            and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
            and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
            and DMT.PAC_THIRD_ID = PER.PAC_PERSON_ID(+)
       group by userenv('SESSIONID')
              , DMT.DOC_DOCUMENT_ID
              , DMT.DMT_NUMBER
              , DMT.PAC_THIRD_ACI_ID
              , DMT.PAC_THIRD_DELIVERY_ID
              , PER.PER_NAME || ' ' || PER.PER_FORENAME);
  end ExtractData_DOC;

  /**
  * procedure ExtractData_POS
  * Description
  *   Extraction des données pour le mode de saisie - POSITION
  */
  procedure ExtractData_POS
  is
  begin
    vLocalFilter  := vGlobalFilter;

    insert into DOC_TMP_POSITION_DETAIL
                (DTP_SESSION_ID
               , DOC_DOCUMENT_ID
               , DOC_POSITION_ID
               , DOC_POSITION_DETAIL_ID
               , DTP_NUMBER
               , DTP_PER_NAME
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , DTP_MAJOR_REFERENCE
               , PDE_BASIS_DELAY
               , PDE_BASIS_DELAY_W
               , PDE_BASIS_DELAY_M
               , PDE_SQM_ACCEPTED_DELAY
               , DTP_NEW_SQM_ACCEPTED_DELAY
               , CRG_SELECT
               , DTP_MODIFY
               , C_GAUGE_TYPE_POS
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select   userenv('SESSIONID')
             , DMT.DOC_DOCUMENT_ID
             , POS.DOC_POSITION_ID
             , POS.DOC_POSITION_ID
             , DMT.DMT_NUMBER
             , PER.PER_NAME || ' ' || PER.PER_FORENAME
             , DMT.PAC_THIRD_ACI_ID
             , DMT.PAC_THIRD_DELIVERY_ID
             , GOO.GOO_MAJOR_REFERENCE || ' ' || GOO.GOO_SECONDARY_REFERENCE
             , min(PDE.PDE_BASIS_DELAY)
             , '' PDE_BASIS_DELAY_W
             , '' PDE_BASIS_DELAY_M
             , '' PDE_SQM_ACCEPTED_DELAY
             , decode(vLocalFilter.TRANSFERT_SQM_DELAY, 1, min(PDE.PDE_SQM_ACCEPTED_DELAY), null)
             , 0
             , 0
             , POS.C_GAUGE_TYPE_POS
             , min(DMT.A_DATECRE)
             , min(DMT.A_DATEMOD)
             , min(DMT.A_IDCRE)
             , min(DMT.A_IDMOD)
             , min(DMT.A_RECLEVEL)
             , min(DMT.A_RECSTATUS)
          from table(GetFilteredDetailID) FLT
             , DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , GCO_GOOD GOO
             , PAC_PERSON PER
         where FLT.column_value = PDE.DOC_POSITION_DETAIL_ID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
           and DMT.PAC_THIRD_ID = PER.PAC_PERSON_ID(+)
      group by userenv('SESSIONID')
             , DMT.DOC_DOCUMENT_ID
             , DMT.DMT_NUMBER
             , POS.DOC_POSITION_ID
             , GOO.GOO_MAJOR_REFERENCE
             , GOO.GOO_SECONDARY_REFERENCE
             , DMT.PAC_THIRD_ACI_ID
             , DMT.PAC_THIRD_DELIVERY_ID
             , PER.PER_NAME || ' ' || PER.PER_FORENAME
             , POS.C_GAUGE_TYPE_POS;
  end ExtractData_POS;

  /**
  * procedure ExtractData_PDE
  * Description
  *   Extraction des données pour le mode de saisie - DETAIL
  */
  procedure ExtractData_PDE
  is
  begin
    vLocalFilter  := vGlobalFilter;

    insert into DOC_TMP_POSITION_DETAIL
                (DTP_SESSION_ID
               , DOC_DOCUMENT_ID
               , DOC_POSITION_DETAIL_ID
               , DTP_NUMBER
               , DTP_PER_NAME
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , DTP_MAJOR_REFERENCE
               , DOC_GAUGE_FLOW_ID
               , DOC_POSITION_ID
               , DOC_GAUGE_POSITION_ID
               , DOC_DOC_POSITION_DETAIL_ID
               , DOC2_DOC_POSITION_DETAIL_ID
               , PDE_BASIS_DELAY
               , PDE_BASIS_DELAY_W
               , PDE_BASIS_DELAY_M
               , PDE_INTERMEDIATE_DELAY
               , PDE_INTERMEDIATE_DELAY_W
               , PDE_INTERMEDIATE_DELAY_M
               , PDE_FINAL_DELAY
               , PDE_FINAL_DELAY_W
               , PDE_FINAL_DELAY_M
               , PDE_SQM_ACCEPTED_DELAY
               , DTP_NEW_SQM_ACCEPTED_DELAY
               , PDE_BASIS_QUANTITY
               , PDE_INTERMEDIATE_QUANTITY
               , PDE_FINAL_QUANTITY
               , PDE_BALANCE_QUANTITY
               , PDE_MOVEMENT_QUANTITY
               , PDE_MOVEMENT_VALUE
               , PDE_CHARACTERIZATION_VALUE_1
               , PDE_CHARACTERIZATION_VALUE_2
               , PDE_CHARACTERIZATION_VALUE_3
               , PDE_CHARACTERIZATION_VALUE_4
               , PDE_CHARACTERIZATION_VALUE_5
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , PDE_BALANCE_QUANTITY_PARENT
               , DIC_PDE_FREE_TABLE_1_ID
               , DIC_PDE_FREE_TABLE_2_ID
               , DIC_PDE_FREE_TABLE_3_ID
               , PDE_DECIMAL_1
               , PDE_DECIMAL_2
               , PDE_DECIMAL_3
               , PDE_TEXT_1
               , PDE_TEXT_2
               , PDE_TEXT_3
               , PDE_DATE_1
               , PDE_DATE_2
               , PDE_DATE_3
               , DIC_DELAY_UPDATE_TYPE_ID
               , PDE_DELAY_UPDATE_TEXT
               , CRG_SELECT
               , DTP_MODIFY
               , C_GAUGE_TYPE_POS
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select userenv('SESSIONID')
           , DMT.DOC_DOCUMENT_ID
           , PDE.DOC_POSITION_DETAIL_ID
           , DMT.DMT_NUMBER
           , PER.PER_NAME || ' ' || PER.PER_FORENAME
           , DMT.PAC_THIRD_ACI_ID
           , DMT.PAC_THIRD_DELIVERY_ID
           , GOO.GOO_MAJOR_REFERENCE || ' ' || GOO.GOO_SECONDARY_REFERENCE
           , PDE.DOC_GAUGE_FLOW_ID
           , PDE.DOC_POSITION_ID
           , POS.DOC_GAUGE_POSITION_ID
           , PDE.DOC_DOC_POSITION_DETAIL_ID
           , PDE.DOC2_DOC_POSITION_DETAIL_ID
           , PDE.PDE_BASIS_DELAY
           , PDE.PDE_BASIS_DELAY_W
           , PDE.PDE_BASIS_DELAY_M
           , PDE.PDE_INTERMEDIATE_DELAY
           , PDE.PDE_INTERMEDIATE_DELAY_W
           , PDE.PDE_INTERMEDIATE_DELAY_M
           , PDE.PDE_FINAL_DELAY
           , PDE.PDE_FINAL_DELAY_W
           , PDE.PDE_FINAL_DELAY_M
           , PDE.PDE_SQM_ACCEPTED_DELAY
           , decode(vLocalFilter.TRANSFERT_SQM_DELAY, 1, PDE.PDE_SQM_ACCEPTED_DELAY, null)
           , PDE.PDE_BASIS_QUANTITY
           , PDE.PDE_INTERMEDIATE_QUANTITY
           , PDE.PDE_FINAL_QUANTITY
           , PDE.PDE_BALANCE_QUANTITY
           , PDE.PDE_MOVEMENT_QUANTITY
           , PDE.PDE_MOVEMENT_VALUE
           , PDE.PDE_CHARACTERIZATION_VALUE_1
           , PDE.PDE_CHARACTERIZATION_VALUE_2
           , PDE.PDE_CHARACTERIZATION_VALUE_3
           , PDE.PDE_CHARACTERIZATION_VALUE_4
           , PDE.PDE_CHARACTERIZATION_VALUE_5
           , PDE.GCO_CHARACTERIZATION_ID
           , PDE.GCO_GCO_CHARACTERIZATION_ID
           , PDE.GCO2_GCO_CHARACTERIZATION_ID
           , PDE.GCO3_GCO_CHARACTERIZATION_ID
           , PDE.GCO4_GCO_CHARACTERIZATION_ID
           , PDE.STM_LOCATION_ID
           , PDE.STM_STM_LOCATION_ID
           , PDE.PDE_BALANCE_QUANTITY_PARENT
           , PDE.DIC_PDE_FREE_TABLE_1_ID
           , PDE.DIC_PDE_FREE_TABLE_2_ID
           , PDE.DIC_PDE_FREE_TABLE_3_ID
           , PDE.PDE_DECIMAL_1
           , PDE.PDE_DECIMAL_2
           , PDE.PDE_DECIMAL_3
           , PDE.PDE_TEXT_1
           , PDE.PDE_TEXT_2
           , PDE.PDE_TEXT_3
           , PDE.PDE_DATE_1
           , PDE.PDE_DATE_2
           , PDE.PDE_DATE_3
           , PDE.DIC_DELAY_UPDATE_TYPE_ID
           , PDE.PDE_DELAY_UPDATE_TEXT
           , 0
           , 0
           , POS.C_GAUGE_TYPE_POS
           , PDE.A_DATECRE
           , PDE.A_DATEMOD
           , PDE.A_IDCRE
           , PDE.A_IDMOD
           , PDE.A_RECLEVEL
           , PDE.A_RECSTATUS
        from table(GetFilteredDetailID) FLT
           , DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
           , GCO_GOOD GOO
           , PAC_PERSON PER
       where FLT.column_value = PDE.DOC_POSITION_DETAIL_ID
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and DMT.PAC_THIRD_ID = PER.PAC_PERSON_ID(+)
         and PDE.PDE_BALANCE_QUANTITY <> 0;
  end ExtractData_PDE;

  /**
  * function GetFilteredThirdID
  * Description
  *   Renvoi une liste d'id des tiers en fonction des filtres à l'interface
  */
  function GetFilteredThirdID(aJobID in COM_LIST.LIS_JOB_ID%type, aNameFrom in PAC_PERSON.PER_NAME%type, aNameTo in PAC_PERSON.PER_NAME%type)
    return ID_TABLE_TYPE pipelined
  is
  begin
    -- Filtre sur le job de la liste des tiers dans la table COM_LIST
    if nvl(aJobID, 0) <> 0 then
      for tplFilter in (select   PER.PAC_PERSON_ID as id
                            from PAC_PERSON PER
                               , COM_LIST LIS
                           where LIS.LIS_JOB_ID = aJobID
                             and LIS.LIS_ID_1 = PER.PAC_PERSON_ID
                             and LIS.LIS_CODE = 'PAC_PERSON_ID'
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    -- Filtre sur la référence des tiers
    elsif    aNameFrom is not null
          or aNameTo is not null then
      for tplFilter in (select   PER.PAC_PERSON_ID as id
                            from PAC_PERSON PER
                           where (PER.PER_NAME between nvl(aNameFrom, lpad(' ', 30, chr(1) ) ) and nvl(aNameTo, lpad(' ', 30, chr(255) ) ) )
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    -- Pas de filtre = Tous les tiers
    else
      for tplFilter in (select   PER.PAC_PERSON_ID as id
                            from PAC_PERSON PER
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    end if;
  end GetFilteredThirdID;

  /**
  * function GetFilteredGoodID
  * Description
  *   Renvoi une liste d'id des produits en fonction des filtres à l'interface
  */
  function GetFilteredGoodID(
    aJobID    in COM_LIST.LIS_JOB_ID%type
  , aGoodFrom in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aGoodTo   in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  )
    return ID_TABLE_TYPE pipelined
  is
  begin
    -- Filtre sur le job de la liste des biens dans la table COM_LIST
    if nvl(aJobID, 0) <> 0 then
      for tplFilter in (select   GOO.GCO_GOOD_ID as id
                            from GCO_GOOD GOO
                               , COM_LIST LIS
                           where LIS.LIS_JOB_ID = aJobID
                             and LIS.LIS_ID_1 = GOO.GCO_GOOD_ID
                             and LIS.LIS_CODE = 'GCO_GOOD_ID'
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    -- Filtre sur la référence des biens
    elsif    aGoodFrom is not null
          or aGoodTo is not null then
      for tplFilter in (select   GOO.GCO_GOOD_ID as id
                            from GCO_GOOD GOO
                           where (GOO.GOO_MAJOR_REFERENCE between nvl(aGoodFrom, lpad(' ', 30, chr(1) ) ) and nvl(aGoodTo, lpad(' ', 30, chr(255) ) ) )
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    -- Pas de filtre = Tous les biens
    else
      for tplFilter in (select   GOO.GCO_GOOD_ID as id
                            from GCO_GOOD GOO
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    end if;
  end GetFilteredGoodID;

  /**
  * function GetFilteredDocumentID
  * Description
  *   Renvoi une liste d'id des documents en fonction des filtres à l'interface
  */
  function GetFilteredDocumentID(
    aJobID      in COM_LIST.LIS_JOB_ID%type
  , aDocFrom    in DOC_DOCUMENT.DMT_NUMBER%type
  , aDocTo      in DOC_DOCUMENT.DMT_NUMBER%type
  , aGaugeID    in DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aStatusList in varchar2
  )
    return ID_TABLE_TYPE pipelined
  is
  begin
    -- Filtre sur le job de la liste des documents dans la table COM_LIST
    if nvl(aJobID, 0) <> 0 then
      for tplFilter in (select   DMT.DOC_DOCUMENT_ID as id
                            from DOC_DOCUMENT DMT
                               , COM_LIST LIS
                           where LIS.LIS_JOB_ID = aJobID
                             and LIS.LIS_ID_1 = DMT.DOC_DOCUMENT_ID
                             and DMT.DMT_PROTECTED = 0
                             and DMT.DOC_GAUGE_ID = aGaugeID
                             and LIS.LIS_CODE = 'DOC_DOCUMENT_ID'
                             and instr(aStatusList, ',' || DMT.C_DOCUMENT_STATUS || ',') > 0
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    -- Filtre sur la référence des documents
    elsif    aDocFrom is not null
          or aDocTo is not null then
      for tplFilter in (select   DMT.DOC_DOCUMENT_ID as id
                            from DOC_DOCUMENT DMT
                           where DMT.DOC_GAUGE_ID = aGaugeID
                             and DMT.DMT_PROTECTED = 0
                             and (DMT.DMT_NUMBER between nvl(aDocFrom, lpad(' ', 30, chr(1) ) ) and nvl(aDocTo, lpad(' ', 30, chr(255) ) ) )
                             and instr(aStatusList, ',' || DMT.C_DOCUMENT_STATUS || ',') > 0
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    -- Pas de filtre = Tous les documents
    else
      for tplFilter in (select   DMT.DOC_DOCUMENT_ID as id
                            from DOC_DOCUMENT DMT
                           where DMT.DOC_GAUGE_ID = aGaugeID
                             and DMT.DMT_PROTECTED = 0
                             and instr(aStatusList, ',' || DMT.C_DOCUMENT_STATUS || ',') > 0
                        order by 1) loop
        pipe row(tplFilter.id);
      end loop;
    end if;
  end GetFilteredDocumentID;

  /**
  * function GetFilteredDetailID
  * Description
  *   Renvoi une liste d'id des détails de position à traiter en fonction des filtres à l'interface
  */
  function GetFilteredDetailID
    return ID_TABLE_TYPE pipelined
  is
    -- Curseur sur les détails de position avec filtres sur les partenaires
    cursor crDetailPartner
    is
      select PDE.DOC_POSITION_DETAIL_ID
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
           , GCO_GOOD GOO
           , table(GetFilteredDocumentID(vLocalFilter.DOCUMENT_JOB_ID
                                       , vLocalFilter.DTP_DOCUMENT_FROM
                                       , vLocalFilter.DTP_DOCUMENT_TO
                                       , vLocalFilter.DOC_GAUGE_ID
                                       , vLocalFilter.DOC_STATUS_LIST
                                        )
                  ) FLT_DMT
           , table(GetFilteredGoodID(vLocalFilter.GOOD_JOB_ID, vLocalFilter.DTP_GOOD_FROM, vLocalFilter.DTP_GOOD_TO) ) FLT_GOO
           , table(GetFilteredThirdID(vLocalFilter.THIRD_JOB_ID, vLocalFilter.DTP_THIRD_FROM, vLocalFilter.DTP_THIRD_TO) ) FLT_PER
           , table(GetFilteredThirdID(vLocalFilter.THIRD_DELIV_JOB_ID, vLocalFilter.DTP_THIRD_DELIVERY_FROM, vLocalFilter.DTP_THIRD_DELIVERY_TO) ) FLT_PER_DELIV
           , table(GetFilteredThirdID(vLocalFilter.THIRD_ACI_JOB_ID, vLocalFilter.DTP_THIRD_ACI_FROM, vLocalFilter.DTP_THIRD_ACI_TO) ) FLT_PER_ACI
       where DMT.DOC_DOCUMENT_ID = FLT_DMT.column_value
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and PDE.GCO_GOOD_ID = GOO.GCO_GOOD_ID   -- pour utilisation de l'index, trop long sinon
         and POS.GCO_GOOD_ID = FLT_GOO.column_value
         and DMT.PAC_THIRD_ID = FLT_PER.column_value
         and DMT.PAC_THIRD_ACI_ID = FLT_PER_ACI.column_value
         and FLT_PER_DELIV.column_value = nvl(DMT.PAC_THIRD_DELIVERY_ID, DMT.PAC_THIRD_ID)
         and POS.C_DOC_POS_STATUS in('01', '02', '03')
         and POS.C_GAUGE_TYPE_POS not in('71', '81', '91', '101')
         and PDE.PDE_BASIS_DELAY >= nvl(vLocalFilter.DTP_BASIS_DELAY_FROM, PDE.PDE_BASIS_DELAY)
         and PDE.PDE_BASIS_DELAY <= nvl(vLocalFilter.DTP_BASIS_DELAY_TO, PDE.PDE_BASIS_DELAY)
         and PDE.PDE_INTERMEDIATE_DELAY >= nvl(vLocalFilter.DTP_INTER_DELAY_FROM, PDE.PDE_INTERMEDIATE_DELAY)
         and PDE.PDE_INTERMEDIATE_DELAY <= nvl(vLocalFilter.DTP_INTER_DELAY_TO, PDE.PDE_INTERMEDIATE_DELAY)
         and PDE.PDE_FINAL_DELAY >= nvl(vLocalFilter.DTP_FINAL_DELAY_FROM, PDE.PDE_FINAL_DELAY)
         and PDE.PDE_FINAL_DELAY <= nvl(vLocalFilter.DTP_FINAL_DELAY_TO, PDE.PDE_FINAL_DELAY)
         and (   PDE.DIC_DELAY_UPDATE_TYPE_ID = vLocalFilter.DIC_DELAY_UPDATE_TYPE_ID
              or vLocalFilter.DIC_DELAY_UPDATE_TYPE_ID is null)
         and (   PDE.DIC_PDE_FREE_TABLE_1_ID = vLocalFilter.DIC_PDE_FREE_TABLE_1_ID
              or vLocalFilter.DIC_PDE_FREE_TABLE_1_ID is null)
         and (   PDE.DIC_PDE_FREE_TABLE_2_ID = vLocalFilter.DIC_PDE_FREE_TABLE_2_ID
              or vLocalFilter.DIC_PDE_FREE_TABLE_2_ID is null)
         and (   PDE.DIC_PDE_FREE_TABLE_3_ID = vLocalFilter.DIC_PDE_FREE_TABLE_3_ID
              or vLocalFilter.DIC_PDE_FREE_TABLE_3_ID is null);

    -- Curseur sur les détails de position sans filtres sur les partenaires
    cursor crDetailNoPartner
    is
      select PDE.DOC_POSITION_DETAIL_ID
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
           , GCO_GOOD GOO
           , table(GetFilteredDocumentID(vLocalFilter.DOCUMENT_JOB_ID
                                       , vLocalFilter.DTP_DOCUMENT_FROM
                                       , vLocalFilter.DTP_DOCUMENT_TO
                                       , vLocalFilter.DOC_GAUGE_ID
                                       , vLocalFilter.DOC_STATUS_LIST
                                        )
                  ) FLT_DMT
           , table(GetFilteredGoodID(vLocalFilter.GOOD_JOB_ID, vLocalFilter.DTP_GOOD_FROM, vLocalFilter.DTP_GOOD_TO) ) FLT_GOO
       where DMT.DOC_DOCUMENT_ID = FLT_DMT.column_value
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and PDE.GCO_GOOD_ID = GOO.GCO_GOOD_ID   -- pour utilisation de l'index, trop long sinon
         and POS.GCO_GOOD_ID = FLT_GOO.column_value
         and POS.C_DOC_POS_STATUS in('01', '02', '03')
         and POS.C_GAUGE_TYPE_POS not in('71', '81', '91', '101')
         and PDE.PDE_BASIS_DELAY >= nvl(vLocalFilter.DTP_BASIS_DELAY_FROM, PDE.PDE_BASIS_DELAY)
         and PDE.PDE_BASIS_DELAY <= nvl(vLocalFilter.DTP_BASIS_DELAY_TO, PDE.PDE_BASIS_DELAY)
         and PDE.PDE_INTERMEDIATE_DELAY >= nvl(vLocalFilter.DTP_INTER_DELAY_FROM, PDE.PDE_INTERMEDIATE_DELAY)
         and PDE.PDE_INTERMEDIATE_DELAY <= nvl(vLocalFilter.DTP_INTER_DELAY_TO, PDE.PDE_INTERMEDIATE_DELAY)
         and PDE.PDE_FINAL_DELAY >= nvl(vLocalFilter.DTP_FINAL_DELAY_FROM, PDE.PDE_FINAL_DELAY)
         and PDE.PDE_FINAL_DELAY <= nvl(vLocalFilter.DTP_FINAL_DELAY_TO, PDE.PDE_FINAL_DELAY)
         and (   PDE.DIC_DELAY_UPDATE_TYPE_ID = vLocalFilter.DIC_DELAY_UPDATE_TYPE_ID
              or vLocalFilter.DIC_DELAY_UPDATE_TYPE_ID is null)
         and (   PDE.DIC_PDE_FREE_TABLE_1_ID = vLocalFilter.DIC_PDE_FREE_TABLE_1_ID
              or vLocalFilter.DIC_PDE_FREE_TABLE_1_ID is null)
         and (   PDE.DIC_PDE_FREE_TABLE_2_ID = vLocalFilter.DIC_PDE_FREE_TABLE_2_ID
              or vLocalFilter.DIC_PDE_FREE_TABLE_2_ID is null)
         and (   PDE.DIC_PDE_FREE_TABLE_3_ID = vLocalFilter.DIC_PDE_FREE_TABLE_3_ID
              or vLocalFilter.DIC_PDE_FREE_TABLE_3_ID is null);

    blnPartnerRef DOC_GAUGE.GAU_REF_PARTNER%type;
  begin
    -- Rechercher si le gabarit à une Référence partenaire pour savoir
    -- si on doit ou pas filtrer sur les partenaires
    select nvl(max(GAU_REF_PARTNER), 1)
      into blnPartnerRef
      from DOC_GAUGE
     where DOC_GAUGE_ID = vLocalFilter.DOC_GAUGE_ID;

    -- Gabarit avec Référence partenaire
    if blnPartnerRef = 1 then
      for tplDetail in crDetailPartner loop
        pipe row(tplDetail.DOC_POSITION_DETAIL_ID);
      end loop;
    else
      -- Gabarit sans Référence partenaire
      for tplDetail in crDetailNoPartner loop
        pipe row(tplDetail.DOC_POSITION_DETAIL_ID);
      end loop;
    end if;
  end GetFilteredDetailID;
end DOC_SERIAL_DELAY;
