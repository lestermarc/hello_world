--------------------------------------------------------
--  DDL for Package Body GAL_PRJ_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PRJ_FUNCTIONS" 
is
--**********************************************************************************************************--
  function fct_get_sale_price(vPrjId gal_project.gal_project_id%type, vBudId gal_budget.gal_budget_id%type, ivGaugeType in varchar2 default 'ORDER')
    return number
  is
    pSalePrice number;
  begin
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    pSalePrice            := 0;
    gSalePrice            := null;
    pSalePrice            := gal_prj_functions.get_sale_price(vPrjId, vBudId, ivGaugeType);
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    gSalePrice            := null;
    return(pSalePrice);
  end fct_get_sale_price;

--**********************************************************************************************************--
  function fct_get_total_amount(vPrjId gal_project.gal_project_id%type, vBudId gal_budget.gal_budget_id%type)
    return number
  is
    pTotalamount number;
  begin
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    gSalePrice            := null;
    pTotalamount          := 0;
    pTotalamount          := gal_prj_functions.get_total_amount(vPrjId, vBudId);
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    gSalePrice            := null;
    return(pTotalamount);
  end fct_get_total_amount;

--**********************************************************************************************************--
  function fct_get_budget_amount(vPrjId gal_project.gal_project_id%type, vBudId gal_budget.gal_budget_id%type)
    return number
  is
    pBudgetamount number;
  begin
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    gSalePrice            := null;
    pBudgetamount         := 0;
    pBudgetamount         := gal_prj_functions.get_budget_amount(vPrjId, vBudId);
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    gSalePrice            := null;
    return(pBudgetamount);
  end fct_get_budget_amount;

--**********************************************************************************************************--
  procedure Get_Balance_Order_Qty(
    vPrjId               gal_project.gal_project_id%type
  , vBudId               gal_budget.gal_budget_id%type
  , vSalePrice    in out number
  , vBudgetamount in out number
  , vTotalamount  in out number
  , ivGaugeType   in     varchar2 default 'ORDER'
  )
  is
  begin
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    vSalePrice            := 0;
    gSalePrice            := null;
    vBudgetamount         := 0;
    vTotalamount          := 0;
    vSalePrice            := gal_prj_functions.get_sale_price(vPrjId, vBudId, ivGaugeType);
    vBudgetamount         := gal_prj_functions.get_budget_amount(vPrjId, vBudId);
    vTotalamount          := gal_prj_functions.get_total_amount(vPrjId, vBudId);
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    gSalePrice            := null;
  end Get_Balance_Order_Qty;

