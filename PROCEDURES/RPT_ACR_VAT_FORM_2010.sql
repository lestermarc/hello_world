--------------------------------------------------------
--  DDL for Procedure RPT_ACR_VAT_FORM_2010
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_VAT_FORM_2010" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_00     IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_7      IN       VARCHAR2,
   parameter_10     IN       VARCHAR2,
   parameter_11     IN       VARCHAR2,
   parameter_12     IN       VARCHAR2,
   parameter_13     IN       VARCHAR2,
   parameter_15     IN       VARCHAR2
)
/**
*Description

 Used for report ACR_VAT_FORM_OFF
*@created JLIU 04.JUNE.2009
*@lastUpdate  4.jan.2010
*@public
*@PARAM parameter_0   Year(from)
*@PARAM parameter_1   Month(from)
*@PARAM parameter_2   Day(from)
*@PARAM parameter_3   Year(to)
*@PARAM parameter_4   Month(to)
*@PARAM parameter_5   Day(to)
*@PARAM parameter_6   ACC_NUMBER(from)
*@PARAM parameter_7   ACC_NUMBER(to)
*@PARAM parameter_10  C_TYPE_CUMUL
*@PARAM parameter_11  C_TYPE_CUMUL
*@PARAM parameter_12  C_TYPE_CUMUL
*@PARAM parameter_13  C_TYPE_CUMUL
*@PARAM parameter_15  vatdetaccountid
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
   vtd_number    varchar2(10);
   vtd_year      varchar2(10);
   vtd_type_cumul varchar2(40);
BEGIN



 IF parameter_00 IS NOT NULL
   THEN
      act_functions.date_from :=
         TO_DATE (   parameter_00
                  || LPAD (parameter_1, 2, '0')
                  || LPAD (parameter_2, 2, '0'),
                  'YYYYMMDD'
                 );
   END IF;

   IF parameter_3 IS NOT NULL
   THEN
      act_functions.date_to :=
         TO_DATE (   parameter_3
                  || LPAD (parameter_4, 2, '0')
                  || LPAD (parameter_5, 2, '0'),
                  'YYYYMMDD'
                 );
   END IF;

   IF     (parameter_15 IS NOT NULL)
      AND (LENGTH (TRIM (parameter_15)) > 0)
      AND (parameter_15 <> '0')
   THEN
      act_functions.vat_det_acc_id := parameter_15;
      select VTD_NUMBER, FYE_NO_EXERCICE  into vtd_number, vtd_year
      from ACT_VAT_DET_ACCOUNT act, acs_financial_year yea
      where act.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
      and  ACT_VAT_DET_ACCOUNT_ID = parameter_15;

   END IF;


   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   vtd_type_cumul := '';
   if parameter_10 = '1' then
     vtd_type_cumul := vtd_type_cumul||'INT,';
   end if;
   if parameter_11 = '1' then
     vtd_type_cumul := vtd_type_cumul||'EXT,';
   end if;
   if parameter_12 = '1' then
     vtd_type_cumul := vtd_type_cumul||'PRE,';
   end if;
   if parameter_13 = '1' then
     vtd_type_cumul := vtd_type_cumul||'ENG,';
   end if;


  delete from ACR_VAT_RPT_TEMP;

insert into ACR_VAT_RPT_TEMP
  (
  SELECT     (SELECT TCO.ACS_VAT_DET_ACCOUNT_ID FROM ACS_TAX_CODE TCO WHERE
             TAX.ACS_TAX_CODE_ID = TCO.ACS_TAX_CODE_ID )  acs_vat_det_account_id,
             vtd_number,
             vtd_year,
             ACC.ACC_NUMBER TAx_number,
             (select FIN.ACC_NUMBER FROM ACS_ACCOUNT FIN WHERE imp.acs_financial_account_id = FIN.acs_account_id) ACC_NUMBER,
             (SELECT DES_DESCRIPTION_SUMMARY FROM ACS_DESCRIPTION DES, ACS_ACCOUNT ACC
             WHERE  ACC.ACS_ACCOUNT_ID = DES.ACS_ACCOUNT_ID
                   AND DES.PC_LANG_ID = vpc_lang_id
                   AND imp.acs_financial_account_id = ACC.acs_account_id) tax_description,
             IMP.C_GENRE_TRANSACTION,
             tax.tax_included_excluded,
             tax.tax_vat_amount_fc,
             tax.tax_vat_amount_lc,
             tax.tax_reduction,
             tax.ht_lc,
             tax.ttc_lc,
             tax.ht_fc,
             tax.ttc_fc,
             tax.imf_value_date,
             tax.act_fin_imput_origin_id,
             TAX.TAX_RATE,
             TAX.DIV_NUMBER,
             TAX.DOC_NUMBER,
             TAX.JOU_NUMBER,
             imp.imf_description,
             imp.imf_exchange_rate,
             imp.imf_transaction_date imf_transaction_date_fin,
             imp.doc_date_delivery,
             imp.pac_person_id,
             (SELECT TCO.DIC_NO_POS_CALC_SHEET4_ID FROM ACS_TAX_CODE TCO WHERE
             TAX.ACS_TAX_CODE_ID = TCO.ACS_TAX_CODE_ID ) DIC_NO_POS_CALC_SHEET4_ID,
             (SELECT TCO.DIC_NO_POS_CALC_SHEET5_ID FROM ACS_TAX_CODE TCO WHERE
             TAX.ACS_TAX_CODE_ID = TCO.ACS_TAX_CODE_ID ) DIC_NO_POS_CALC_SHEET5_ID,
             (SELECT TCO.DIC_NO_POS_CALC_SHEET6_ID FROM ACS_TAX_CODE TCO WHERE
             TAX.ACS_TAX_CODE_ID = TCO.ACS_TAX_CODE_ID ) DIC_NO_POS_CALC_SHEET6_ID,
             '       ' DECOMPTE_POSITION,
             case when c_genre_transaction in ('1','5','9') then 'N' else 'Y' end reduction,
             0 AMOUNT,
             0 OTHER_AMOUNT
             FROM
             v_act_fin_imputation_date imp,
             v_act_det_tax_date tax,
             act_document doc,
             v_act_journal jou,
             acs_account acc
             WHERE imp.act_financial_imputation_id = tax.act_financial_imputation_id
                   AND IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   AND DOC.ACT_JOB_ID = JOU.ACT_JOB_ID
                   AND TAX.ACS_TAX_CODE_ID = ACC.ACS_ACCOUNT_ID
                   AND acc.acc_number >= nvl(parameter_6,'(')
                   AND acc.acc_number <= nvl(parameter_7,'}')
                   AND jou.c_sub_set = 'ACC'
                   AND instr(vtd_type_cumul, tax.c_type_cumul) > 0
                   AND nvl(tax.tax_tmp_vat_encashment, 0) = 0
                                      );

         delete from ACR_VAT_FINAL_RPT_TEMP;

         -- 1er run pour charge le 1er dico de positionnement
         insert into ACR_VAT_FINAL_RPT_TEMP (
         select ACS_VAT_DET_ACCOUNT_ID,
             vtd_number,
             vtd_year,
             tax_number,
             ACC_NUMBER,
             tax_description,
             C_GENRE_TRANSACTION,
             tax_included_excluded,
             tax_vat_amount_fc,
             tax_vat_amount_lc,
             tax_reduction,
             ht_lc,
             ttc_lc,
             ht_fc,
             ttc_fc,
             imf_value_date,
             act_fin_imput_origin_id,
             TAX_RATE,
             DIV_NUMBER,
             DOC_NUMBER,
             JOU_NUMBER,
             imf_description,
             imf_exchange_rate,
             imf_transaction_date_fin,
             doc_date_delivery,
             pac_person_id,
             DIC_NO_POS_CALC_SHEET4_ID,
             DIC_NO_POS_CALC_SHEET5_ID,
             DIC_NO_POS_CALC_SHEET6_ID,
             DIC_NO_POS_CALC_SHEET4_ID,
             reduction,
             case when DIC_NO_POS_CALC_SHEET4_ID in ( '200', '205', '220',  '221', '225', '230', '280', '900', '910') and REDUCTION = 'N' then ht_lc *-1
                  when DIC_NO_POS_CALC_SHEET4_ID in ( '235') and REDUCTION = 'Y' then ht_lc
                  else 0
             end TAX_AMOUNT,
             case when DIC_NO_POS_CALC_SHEET4_ID in ('380') and tax_included_excluded = 'S' then ht_lc
                  else 0
             end  TURNOVER_AMOUNT
             from ACR_VAT_RPT_TEMP where  DIC_NO_POS_CALC_SHEET4_ID is not null);


-- 2¨¨me run pour charge le 2¨¨me dico de positionnement
         insert into ACR_VAT_FINAL_RPT_TEMP (
         select ACS_VAT_DET_ACCOUNT_ID,
             vtd_number,
             vtd_year,
             tax_number,
             ACC_NUMBER,
             tax_description,
             C_GENRE_TRANSACTION,
             tax_included_excluded,
             tax_vat_amount_fc,
             tax_vat_amount_lc,
             tax_reduction,
             ht_lc,
             ttc_lc,
             ht_fc,
             ttc_fc,
             imf_value_date,
             act_fin_imput_origin_id,
             TAX_RATE,
             DIV_NUMBER,
             DOC_NUMBER,
             JOU_NUMBER,
             imf_description,
             imf_exchange_rate,
             imf_transaction_date_fin,
             doc_date_delivery,
             pac_person_id,
             DIC_NO_POS_CALC_SHEET4_ID,
             DIC_NO_POS_CALC_SHEET5_ID,
             DIC_NO_POS_CALC_SHEET6_ID,
             DIC_NO_POS_CALC_SHEET5_ID,
             reduction,
             case when DIC_NO_POS_CALC_SHEET5_ID in ( '220','221', '225', '230', '280') and REDUCTION = 'N' then ht_lc *-1
                  when DIC_NO_POS_CALC_SHEET5_ID in ( '235') and REDUCTION = 'Y' then ht_lc
                  else 0
             end TAX_AMOUNT,
             0  TURNOVER_AMOUNT
             from ACR_VAT_RPT_TEMP where  DIC_NO_POS_CALC_SHEET5_ID is not null);


-- 3¨¨me run pour charge le 3¨¨me dico de positionnement
         insert into ACR_VAT_FINAL_RPT_TEMP (
         select ACS_VAT_DET_ACCOUNT_ID,
             vtd_number,
             vtd_year,
             tax_number,
             ACC_NUMBER,
             tax_description,
             C_GENRE_TRANSACTION,
             tax_included_excluded,
             tax_vat_amount_fc,
             tax_vat_amount_lc,
             tax_reduction,
             ht_lc,
             ttc_lc,
             ht_fc,
             ttc_fc,
             imf_value_date,
             act_fin_imput_origin_id,
             TAX_RATE,
             DIV_NUMBER,
             DOC_NUMBER,
             JOU_NUMBER,
             imf_description,
             imf_exchange_rate,
             imf_transaction_date_fin,
             doc_date_delivery,
             pac_person_id,
             DIC_NO_POS_CALC_SHEET4_ID,
             DIC_NO_POS_CALC_SHEET5_ID,
             DIC_NO_POS_CALC_SHEET6_ID,
             DIC_NO_POS_CALC_SHEET6_ID,
             reduction,
             case when DIC_NO_POS_CALC_SHEET6_ID in ('300','310','340','380') then tax_vat_amount_lc *-1
                  when DIC_NO_POS_CALC_SHEET6_ID in ( '400','405','410','415','420')  then tax_vat_amount_lc
                  else 0
             end TAX_AMOUNT,
             case when DIC_NO_POS_CALC_SHEET6_ID in ('300','310','340') then ht_lc *-1
                  else 0
             end TURNOVER_AMOUNT
             from ACR_VAT_RPT_TEMP where  DIC_NO_POS_CALC_SHEET6_ID is not null);


OPEN arefcursor FOR
      SELECT  decompte_position, sum(TAX_aMOUNT) tax_Amount , sum(TURNOVER_AMOUNT) turnover_amount, count(*) record_count, MAX(vtd_number) VTD_NUMBER, MAX(vtd_year) FYE_NO_EXERCICE,ACS_VAT_DET_ACCOUNT_ID
      from ACR_VAT_FINAL_RPT_TEMP
      group by decompte_position,ACS_VAT_DET_ACCOUNT_ID  ;

END rpt_acr_vat_form_2010;
