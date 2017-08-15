--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_TAXES_MP_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_TAXES_MP_SUB" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_4    in     DOC_POSITION.DOC_DOC_POSITION_ID%type
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
*Description - Used for report DOC_STD_3

*@created VHA 15 January 2013
*@lastUpdate SMA 1 April 2015
*@public
*@param parameter_4:  DOC_POSITION_ID
*/
  vpc_lang_id  pcs.pc_lang.pc_lang_id%type;
  vpc_comp_id  pcs.pc_comp.pc_comp_id%type;
  vpc_conli_id pcs.pc_conli.pc_conli_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  pcs.PC_I_LIB_SESSION.setcompanyid(pc_comp_id);
  pcs.PC_I_LIB_SESSION.setconliid(pc_conli_id);
  vpc_lang_id   := pcs.PC_I_LIB_SESSION.getuserlangid;
  vpc_comp_id   := pcs.PC_I_LIB_SESSION.getcompanyid;
  vpc_conli_id  := pcs.PC_I_LIB_SESSION.getconliid;

  open arefcursor for
    select   DOA.DOC_POSITION_ID
           , DOA.GCO_ALLOY_ID
           , DOA.DOA_WEIGHT_DELIVERY
           , DOA.DOA_WEIGHT_DELIVERY_TH
           , DOA.DOA_LOSS
           , DOA.DOA_LOSS_TH
           , DFA.DFA_RATE
           , DFA.DFA_RATE_TH
           , DFA.DFA_RATE_DATE
           , PCH.PCH_DESCRIPTION GAL_ALLOY_REF
           , (select PCS.PC_FUNCTIONS.GetDescodeDescr('C_THIRD_MATERIAL_RELATION_TYPE', DOC.C_THIRD_MATERIAL_RELATION_TYPE, vpc_lang_id)
                from doc_document doc
               where DOC.DOC_DOCUMENT_ID = DOA.DOC_DOCUMENT_ID) THIRD_MAT_REL_TYPE_DESC
           , PCH.PCH_DESCRIPTION
           , PCH.PCH_AMOUNT
           , CRG.CRG_NAME
           , case
               when(    (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainSal(DOA.DOC_DOCUMENT_ID) = 1)
                         and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                              or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             )
                        )
                    or (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainPur(DOA.DOC_DOCUMENT_ID) = 1)
                        and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                            )
                       )
                   ) then 'SURCHARGE'
               else case
               when(    (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainSal(DOA.DOC_DOCUMENT_ID) = 1)
                         and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                              or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             )
                        )
                    or (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainPur(DOA.DOC_DOCUMENT_ID) = 1)
                        and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                            )
                       )
                   ) then 'INCREASE'
               else 'OTHER'
             end
             end CRG_TYPE
           , case
               when(    (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainSal(DOA.DOC_DOCUMENT_ID) = 1)
                         and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                              or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             )
                        )
                    or (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainPur(DOA.DOC_DOCUMENT_ID) = 1)
                        and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                            )
                       )
                   ) then 1
               else case
               when(    (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainSal(DOA.DOC_DOCUMENT_ID) = 1)
                         and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                              or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             )
                        )
                    or (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainPur(DOA.DOC_DOCUMENT_ID) = 1)
                        and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                            )
                       )
                   ) then 2
               else 3
             end
             end ORDER_TYPE
           , TRF.DIC_TARIFF_ID
           , TRF.DIC_DESCR
        from DOC_POSITION_ALLOY DOA
           , DOC_FOOT_ALLOY DFA
           , DOC_POSITION_CHARGE PCH
           , PTC_CHARGE CRG
           , (select POS.DOC_DOCUMENT_ID
                   , POS.DOC_POSITION_ID
                   , DIC.DIC_TARIFF_ID
                   , DIC.DIC_DESCR
                from DIC_TARIFF DIC
                   , DOC_POSITION POS
               where DIC.DIC_TARIFF_ID = POS.DIC_TARIFF_ID) TRF
       where DFA.DOC_DOC_DOCUMENT_ID(+) = DOA.DOC_DOCUMENT_ID
         and PCH.DOC_POSITION_ID(+) = DOA.DOC_POSITION_ID
         and TRF.DOC_POSITION_ID(+) = DOA.DOC_POSITION_ID
         and CRG.PTC_CHARGE_ID(+) = PCH.PTC_CHARGE_ID
         and DOA.DOC_POSITION_ID = parameter_4
         and DOA.GCO_ALLOY_ID is not null
         and (    (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainSal(DOA.DOC_DOCUMENT_ID) = 1)
                   and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                        or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                        or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                        or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                       )
                  )
              or (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainPur(DOA.DOC_DOCUMENT_ID) = 1)
                  and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                       or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                       or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                       or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                      )
                 )
             )
    order by case
               when(    (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainSal(DOA.DOC_DOCUMENT_ID) = 1)
                         and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                              or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             )
                        )
                    or (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainPur(DOA.DOC_DOCUMENT_ID) = 1)
                        and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                            )
                       )
                   ) then 1
               else case
               when(    (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainSal(DOA.DOC_DOCUMENT_ID) = 1)
                         and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                              or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_SAL') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             )
                        )
                    or (     (DOC_I_LIB_DOCUMENT.IsDocAdminDomainPur(DOA.DOC_DOCUMENT_ID) = 1)
                        and (    (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                             or (instr(';' || PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_PUR') || ';', ';' || CRG.CRG_NAME || ';') > 0)
                            )
                       )
                   ) then 2
               else 3
             end
             end;
end RPT_DOC_STD_3_TAXES_MP_SUB;