--**********************************************************************************************************--
  procedure Get_Balance_Order_information(
    vPrjId                  gal_project.gal_project_id%type
  , vBudId                  gal_budget.gal_budget_id%type
  , vSalePrice       in out number
  , vDmtNumber       in out DOC_DOCUMENT.DMT_NUMBER%type
  , vPacThirdId      in out DOC_DOCUMENT.PAC_THIRD_ID%type
  , vDmtDateDocument in out DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , vPdeFinalDelay   in out DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type
  , ivGaugeType      in     varchar2 default 'ORDER'
  )
  is
    pgaudescribe      varchar2(4000);
    vDmtNumberw       DOC_DOCUMENT.DMT_NUMBER%type;
    vPacThirdIdw      DOC_DOCUMENT.PAC_THIRD_ID%type;
    vDmtDateDocumentw DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    vPdeFinalDelayw   DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
  begin
    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    vSalePrice            := 0;
    gSalePrice            := null;
    vdmtnumber            := null;
    vpacthirdid           := null;
    vdmtdatedocument      := null;
    vpdefinaldelay        := null;
    vdmtnumberw           := null;
    vpacthirdidw          := null;
    vdmtdatedocumentw     := null;
    vpdefinaldelayw       := null;

    -- Commande
    if ivGaugeType = 'ORDER' then
      select ';' || nvl(trim(pcs.pc_config.getconfig('GAL_GAUGE_BALANCE_ORDER') ), '') || ';'
        into pgaudescribe
        from dual;
    -- Facture
    elsif ivGaugeType = 'INVOICE' then
      select ';' || nvl(trim(pcs.pc_config.getconfig('GAL_GAUGE_INVOICE') ), '') || ';'
        into pgaudescribe
        from dual;
    end if;

    if Rebuild_TblDocRecord = 1 then
      Init_TblDocRecord(vPrjId, vBudId);
      Rebuild_TblDocRecord  := 0;
    end if;

    vSalePrice            := gal_prj_functions.get_sale_price(vPrjId, vBudId);

    begin
      for LOUPE in (select distinct doc_record_id
                               from table(tableDOC_RECORD) ) loop
        begin
          select dmt_number
               , pac_third_id
               , dmt_date_document
               , pde_final_delay
            into vdmtnumberw
               , vpacthirdidw
               , vdmtdatedocumentw
               , vpdefinaldelayw
            from (select   doc.dmt_number dmt_number
                         , doc.pac_third_id pac_third_id
                         , doc.dmt_date_document dmt_date_document
                         , pde.pde_final_delay pde_final_delay
                         , nvl(pde_final_delay, to_date('31/12/2999', 'DD/MM/YYYY') ) Final_delay
                      from doc_position_detail pde
                         , doc_record dos_pos
                         , doc_position pos
                         , doc_gauge gau
                         , doc_document doc   --,TABLE (tabledoc_record) tdc
                     where not exists(select 1
                                        from doc_document DOC_AVT
                                       where DOC_AVT.DMT_ADDENDUM_OF_DOC_ID = doc.doc_document_id)
                       and not exists(select 1
                                        from doc_document DOC_AVT
                                       where DOC_AVT.DMT_ADDENDUM_SRC_DOC_ID = doc.doc_document_id)
                       and pde.doc_position_id(+) = pos.doc_position_id
                       and dos_pos.doc_record_id(+) = pos.doc_record_id
                       and pos.c_doc_pos_status < '05'
                       and pos.doc_document_id(+) = doc.doc_document_id
                       and gau.doc_gauge_id(+) = doc.doc_gauge_id
                       and pos.pos_imputation = 0
                       --AND pos.doc_record_id = tdc.doc_record_id
                       and pos.doc_record_id = LOUPE.doc_record_id   -- in (select DOC_RECORD_ID FROM table(tableDOC_RECORD))
                       and instr(pgaudescribe, ';' || trim(gau.gau_describe) || ';') <> 0
                  union all
                  select   doc.dmt_number dmt_number
                         , doc.pac_third_id pac_third_id
                         , doc.dmt_date_document dmt_date_document
                         , pde.pde_final_delay pde_final_delay
                         , nvl(pde_final_delay, to_date('31/12/2999', 'DD/MM/YYYY') ) final_delay
                      from doc_position_detail pde
                         , doc_record dos_imp
                         , doc_position_imputation imp
                         , doc_position pos
                         , doc_gauge gau
                         , doc_document doc   --,TABLE (tabledoc_record) tdc
                     where not exists(select 1
                                        from doc_document DOC_AVT
                                       where DOC_AVT.DMT_ADDENDUM_OF_DOC_ID = doc.doc_document_id)
                       and not exists(select 1
                                        from doc_document DOC_AVT
                                       where DOC_AVT.DMT_ADDENDUM_SRC_DOC_ID = doc.doc_document_id)
                       and dos_imp.doc_record_id(+) = imp.doc_record_id
                       and pde.doc_position_id(+) = pos.doc_position_id
                       and imp.doc_position_id(+) = pos.doc_position_id
                       and pos.c_doc_pos_status < '05'
                       and pos.doc_document_id(+) = doc.doc_document_id
                       and gau.doc_gauge_id(+) = doc.doc_gauge_id
                       and pos.pos_imputation = 1
                       --AND imp.doc_record_id = tdc.doc_record_id
                       and imp.doc_record_id = LOUPE.doc_record_id   --in (select DOC_RECORD_ID FROM table(tableDOC_RECORD))
                       and instr(pgaudescribe, ';' || trim(gau.gau_describe) || ';') <> 0
                  order by final_delay asc
                         , dmt_date_document asc)
           where rownum = 1;
        exception
          when no_data_found then
            vdmtnumberw        := null;
            vpacthirdidw       := null;
            vdmtdatedocumentw  := to_date('31/12/3000', 'DD/MM/YYYY');
            vpdefinaldelayw    := to_date('31/12/3000', 'DD/MM/YYYY');
        end;

        if nvl(vpdefinaldelayw, to_date('31/12/2999', 'DD/MM/YYYY') ) <= nvl(vpdefinaldelay, to_date('31/12/2999', 'DD/MM/YYYY') ) then
          if nvl(vdmtdatedocumentw, to_date('31/12/2999', 'DD/MM/YYYY') ) <= nvl(vdmtdatedocument, to_date('31/12/2999', 'DD/MM/YYYY') ) then
            vdmtnumber        := vdmtnumberw;
            vpacthirdid       := vpacthirdidw;
            vdmtdatedocument  := vdmtdatedocumentw;
            vpdefinaldelay    := vpdefinaldelayw;
          end if;
        end if;
      end loop;
    end;

    Rebuild_TblDocRecord  := 1;
    Rebuild_Gal_Spending  := 1;
    gSalePrice            := null;
  end Get_Balance_Order_information;

