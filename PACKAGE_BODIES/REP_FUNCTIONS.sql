--------------------------------------------------------
--  DDL for Package Body REP_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml de réplication.
 *
 * Le générateur Xml Oracle ne traite pas correctement les nombres, ainsi que
 * les champs une date contenant une partie temp.
 * Afin de contourner ce problème, les paramètres NLS suivant sont modifié pour
 * le temps de l'appel d'un méthode de génération d'un document Xml :
 *   o NLS_NUMERIC_CHARACTERS
 *   o NLS_DATE_FORMAT
 *   o NLS_TIMESTAMP_FORMAT
 *
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 * @author fperotto
 * @author pvogel
 * @author ngomes
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

--
-- Internal declarations
--

  /** Transformateur utilisé par la méthode AddDocumentDirective */
  gx_add_directive XMLType;

  /** Curseur des transformateurs standard. */
  cursor gcur_standard_xsl(
    iv_object_name IN rep_transformer.rep_reference%TYPE)
  is
    select REP_XSL_OUT
    from REP_TRANSFORMER
    where REP_REFERENCE = iv_object_name and REP_USE_XSL_OUT = 1;

  /** Curseur des transformateurs spécifiques aux articles. */
  cursor gcur_good_categ_xsl(
    in_good_id IN gco_good.gco_good_id%TYPE,
    iv_object_name IN rep_transformer.rep_reference%TYPE)
  is
    select CAT_XSLT_OUT
    from GCO_GOOD_CATEGORY
    where GCO_GOOD_CATEGORY_ID = (select GCO_GOOD_CATEGORY_ID from GCO_GOOD
                                  where GCO_GOOD_ID = in_good_id) and
      CAT_XSLT_FLAG_OUT = 1
    union all
    select REP_XSL_OUT
    from REP_TRANSFORMER
    where REP_REFERENCE = iv_object_name and REP_USE_XSL_OUT = 1;


function p_get_xsl_add_directive return XMLType is
begin
  if (gx_add_directive is null) then
    gx_add_directive := XMLType(
      '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' ||
        '<xsl:param name="Directive"/>'||
        '<xsl:template match="/*">' ||
          '<xsl:copy>' ||
            '<xsl:apply-templates select="@*|node()"/>' ||
          '</xsl:copy>' ||
        '</xsl:template>' ||
        '<xsl:template match="/*/*">' ||
          '<xsl:element name="{name()}">' ||
            '<xsl:copy-of select="@*"/>' ||
            '<xsl:element name="DOC_SEARCH_MODE">' ||
              '<xsl:value-of select="$Directive"/>' ||
            '</xsl:element>' ||
            '<xsl:copy-of select="node()"/>' ||
          '</xsl:element>' ||
        '</xsl:template>' ||
      '</xsl:stylesheet>');
  end if;
  return gx_add_directive;
end;

/**
 * Application du transformateur ix_xslt au document ix_document.
 * @param ix_document  Document Xml original.
 * @param BOName  Nom de l'objet de gestion à utiliser.
 * @return  Le document Xml transformé par le transformateur xslt spécifié.
 * pour l'objet de base.
 */
function p_ApplyTransformer(ix_document IN XMLType, ix_xslt IN CLOB)
  return XMLType
is
begin
  if (ix_document is not null and ix_xslt is not null and dbms_lob.getlength(ix_xslt) > 0) then
    return ix_document.transform(XMLType(ix_xslt));
  end if;

  return ix_document;
end;

/**
 * Application du transformateur générique associé à un object de base.
 * @param ix_document  Document Xml original.
 * @param lv_object_name  Nom de l'objet de gestion à utiliser.
 * @return  Le document Xml transformé par le transformateur xslt spécifié
 * pour l'objet de base.
 */
function p_ApplyTransformerText(ix_document IN XMLType, iv_object_name IN VARCHAR2)
  return XMLType
is
  lv_xslt CLOB;
begin
  if (ix_document is not null and iv_object_name is not null) then
    open gcur_standard_xsl(iv_object_name);
    fetch gcur_standard_xsl into lv_xslt;
    close gcur_standard_xsl;
    return p_ApplyTransformer(ix_document, lv_xslt);
  end if;

  return ix_document;
end;

/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param ix_document  Document Xml original.
 * @return Un CLob contenant le texte du document Xml, ainsi qu'un prologue
 *         complet correspondant à l'encodage de la base.
 */
