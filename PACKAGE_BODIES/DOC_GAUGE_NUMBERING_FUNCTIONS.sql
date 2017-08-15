--------------------------------------------------------
--  DDL for Package Body DOC_GAUGE_NUMBERING_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_GAUGE_NUMBERING_FUNCTIONS" 
is
  /**
  * Description
  *    Duplique une numérotation d'un gabarit. Retourne l'id de la numérotation créée
  */
  procedure DuplicateGaugeNumbering(
    aSrcId       in     DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type
  , aNewId       out    DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type
  , aNewDescribe in     DOC_GAUGE_NUMBERING.GAN_DESCRIBE%type
  , aNewPrefix   in     DOC_GAUGE_NUMBERING.GAN_PREFIX%type
  , aNewSuffix   in     DOC_GAUGE_NUMBERING.GAN_SUFFIX%type
  )
  is
    -- curseur représentant la numérotation source
    cursor csSrcGaugeNumbering(pSrcGaugeNumberingId DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type)
    is
      select *
        from DOC_GAUGE_NUMBERING
       where DOC_GAUGE_NUMBERING_ID = pSrcGaugeNumberingId;

    rSrcGaugeNumbering  csSrcGaugeNumbering%rowtype;
    newGaugeNumberingId DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  begin
    -- Recherche les informations à copier
    open csSrcGaugeNumbering(aSrcId);

    fetch csSrcGaugeNumbering
     into rSrcGaugeNumbering;

    -- si on a trouvé les informations à copier
    if csSrcGaugeNumbering%found then
      -- Recherche l'ID de la nouvelle numérotation
      select INIT_ID_SEQ.nextval
        into newGaugeNumberingId
        from dual;

      -- créer la nouvelle numérotation
      insert into DOC_GAUGE_NUMBERING
                  (DOC_GAUGE_NUMBERING_ID
                 , GAN_DESCRIBE
                 , GAN_PREFIX
                 , GAN_SUFFIX
                 , GAN_INCREMENT
                 , GAN_MODIFY_NUMBER
                 , GAN_LAST_NUMBER
                 , GAN_RANGE_NUMBER
                 , GAN_FREE_NUMBER
                 , GAN_NUMBER
                 , GAN_ADDENDUM
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (newGaugeNumberingId
                 , aNewDescribe
                 , aNewPrefix
                 , aNewSuffix
                 , rSrcGaugeNumbering.GAN_INCREMENT
                 , rSrcGaugeNumbering.GAN_MODIFY_NUMBER
                 , rSrcGaugeNumbering.GAN_LAST_NUMBER
                 , rSrcGaugeNumbering.GAN_RANGE_NUMBER
                 , rSrcGaugeNumbering.GAN_FREE_NUMBER
                 , rSrcGaugeNumbering.GAN_NUMBER
                 , rSrcGaugeNumbering.GAN_ADDENDUM
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    -- ferme le curseur
    close csSrcGaugeNumbering;

    -- retourne l'id de la nouvelle numérotation
    aNewId  := newGaugeNumberingId;
  end DuplicateGaugeNumbering;
end DOC_GAUGE_NUMBERING_FUNCTIONS;