--**********************************************************************************************************--
  procedure Init_TblDocRecord(vPrjId gal_project.gal_project_id%type, vBudId gal_budget.gal_budget_id%type)
  is      /*
       cursor c_loop_project(RecID gal_project.doc_record_id%type)
       is select DOC_RECORD_ID from GAL_BUDGET where GAL_PROJECT_ID = (select GAL_PROJECT_ID from GAL_PROJECT where GAL_PROJECT.DOC_RECORD_ID = RecId)
                                 connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
                    and GAL_BUDGET.DOC_RECORD_ID IS NOT NULL;
       */
    cursor c_DocRec_prj_Id(RecID gal_project.gal_project_id%type)
    is
      select distinct DOC_RECORD_ID
                 from GAL_BUDGET
                where DOC_RECORD_ID is not null
           start with GAL_PROJECT_ID = RecId
           connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
      union all
      select DOC_RECORD_ID
        from GAL_PROJECT
       where GAL_PROJECT_ID = RecId;

    cursor c_DocRec_bud_Id(RecID gal_project.gal_project_id%type)
    is
      select     DOC_RECORD_ID
            from GAL_BUDGET
           where GAL_BUDGET.DOC_RECORD_ID is not null
      start with GAL_BUDGET.GAL_BUDGET_ID = RecID
      connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID;
  begin
    if vBudId is null   --Affaire/Budget/Sous-budget
                     then
      gTblDocRecord  := tTblDocRecord();

      open c_DocRec_prj_Id(vPrjId);

      fetch c_DocRec_prj_Id
      bulk collect into gTblDocRecord;

      gTblDocRecord.extend(1);

      close c_DocRec_prj_Id;
    end if;

    if vBudId is not null   --Budget/Sous-budget
                         then
      gTblDocRecord  := tTblDocRecord();

      open c_DocRec_bud_Id(vBudId);

      fetch c_DocRec_bud_Id
      bulk collect into gTblDocRecord;

      gTblDocRecord.extend(1);

      close c_DocRec_bud_Id;
    end if;
  end Init_TblDocRecord;