function p_XmlToClob(ix_document IN XMLType) return CLob is
begin
  if (ix_document is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| ix_document.getClobVal();
  end if;

  return null;
end;


function p_check_online_enqueue(
  iv_object_name IN rep_to_publish.rpt_basic_object_name%TYPE,
  in_enqueue IN T_ENQUEUE_MODE)
  return INTEGER
is
  ln_result INTEGER;
begin
  ln_result := in_enqueue;

  -- Rechercher du mode de transmission (différé ou online)
  if (ln_result = ENQUEUE_NO_FORCE) then
    begin
      select REP_ONLINE_ENQUEUE
        into ln_result
        from REP_TRANSFORMER
       where REP_REFERENCE = iv_object_name;
    exception
      when NO_DATA_FOUND then
        ln_result := 0;
      when OTHERS then
        return 0;
    end;
  end if;
  return ln_result;
end;

function p_publish(
  Id IN rep_to_publish.rpt_id%TYPE,
  iv_object_name IN rep_to_publish.rpt_basic_object_name%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE)
  return INTEGER
is
  ln_exists INTEGER := 0;
  ln_enqueue BINARY_INTEGER := 0;
  lv_enqueue_proc VARCHAR2(32767);
begin
  -- vérification du mode d'envoi du document
  ln_enqueue := p_check_online_enqueue(iv_object_name, ForceEnqueue);

  if (ln_enqueue = ENQUEUE_NO_FORCE) then
    -- Recherche de l'existance d'un enregistrement dans la table de publication
    begin
      select Count(*)
        into ln_exists
        from REP_TO_PUBLISH
       where RPT_ID = Id and RPT_BASIC_OBJECT_NAME = iv_object_name;
    exception
      when NO_DATA_FOUND then
        ln_exists := 0;
      when OTHERS then
        ln_exists := SQLCODE;
    end;

    if (ln_exists = 0) then
      insert into REP_TO_PUBLISH
      (RPT_ID, RPT_BASIC_OBJECT_NAME)
      values
      (Id, iv_object_name);
      return 1;
    elsif (ln_exists > 0) then
      return 1;
    else
      return ln_exists;
    end if;
  else -- if (ln_enqueue = ENQUEUE_FORCE) then
    begin
      select REP_ENQUEUE_PROC
        into lv_enqueue_proc
        from REP_TRANSFORMER
       where REP_REFERENCE = iv_object_name;
    exception
      when NO_DATA_FOUND then
        lv_enqueue_proc := null;
    end;
    if (lv_enqueue_proc is null) then
      lv_enqueue_proc := case iv_object_name
        when 'GCO_PRODUCT' then 'GCO_QUE_FCT.USE_ENQUEUE_GOOD'
        when 'GCO_GOOD_CATEGORY' then 'GCO_QUE_FCT.USE_ENQUEUE_CATEGORY'
        when 'GCO_ATTRIBUTE_FIELDS' then 'GCO_QUE_FCT.USE_ENQUEUE_ATTRIBUTE_FIELDS'
        when 'GCO_ALLOY' then 'GCO_QUE_FCT.USE_ENQUEUE_ALLOY'
        when 'GCO_PRODUCT_GROUP' then 'GCO_QUE_FCT.USE_ENQUEUE_PRODUCT_GROUP'
        when 'GCO_QUALITY_STATUS' then 'GCO_QUE_FCT.USE_ENQUEUE_QUALITY_STATUS'
        when 'GCO_QUALITY_STAT_FLOW' then 'GCO_QUE_FCT.USE_ENQUEUE_QUALITY_STAT_FLOW'
        when 'PPS_NOMENCLATURE' then 'PPS_QUE_FCT.USE_ENQUEUE_NOMENCLATURE'
        when 'PAC_ADDRESS' then 'PAC_QUE_FCT.USE_ENQUEUE_PERSON'
        when 'PAC_PERSON_ASSOCIATION' then 'PAC_QUE_FCT.USE_ENQUEUE_ASSOCIATION'
        when 'ACS_ACCOUNT' then 'ACS_QUE_FCT.USE_ENQUEUE_ACCOUNT'
        when 'ACS_EVALUATION_METHOD' then 'ACS_QUE_FCT.USE_ENQUEUE_EVALUATION_METHOD'
        when 'ACS_INTEREST_CATEG' then 'ACS_QUE_FCT.USE_ENQUEUE_INTEREST_CATEG'
        when 'ACS_INT_CALC_METHOD' then 'ACS_QUE_FCT.USE_ENQUEUE_INT_CALC_METHOD'
        when 'STM_DISTRIBUTION_UNIT' then 'GCO_QUE_FCT.USE_ENQUEUE_DISTRIBUTION_UNIT'
        when 'DOC_RECORD' then 'DOC_QUE_FCT.USE_ENQUEUE_RECORD'
        when 'DOC_RECORD_CATEGORY' then 'DOC_QUE_FCT.USE_ENQUEUE_RECORD_CATEGORY'
        when 'DOC_RECORD_CAT_LINK_TYPE' then 'DOC_QUE_FCT.USE_ENQUEUE_RCO_CAT_LNK_TYPE'
        when 'FAL_SCHEDULE_PLAN' then 'FAL_QUE_FCT.USE_ENQUEUE_SCH_PLAN'
        when 'FAL_TASK' then 'FAL_QUE_FCT.USE_ENQUEUE_TASK'
        when 'FAL_FACTORY_FLOOR' then 'FAL_QUE_FCT.USE_ENQUEUE_FAC_FLOOR'
      end;
      -- Ajout des paramètres génériques de l'appel de l'enqueue
      if (lv_enqueue_proc is not null) then
        lv_enqueue_proc := lv_enqueue_proc||'(MAIN_ID,''KEY'');';
      end if;
    end if;
    if (lv_enqueue_proc is not null) then
      lv_enqueue_proc := RTrim(lv_enqueue_proc, Chr(10)||' ');
      if (Substr(lv_enqueue_proc, -1) != ';') then
        lv_enqueue_proc := lv_enqueue_proc||';';
      end if;
      EXECUTE IMMEDIATE
        'DECLARE MAIN_ID NUMBER := '||to_char(Id)||';'||
        ' BEGIN '||lv_enqueue_proc||' END;';
      return 1;
    else
      return 0;
    end if;
  end if;

  exception
    when OTHERS then
      return SQLCODE;
end;


--
-- Public declarations
--

function AddDocumentDirective(
  ix_document IN XMLType,
  iv_directive IN VARCHAR2)
  return XMLType
is
begin
  if (ix_document is not null and
      iv_directive is not null and
      iv_directive != rep_utils.USE_KEY_VALUE) then
    -- Transformation du document pour y ajouter la directive
    return ix_document.transform(p_get_xsl_add_directive(), 'Directive="'''||iv_directive||'''"');
  end if;

  return ix_document;
end;


procedure PublishArticle(
  Id IN gco_good.gco_good_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishArticle(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishArticle(
  Id IN gco_good.gco_good_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
  nReplicable INTEGER := 0;
  nGoodActive INTEGER := 0;
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    select g.c_good_status,
      Nvl((select c.c_replication_type from gco_good_category c
           where c.gco_good_category_id = g.gco_good_category_id),0) c_replication_type
      into nGoodActive, nReplicable
    from gco_good g
    where g.gco_good_id = Id;
    if (nReplicable = 1) and (nGoodActive in (GCO_I_LIB_CONSTANT.gcGoodStatusActive, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended)) then
      vResult := p_publish(Id, 'GCO_PRODUCT', ForceEnqueue);
    end if;
  end if;
end;

procedure PublishGoodAlloy(
  Id IN gco_good.gco_good_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishGoodAlloy(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishGoodAlloy(
  Id IN gco_good.gco_good_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    vResult := p_publish(Id, 'GCO_ALLOY', ForceEnqueue);
  end if;
end;

procedure PublishGoodCategory(
  Id IN gco_good_category.gco_good_category_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishGoodCategory(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishGoodCategory(
  Id IN gco_good_category.gco_good_category_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    vResult := p_publish(Id, 'GCO_GOOD_CATEGORY', ForceEnqueue);
    if (vResult = 1) then
      rep_functions.PublishAttributeFields(Id, ForceEnqueue, vResult);
    end if;
  end if;
end;

procedure PublishAttributeFields(
  Id IN gco_attribute_fields.gco_attribute_fields_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishAttributeFields(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishAttributeFields(
  Id IN gco_attribute_fields.gco_attribute_fields_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    vResult := p_publish(Id, 'GCO_ATTRIBUTE_FIELDS', ForceEnqueue);
  end if;
end;

procedure PublishProductGroup(
  Id IN gco_good.gco_good_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishProductGroup(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishProductGroup(
  Id IN gco_good.gco_good_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    vResult := p_publish(Id, 'GCO_PRODUCT_GROUP', ForceEnqueue);
  end if;
end;

procedure PublishQualityStatus(
  Id IN gco_quality_status.gco_quality_status_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishQualityStatus(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end PublishQualityStatus;

procedure PublishQualityStatus(
  Id IN gco_quality_status.gco_quality_status_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    vResult := p_publish(Id, 'GCO_QUALITY_STATUS', ForceEnqueue);
  end if;
end PublishQualityStatus;

procedure PublishQualityStatusFlow(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishQualityStatusFlow(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end PublishQualityStatusFlow;

procedure PublishQualityStatusFlow(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    vResult := p_publish(Id, 'GCO_QUALITY_STAT_FLOW', ForceEnqueue);
  end if;
end PublishQualityStatusFlow;

procedure PublishDIU(
  Id IN stm_distribution_unit.stm_distribution_unit_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishDIU(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishDIU(
  Id IN stm_distribution_unit.stm_distribution_unit_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication du bien
    vResult := p_publish(Id, 'STM_DISTRIBUTION_UNIT', ForceEnqueue);
  end if;
end;

procedure PublishBOM(
  BOMId IN pps_nomenclature.pps_nomenclature_id%TYPE,
  GoodId IN gco_good.gco_good_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishBOM(BOMId, GoodId, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishBOM(
  BOMId IN pps_nomenclature.pps_nomenclature_id%TYPE,
  GoodId IN gco_good.gco_good_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
  nReplicable INTEGER := 0;
  nGoodActive INTEGER := 0;
  nCurrentGoodActive INTEGER := 2; -- Actif par défaut
begin
  vResult := 2;
  if (BOMId is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    -- nous sommes dans une session PCS, ok pour une éventuelle
    -- réplication de la nomenclature
    if GoodId is not null then
      select c_good_status into nCurrentGoodActive
      from gco_good
      where gco_good_id = GoodId;
    end if;

    if nCurrentGoodActive in (GCO_I_LIB_CONSTANT.gcGoodStatusActive, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended)  then
      select g.c_good_status,
        Nvl((select c.c_replication_type from gco_good_category c
             where c.gco_good_category_id = g.gco_good_category_id),0) c_replication_type
        into nGoodActive, nReplicable
      from gco_good g
      where g.gco_good_id =
          (select gco_good_id from pps_nomenclature
           where pps_nomenclature_id = BOMId);
      if (nReplicable = 1) and (nGoodActive in (GCO_I_LIB_CONSTANT.gcGoodStatusActive, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended) ) then
        -- le bien est replicable, et le composant est actif
        vResult := p_publish(BOMId, 'PPS_NOMENCLATURE', ForceEnqueue);
      end if;
    end if;
  end if;
end;

procedure PublishPerson(
  Id IN pac_person.pac_person_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishPerson(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishPerson(
  Id IN pac_person.pac_person_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'PAC_ADDRESS', ForceEnqueue);
    -- La publication des associations liées à la personne sera exécutée dans la
    -- méthode PAC_QUE_FCT.USE_ENQUEUE_PERSON
    -- if (vResult = 1) then
    --   rep_functions.PublishAssociation(Id, ForceEnqueue, vResult);
    -- end if;
  end if;
end;

procedure PublishAssociation(
  Id IN pac_person.pac_person_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishAssociation(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishAssociation(
  Id IN pac_person.pac_person_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'PAC_PERSON_ASSOCIATION', ForceEnqueue);
  end if;
end;

procedure PublishAccount(
  Id IN acs_account.acs_account_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishAccount(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishAccount(
  Id IN acs_account.acs_account_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'ACS_ACCOUNT', ForceEnqueue);
  end if;
end;

procedure PublishEvaluationMethod(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishEvaluationMethod(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishEvaluationMethod(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'ACS_EVALUATION_METHOD', ForceEnqueue);
  end if;
end;

procedure PublishInterestCateg(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishInterestCateg(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishInterestCateg(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'ACS_INTEREST_CATEG', ForceEnqueue);
  end if;
end;

procedure PublishInterestCalcMethod(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishInterestCalcMethod(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishInterestCalcMethod(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'ACS_INT_CALC_METHOD', ForceEnqueue);
  end if;
end;

procedure PublishDocRecord(
  Id IN doc_record.doc_record_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishDocRecord(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishDocRecord(
  Id IN doc_record.doc_record_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'DOC_RECORD', ForceEnqueue);
  end if;
end;

procedure PublishDocRecordCategory(
  Id IN doc_record_category.doc_record_category_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishDocRecordCategory(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishDocRecordCategory(
  Id IN doc_record_category.doc_record_category_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'DOC_RECORD_CATEGORY', ForceEnqueue);
  end if;
end;

procedure PublishDocRecordCatLinkType(
  Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishDocRecordCatLinkType(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishDocRecordCatLinkType(
  Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (Id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(Id, 'DOC_RECORD_CAT_LINK_TYPE', ForceEnqueue);
  end if;
end;

procedure PublishSchedulePlan(
  Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishSchedulePlan(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishSchedulePlan(
  Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(id, 'FAL_SCHEDULE_PLAN', ForceEnqueue);
  end if;
end;

procedure PublishTask(
  Id IN fal_task.fal_task_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishTask(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishTask(
  Id IN fal_task.fal_task_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(id, 'FAL_TASK', ForceEnqueue);
  end if;
end;

procedure PublishFacFloor(
  Id IN fal_factory_floor.fal_factory_floor_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishFacFloor(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishFacFloor(
  Id IN fal_factory_floor.fal_factory_floor_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(id, 'FAL_FACTORY_FLOOR', ForceEnqueue);
  end if;
end;

procedure PublishSupplyRequest(
  Id IN fal_supply_request.fal_supply_request_id%TYPE,
  vResult OUT NOCOPY INTEGER)
is
begin
  rep_functions.PublishSupplyRequest(Id, rep_functions.ENQUEUE_NO_FORCE, vResult);
end;
procedure PublishSupplyRequest(
  Id IN fal_supply_request.fal_supply_request_id%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE,
  vResult OUT NOCOPY INTEGER)
is
begin
  vResult := 2;
  if (id is not null and pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    vResult := p_publish(id, 'FAL_SUPPLY_REQUEST', ForceEnqueue);
  end if;
end;



/**
 * @deprecated use rep_lib_replicate.IsBOMReplicable instead
 */
function IsBOMReplicable(
  BOMId IN pps_nomenclature.pps_nomenclature_id%TYPE,
  CheckDeleted IN INTEGER DEFAULT 1)
  return INTEGER
is
begin
  return rep_lib_replicate.IsBOMReplicable(BOMId, CheckDeleted);
end;

/**
 * @deprecated use rep_lib_replicate.IsCategoryReplicable instead
 */
function IsCategoryReplicable(
  CategoryId IN gco_good_category.gco_good_category_id%TYPE)
  return INTEGER
is
begin
  return rep_lib_replicate.IsCategoryReplicable(CategoryId);
end;

/**
 * @deprecated use rep_lib_replicate.IsGoodReplicable instead
 */
function IsGoodReplicable(
  GoodId IN gco_good.gco_good_id%TYPE)
  return INTEGER
is
begin
  return rep_lib_replicate.IsGoodReplicable(GoodId);
end;


function PublishRecord(
  Id IN rep_to_publish.rpt_id%TYPE,
  BasicObjectName IN rep_to_publish.rpt_basic_object_name%TYPE)
  return INTEGER
is
begin
  return rep_functions.PublishRecord(Id, BasicObjectName, rep_functions.ENQUEUE_NO_FORCE);
end;
function PublishRecord(
  Id IN rep_to_publish.rpt_id%TYPE,
  BasicObjectName IN rep_to_publish.rpt_basic_object_name%TYPE,
  ForceEnqueue IN T_ENQUEUE_MODE)
  return INTEGER
is
begin
  if (pcs.PC_I_LIB_SESSION.IsReplicationEnabled = 1) then
    return p_publish(Id, BasicObjectName, ForceEnqueue);
  end if;
  return 1;
end;


function get_classification_xml(
  Id IN classification.classification_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_classification_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_classification_xml(
  Id IN classification.classification_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_classification_XMLType(Id, SearchMode));
end;

function get_classification_XMLType(
  Id IN classification.classification_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_cla_functions.get_classification_xml(Id), 'CLASSIFICATION'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_gco_good_xml(
  Id IN gco_good.gco_good_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_gco_good_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_gco_good_xml(
  Id IN gco_good.gco_good_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_gco_good_XMLType(Id, SearchMode));
end;

function get_gco_good_XMLType(
  Id IN gco_good.gco_good_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  xslt CLOB;
  lx_result XMLType;
begin
  open gcur_good_categ_xsl(Id, 'GCO_PRODUCT');
  fetch gcur_good_categ_xsl into xslt;
  close gcur_good_categ_xsl;
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformer(
        rep_log_functions.get_gco_good_xml(Id), xslt),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_gco_good_category_xml(
  Id IN gco_good_category.gco_good_category_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_gco_good_category_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_gco_good_category_xml(
  Id IN gco_good_category.gco_good_category_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_gco_good_category_XMLType(Id, SearchMode));
end;

function get_gco_good_category_XMLType(
  Id IN gco_good_category.gco_good_category_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_gco_good_category_xml(Id), 'GCO_GOOD_CATEGORY'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_gco_attribute_fields_xml(
  Id IN gco_good_category.gco_good_category_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_gco_attribute_fields_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_gco_attribute_fields_xml(
  Id IN gco_good_category.gco_good_category_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_gco_attribute_flds_XMLType(Id, SearchMode));
end;

function get_gco_attribute_flds_XMLType(
  Id IN gco_good_category.gco_good_category_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_gco_attribute_fields_xml(Id), 'GCO_ATTRIBUTE_FIELDS'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_gco_product_group_xml(
  Id IN gco_product_group.gco_product_group_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_gco_product_group_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_gco_product_group_xml(
  Id IN gco_product_group.gco_product_group_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_gco_product_group_XMLType(Id, SearchMode));
end;

function get_gco_product_group_XMLType(
  Id IN gco_product_group.gco_product_group_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_gco_product_group_xml(Id), 'GCO_PRODUCT_GROUP'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_stm_distribution_unit_xml(
  Id IN stm_distribution_unit.stm_distribution_unit_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_stm_distribution_unit_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_stm_distribution_unit_xml(
  Id IN stm_distribution_unit.stm_distribution_unit_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_stm_distrib_unit_XMLType(Id, SearchMode));
end;

function get_stm_distrib_unit_XMLType(
  Id IN stm_distribution_unit.stm_distribution_unit_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_stm_distribution_unit_xml(Id), 'STM_DISTRIBUTION_UNIT'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_gco_alloy_xml(
  Id IN gco_alloy.gco_alloy_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_gco_alloy_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_gco_alloy_xml(
  Id IN gco_alloy.gco_alloy_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_gco_alloy_XMLType(Id, SearchMode));
end;

function get_gco_alloy_XMLType(
  Id IN gco_alloy.gco_alloy_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_gco_alloy_xml(Id), 'GCO_ALLOY'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;

function get_gco_quality_status_xml(
  Id IN gco_quality_status.gco_quality_status_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_gco_quality_status_xml(Id, rep_utils.USE_KEY_VALUE);
end get_gco_quality_status_xml;

function get_gco_quality_status_xml(
  Id IN gco_quality_status.gco_quality_status_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_gco_quality_status_XMLType(Id, SearchMode));
end get_gco_quality_status_xml;

function get_gco_quality_status_XMLType(
  Id IN gco_quality_status.gco_quality_status_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_gco_quality_status_xml(Id), 'GCO_QUALITY_STATUS'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end get_gco_quality_status_XMLType;


function get_gco_qual_stat_flow_xml(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_gco_qual_stat_flow_xml(Id, rep_utils.USE_KEY_VALUE);
end get_gco_qual_stat_flow_xml;

function get_gco_qual_stat_flow_xml(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_gco_qual_stat_flow_XMLType(Id, SearchMode));
end get_gco_qual_stat_flow_xml;

function get_gco_qual_stat_flow_XMLType(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_gco_quality_stat_flow_xml(Id), 'GCO_QUALITY_STAT_FLOW'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end get_gco_qual_stat_flow_XMLType;

function get_pps_nomenclature_xml(
  Id IN pps_nomenclature.pps_nomenclature_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_pps_nomenclature_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_pps_nomenclature_xml(
  Id IN pps_nomenclature.pps_nomenclature_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_pps_nomenclature_XMLType(Id, SearchMode));
end;

function get_pps_nomenclature_XMLType(
  Id IN pps_nomenclature.pps_nomenclature_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_ind_functions.get_pps_nomenclature_xml(Id), 'PPS_NOMENCLATURE'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_ptc_tariff_category_xml(
  Id IN ptc_tariff_category.ptc_tariff_category_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_ptc_tariff_category_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_ptc_tariff_category_xml(
  Id IN ptc_tariff_category.ptc_tariff_category_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_ptc_tariff_categ_XMLType(Id, SearchMode));
end;

function get_ptc_tariff_categ_XMLType(
  Id IN ptc_tariff_category.ptc_tariff_category_id%TYPE,
  SearchMode IN VARCHAR2)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_ptc_tariff_category_xml(Id), 'PTC_TARIFF_CATEGORY'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_pac_person_xml(
  Id IN pac_person.pac_person_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_pac_person_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_pac_person_xml(
  Id IN pac_person.pac_person_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_pac_person_XMLType(Id, SearchMode));
end;

function get_pac_person_XMLType(
  Id IN pac_person.pac_person_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_pac_functions.get_pac_person_xml(Id), 'PAC_ADDRESS'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_pac_person_association_xml(
  Id IN pac_person.pac_person_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_pac_person_association_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_pac_person_association_xml(
  Id IN pac_person.pac_person_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_pac_person_assoc_XMLType(Id, SearchMode));
end;

function get_pac_person_assoc_XMLType(
  Id IN pac_person.pac_person_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_pac_functions.get_pac_person_association_xml(Id), 'PAC_PERSON_ASSOCIATION'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acs_account_xml(
  Id IN acs_account.acs_account_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acs_account_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acs_account_xml(
  Id IN acs_account.acs_account_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acs_account_XMLType(Id, SearchMode));
end;

function get_acs_account_XMLType(
  Id IN acs_account.acs_account_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acs_account_xml(Id), 'ACS_ACCOUNT'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acj_catalogue_doc_xml(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acj_catalogue_doc_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acj_catalogue_doc_xml(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acj_catalogue_doc_XMLType(Id, SearchMode));
end;

function get_acj_catalogue_doc_XMLType(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acj_catalogue_doc_xml(Id), 'ACJ_CATALOGUE_DOCUMENT'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acj_job_type_xml(
  Id IN acj_job_type.acj_job_type_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acj_job_type_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acj_job_type_xml(
  Id IN acj_job_type.acj_job_type_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acj_job_type_XMLType(Id, SearchMode));
end;

function get_acj_job_type_XMLType(
  Id IN acj_job_type.acj_job_type_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acj_job_type_xml(Id), 'ACJ_JOB_TYPE'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acs_evaluation_method_xml(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acs_evaluation_method_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acs_evaluation_method_xml(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acs_eval_method_XMLType(Id, SearchMode));
end;

function get_acs_eval_method_XMLType(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acs_evaluation_method_xml(Id), 'ACS_EVALUATION_METHOD'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acs_interest_categ_xml(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acs_interest_categ_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acs_interest_categ_xml(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acs_interest_categ_XMLType(Id, SearchMode));
end;

function get_acs_interest_categ_XMLType(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acs_interest_categ_xml(Id), 'ACS_INT_CALC_METHOD'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acs_int_calc_method_xml(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acs_int_calc_method_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acs_int_calc_method_xml(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acs_int_cal_method_XMLType(Id, SearchMode));
end;

function get_acs_int_cal_method_XMLType(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acs_int_calc_method_xml(Id), 'ACS_INT_CALC_METHOD'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_fal_supply_request_xml(
  Id IN fal_supply_request.fal_supply_request_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_fal_supply_request_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_fal_supply_request_xml(
  Id IN fal_supply_request.fal_supply_request_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_fal_supply_request_XMLType(Id, SearchMode));
end;

function get_fal_supply_request_XMLType(
  Id IN fal_supply_request.fal_supply_request_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_ind_functions.get_fal_supply_request_xml(Id), 'FAL_SUPPLY_REQUEST'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_fal_schedule_plan_xml(
  Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_fal_schedule_plan_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_fal_schedule_plan_xml(
  Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_fal_schedule_plan_XMLType(Id, SearchMode));
end;

function get_fal_schedule_plan_XMLType(
  Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_ind_functions.get_fal_schedule_plan_xml(Id), 'FAL_SCHEDULE_PLAN'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;

function get_fal_task_xml(
  Id IN fal_task.fal_task_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_fal_task_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_fal_task_xml(
  Id IN fal_task.fal_task_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_fal_task_xmlType(Id, SearchMode));
end;

function get_fal_task_xmlType(
  Id IN fal_task.fal_task_id%TYPE,
  SearchMode IN VARCHAR2 default rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_ind_functions.get_ind_fal_task_xml(id), 'FAL_TASK'),
    SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;

function get_fal_factory_floor_xml(
  Id IN fal_factory_floor.fal_factory_floor_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_fal_factory_floor_xml(id, rep_utils.USE_KEY_VALUE);
end;
function get_fal_factory_floor_xml(
  Id IN fal_factory_floor.fal_factory_floor_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_fal_factory_floor_XMLType(id, SearchMode));
end;

function get_fal_factory_floor_XMLType(
  Id IN fal_factory_floor.fal_factory_floor_id%TYPE,
  SearchMode IN VARCHAR2 default rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_ind_functions.get_ind_fal_factory_floor_xml(Id), 'FAL_FACTORY_FLOOR'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_stm_stock_xml(
  Id IN stm_stock.stm_stock_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_stm_stock_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_stm_stock_xml(
  Id IN stm_stock.stm_stock_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_stm_stock_XMLType(Id, SearchMode));
end;

function get_stm_stock_XMLType(
  Id IN stm_stock.stm_stock_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_stm_stock_xml(Id), 'STM_STOCK'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_stm_location_xml(
  Id IN stm_location.stm_location_ID%TYPE)
  return CLOB
is
begin
  return rep_functions.get_stm_location_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_stm_location_xml(
  Id IN stm_location.stm_location_ID%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_stm_location_XMLType(Id, SearchMode));
end;

function get_stm_location_XMLType(
  Id IN stm_location.stm_location_ID%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_stm_location_xml(Id), 'STM_LOCATION'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_stm_movement_kind_xml(
  Id IN stm_movement_kind.stm_movement_kind_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_stm_movement_kind_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_stm_movement_kind_xml(
  Id IN stm_movement_kind.stm_movement_kind_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_stm_movement_kind_XMLType(Id, SearchMode));
end;

function get_stm_movement_kind_XMLType(
  Id IN stm_movement_kind.stm_movement_kind_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_stm_movement_kind_xml(Id), 'STM_MOVEMENT_KIND'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_stm_stock_movement_xml(
  Id IN stm_stock_movement.stm_stock_movement_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_stm_stock_movement_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_stm_stock_movement_xml(
  Id IN stm_stock_movement.stm_stock_movement_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_stm_stock_movement_XMLType(Id, SearchMode));
end;

function get_stm_stock_movement_XMLType(
  Id IN stm_stock_movement.stm_stock_movement_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_stm_stock_movement_xml(Id), 'STM_STOCK_MOVEMENT'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_doc_record_xml(
  Id IN doc_record.doc_record_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_doc_record_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_doc_record_xml(
  Id IN doc_record.doc_record_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_doc_record_XMLType(Id, SearchMode));
end;

function get_doc_record_XMLType(
  Id IN doc_record.doc_record_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_doc_record_xml(Id), 'DOC_RECORD'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_doc_record_cat_xml(
  Id IN doc_record_category.doc_record_category_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_doc_record_cat_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_doc_record_cat_xml(
  Id IN doc_record_category.doc_record_category_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_doc_record_cat_XMLType(Id, SearchMode));
end;

function get_doc_record_cat_XMLType(
  Id IN doc_record_category.doc_record_category_iD%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_doc_record_category_xml(Id), 'DOC_RECORD_CATEGORY'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_rco_cat_lnk_type_xml(
  Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_rco_cat_lnk_type_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_rco_cat_lnk_type_xml(
  Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_rco_cat_lnk_type_XMLType(Id, SearchMode));
end;

function get_rco_cat_lnk_type_XMLType(
  Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_rco_cat_lnk_type_xml(Id), 'DOC_RECORD_CAT_LINK_TYPE'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_doc_gauge_signat_xml(
  Id IN doc_gauge_signatory.doc_gauge_signatory_ID%TYPE)
  return CLOB
is
begin
  return rep_functions.get_doc_gauge_signat_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_doc_gauge_signat_xml(
  Id IN doc_gauge_signatory.doc_gauge_signatory_ID%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_doc_gauge_signat_XMLType(Id, SearchMode));
end;

function get_doc_gauge_signat_XMLType(
  Id IN doc_gauge_signatory.doc_gauge_signatory_ID%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_doc_gauge_signatory_xml(Id), 'DOC_GAUGE_SIGNATORY'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_doc_gauge_number_xml(
  Id IN doc_gauge_numbering.doc_gauge_numbering_ID%TYPE)
  return CLOB
is
begin
  return rep_functions.get_doc_gauge_number_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_doc_gauge_number_xml(
  Id IN doc_gauge_numbering.doc_gauge_numbering_ID%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_doc_gauge_number_XMLType(Id, SearchMode));
end;

function get_doc_gauge_number_XMLType(
  Id IN doc_gauge_numbering.doc_gauge_numbering_ID%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_doc_gauge_numbering_xml(Id), 'DOC_GAUGE_NUMBERING'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_doc_gauge_xml(
  Id IN doc_gauge.doc_gauge_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_doc_gauge_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_doc_gauge_xml(
  Id IN doc_gauge.doc_gauge_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_doc_gauge_XMLType(Id, SearchMode));
end;

function get_doc_gauge_XMLType(
  Id IN doc_gauge.doc_gauge_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_doc_gauge_xml(Id), 'DOC_GAUGE'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_doc_gauge_flow_xml(
  Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_doc_gauge_flow_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_doc_gauge_flow_xml(
  Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_doc_gauge_flow_XMLType(Id, SearchMode));
end;

function get_doc_gauge_flow_XMLType(
  Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_log_functions.get_doc_gauge_flow_xml(Id), 'DOC_GAUGE_FLOW'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_pac_payment_cond_xml(
  Id IN pac_payment_condition.pac_payment_condition_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_pac_payment_cond_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_pac_payment_cond_xml(
  Id IN pac_payment_condition.pac_payment_condition_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_pac_payment_cond_XMLType(Id, SearchMode));
end;

function get_pac_payment_cond_XMLType(
  Id IN pac_payment_condition.pac_payment_condition_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_pac_functions.get_pac_payment_condition_xml(Id), 'PAC_PAYMENT_CONDITION'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_hrm_elements_root_xml(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return CLob
is
begin
  return rep_functions.get_hrm_elements_root_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_hrm_elements_root_xml(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLob
is
begin
  return p_XmlToClob(rep_functions.get_hrm_elements_root_XMLType(Id, SearchMode));
end;

function get_hrm_elements_root_XMLType(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_hrm_functions.get_hrm_elements_root_xml(Id), 'HRM_ELEMENTS_ROOT'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_hrm_control_list_xml(
  Id IN hrm_control_list.hrm_control_list_id%TYPE)
  return CLob
is
begin
  return rep_functions.get_hrm_control_list_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_hrm_control_list_xml(
  Id IN hrm_control_list.hrm_control_list_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLob
is
begin
  return p_XmlToClob(rep_functions.get_hrm_control_list_XMLType(Id, SearchMode));
end;

function get_hrm_control_list_XMLType(
  Id IN hrm_control_list.hrm_control_list_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_hrm_functions.get_hrm_control_list_xml(Id), 'HRM_CONTROL_LIST'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_hrm_allocation_xml(
  Id hrm_allocation.hrm_allocation_id%TYPE)
  return CLob
is
begin
  return rep_functions.get_hrm_allocation_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_hrm_allocation_xml(
  Id hrm_allocation.hrm_allocation_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLob
is
begin
  return p_XmlToClob(rep_functions.get_hrm_allocation_XMLType(Id, SearchMode));
end;

function get_hrm_allocation_XMLType(
  Id hrm_allocation.hrm_allocation_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_hrm_functions.get_hrm_allocation_xml(Id), 'HRM_ALLOCATION'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acs_vat_code_xml(
  Id IN acs_tax_code.acs_tax_code_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acs_vat_code_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acs_vat_code_xml(
  Id IN acs_tax_code.acs_tax_code_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acs_vat_code_XMLType(Id, SearchMode));
end;
function get_acs_vat_code_XMLType(
  Id IN acs_tax_code.acs_tax_code_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acs_account_xml(Id), 'ACS_ACCOUNT'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_acs_fin_account_xml(
  Id IN acs_financial_account.acs_financial_account_id%TYPE)
  return CLOB
is
begin
  return rep_functions.get_acs_fin_account_xml(Id, rep_utils.USE_KEY_VALUE);
end;
function get_acs_fin_account_xml(
  Id IN acs_financial_account.acs_financial_account_id%TYPE,
  SearchMode IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_functions.get_acs_fin_account_XMLType(Id, SearchMode));
end;
function get_acs_fin_account_XMLType(
  Id IN acs_financial_account.acs_financial_account_id%TYPE,
  SearchMode IN VARCHAR2 DEFAULT rep_utils.USE_KEY_VALUE)
  return XMLType
is
  lx_result XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  lx_result :=
    rep_functions.AddDocumentDirective(
      p_ApplyTransformerText(
        rep_fin_functions.get_acs_account_xml(Id), 'ACS_ACCOUNT'),
      SearchMode);
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_result;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


END REP_FUNCTIONS;