--**********************************************************************************************************--
  function get_sale_price(vPrjId gal_project.gal_project_id%type, vBudId gal_budget.gal_budget_id%type, ivGaugeType in varchar2 default 'ORDER')
    return number
  is
    poi_amount    gal_project.prj_sale_price%type;
    poi_amountw   gal_project.prj_sale_price%type;
    pgaudescribe  varchar2(4000);
    lnUseMultiPly number;
  begin
    if gSalePrice is null then
      poi_amountw  := 0;
      poi_amount   := 0;

      -- Commande
      if ivGaugeType = 'ORDER' then
        lnUseMultiply  := 0;

        select ';' || nvl(trim(pcs.pc_config.getconfig('GAL_GAUGE_BALANCE_ORDER') ), '') || ';'
          into pgaudescribe
          from dual;
      -- Facture
      elsif ivGaugeType = 'INVOICE' then
        lnUseMultiply  := 1;

        select ';' || nvl(trim(pcs.pc_config.getconfig('GAL_GAUGE_INVOICE') ), '') || ';'
          into pgaudescribe
          from dual;
      end if;

      if Rebuild_TblDocRecord = 1 then
        Init_TblDocRecord(vPrjId, vBudId);
        Rebuild_TblDocRecord  := 0;
      end if;

      begin
        for LOUPE in (select distinct doc_record_id
                                 from table(tableDOC_RECORD) ) loop
          select nvl(sum(SALE_PRICE), 0)
            into poi_amountw
            from (select nvl(pos.pos_net_value_excl_b, 0) *(case
                                                              when lnUseMultiply = 0 then 1
                                                              when GAS.C_DOC_JOURNAL_CALCULATION = 'REMOVE' then -1
                                                              else 1
                                                            end) SALE_PRICE
                    from DOC_POSITION POS
                       , DOC_GAUGE GAU
                       , DOC_GAUGE_STRUCTURED GAS
                       , DOC_DOCUMENT DOC
                   where not exists(select 1
                                      from doc_document DOC_AVT
                                     where DOC_AVT.DMT_ADDENDUM_OF_DOC_ID = doc.doc_document_id)
                     and not exists(select 1
                                      from doc_document DOC_AVT
                                     where DOC_AVT.DMT_ADDENDUM_SRC_DOC_ID = doc.doc_document_id)
                     and pos.doc_document_id(+) = doc.doc_document_id
                     and gau.doc_gauge_id(+) = doc.doc_gauge_id
                     and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
                     and pos.c_doc_pos_status < '05'
                     and pos.pos_imputation = 0
                     and pos.doc_record_id = LOUPE.doc_record_id
                     and instr(pgaudescribe, ';' || trim(gau.gau_describe) || ';') <> 0
                  union all
                  select ( (nvl2(imp.poi_amount_b, nvl(pos.pos_net_value_excl_b, 0), 0) * nvl(imp.poi_amount_b, 0) ) /
                          (select nvl(decode(sum(imp2.poi_amount_b), 0, 1, sum(imp2.poi_amount_b) ), 1)
                             from doc_position_imputation imp2
                            where imp2.doc_position_id = imp.doc_position_id)
                         ) *
                         (case
                            when lnUseMultiply = 0 then 1
                            when GAS.C_DOC_JOURNAL_CALCULATION = 'REMOVE' then -1
                            else 1
                          end)
                    from doc_position_imputation imp
                       , doc_position pos
                       , doc_gauge gau
                       , DOC_GAUGE_STRUCTURED GAS
                       , doc_document doc
                   where not exists(select 1
                                      from doc_document DOC_AVT
                                     where DOC_AVT.DMT_ADDENDUM_OF_DOC_ID = doc.doc_document_id)
                     and not exists(select 1
                                      from doc_document DOC_AVT
                                     where DOC_AVT.DMT_ADDENDUM_SRC_DOC_ID = doc.doc_document_id)
                     and imp.doc_position_id(+) = pos.doc_position_id
                     and pos.doc_document_id(+) = doc.doc_document_id
                     and gau.doc_gauge_id(+) = doc.doc_gauge_id
                     and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
                     and pos.c_doc_pos_status < '05'
                     and pos.pos_imputation = 1
                     and imp.doc_record_id = LOUPE.doc_record_id
                     and instr(pgaudescribe, ';' || trim(gau.gau_describe) || ';') <> 0
                     and nvl(imp.poi_amount_b, 0) <> 0);

          poi_amount  := poi_amount + poi_amountw;
        end loop;
      end;

      gSalePrice   := poi_amount;
    else
      poi_amount  := gSalePrice;
    end if;

    return poi_amount;
  end get_sale_price;

--**********************************************************************************************************--
  function get_total_amount(vPrjId gal_project.gal_project_id%type, vBudId gal_budget.gal_budget_id%type)
    return number
  is
    tot_amount gal_project.prj_sale_price%type;
  --tot_amount     gal_project.prj_sale_price%TYPE;
  begin
    tot_amount  := 0;

    --tot_amount := 0;
    if Rebuild_Gal_Spending = 1 then
      if vBudId is null then   --Affaire
        GAL_PROJECT_CONSOLIDATION.GAL_SPENDING_GENERATE(vPrjId, 0, 0, null, 0);   --AGALPROJECTID+AGALBUDGETID+AGALTASKID+ASNAPSHOTDATE+ASNAPSHOTID
      else   --Budget
        GAL_PROJECT_CONSOLIDATION.GAL_SPENDING_GENERATE(vPrjId, vBudId, 0, null, 0);   --AGALPROJECTID+AGALBUDGETID+AGALTASKID+ASNAPSHOTDATE+ASNAPSHOTID
      end if;

      Rebuild_Gal_Spending  := 0;
    end if;

    if vBudId is null then   --Affaire
      begin
        select sum(GSP_TOTAL_AMOUNT)
          into tot_amount
          from GAL_SPENDING_CONSOLIDATED
         where GAL_SPENDING_CONSOLIDATED.GAL_PROJECT_ID = vPrjId
           and GAL_SPENDING_CONSOLIDATED.GAL_BUDGET_ID is null;
      exception
        when no_data_found then
          tot_amount  := 0;
      end;
    else   --Budget
      begin
        select sum(GSP_TOTAL_AMOUNT)
          into tot_amount
          from GAL_SPENDING_CONSOLIDATED
         where GAL_SPENDING_CONSOLIDATED.GAL_BUDGET_ID = vBudId;
      exception
        when no_data_found then
          tot_amount  := 0;
      end;
    end if;

    --tot_margin := gal_prj_functions.get_sale_price(vPrjId,vBudId) - tot_amount;
    return tot_amount;
  end get_total_amount;

--**********************************************************************************************************--
  function get_budget_amount(vPrjId gal_project.gal_project_id%type, vBudId gal_budget.gal_budget_id%type)
    return number
  is
    bud_amount gal_project.prj_sale_price%type;
  --bud_amount     gal_project.prj_sale_price%TYPE;
  begin
    bud_amount  := 0;

    --bud_amount := 0;
    if Rebuild_Gal_Spending = 1 then
      if vBudId is null then   --Affaire
        GAL_PROJECT_CONSOLIDATION.GAL_SPENDING_GENERATE(vPrjId, 0, 0, null, 0);   --AGALPROJECTID+AGALBUDGETID+AGALTASKID+ASNAPSHOTDATE+ASNAPSHOTID
      else   --Budget
        GAL_PROJECT_CONSOLIDATION.GAL_SPENDING_GENERATE(vPrjId, vBudId, 0, null, 0);   --AGALPROJECTID+AGALBUDGETID+AGALTASKID+ASNAPSHOTDATE+ASNAPSHOTID
      end if;

      Rebuild_Gal_Spending  := 0;
    end if;

    if vBudId is null then   --Affaire
      begin
        select sum(GSP_BUDGET_AMOUNT)
          into bud_amount
          from GAL_SPENDING_CONSOLIDATED
         where GAL_SPENDING_CONSOLIDATED.GAL_PROJECT_ID = vPrjId
           and GAL_SPENDING_CONSOLIDATED.GAL_BUDGET_ID is null;
      exception
        when no_data_found then
          bud_amount  := 0;
      end;
    else   --Budget
      begin
        select sum(GSP_BUDGET_AMOUNT)
          into bud_amount
          from GAL_SPENDING_CONSOLIDATED
         where GAL_SPENDING_CONSOLIDATED.GAL_BUDGET_ID = vBudId;
      exception
        when no_data_found then
          bud_amount  := 0;
      end;
    end if;

    --bud_margin := gal_prj_functions.get_sale_price(vPrjId,vBudId) - bud_amount;
    return bud_amount;
  end get_budget_amount;

  /**
  * function tableDOC_RECORD
  * Description
  *    Retourne la liste des Id de DOC_RECORd à prendre en compte dans les analyses
  * @created fp 03.05.2007
  * @lastUpdate Lse 16.08.2007
  * @public
  * @param aRecordIdList : liste de dossier
  * @return tableau représentant DOC_RECORD
  */
  function tableDOC_RECORD
    return tTblDocRecord pipelined
  is
  begin
    for i in 1 .. gTblDocRecord.count loop
      pipe row(gTblDocRecord(i) );
    --dbms_output.put_line(gTblDocRecord(i).doc_record_id);
    end loop;
  end tableDOC_RECORD;
end gal_prj_functions;
