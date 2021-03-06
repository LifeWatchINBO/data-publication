USE [NBNData_IPT]
GO

/****** Object:  View [ipt].[vwGBIF_DepletionFishingNeteOccurrence]    Script Date: 19/09/2016 12:12:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [ipt].[vwGBIF_DepletionFishingNeteOccurrence]
AS

SELECT
	  [occurrenceID] = 'INBO:NBN:' + Tao.Taxon_occurrence_key
      , [verbatimLocality] = Ln.Item_name
      , [samplingProtocol] = CASE
                                 WHEN St.Short_name = 'Elektrovisserij' THEN 'electrofishing'
                                 WHEN St.Short_name IN ( 'Fuik', 'schietfuik') THEN 'fyke'
								 WHEN St.Short_name IN ( 'Kruisnet') THEN 'liftnet'
								 WHEN St.Short_name IN ( 'Sleepstaal') THEN 'dragnet'
                                 ELSE St.Short_name
                            END
      , [institutionCode] = CONVERT( NVARCHAR(20), 'INBO')
      , [language] = CONVERT( NVARCHAR(20), 'en')

      -- Taxonomic Elements --
      , [basisOfRecord] = CASE
                              WHEN RT.[SHORT_NAME] = 'Collection' THEN 'PreservedSpecimen'
                              ELSE 'HumanObservation'
                          END
      , [scientificName] = Ns.Recommended_scientific_name
      , [scientificNameAuthorship] = NS.RECOMMENDED_NAME_AUTHORITY + ISNULL ( ' ' + NS.RECOMMENDED_NAME_QUALIFIER , '')
      , [kingdom] = 'Animalia' 
      , [phylum] = CASE WHEN MAX(ns.[INFORMAL GROUP]) = N'schaaldier' THEN N'Arthropoda' 
						WHEN MAX(ns.[INFORMAL GROUP]) IN ('beenvis (Actinopterygii)','rondbek (Agnatha)')  THEN N'Chordata'
						ELSE NULL END 
	  , [class] = 'Actinopterygii'
      , [taxonRank] = LOWER(Ns.Recommended_name_rank_long)
	  , [vernacularName] = NormNaam.ITEM_NAME
      , [nomenclaturalCode] = CONVERT(Nvarchar(20),'ICZN') 
      , [countryCode] = CONVERT( NVARCHAR(20), 'BE')
     
      -- Collecting Event Elements --
      , [eventDate] = MAX( [inbo].[LCReturnVagueDateGBIF](  Sa.Vague_date_start
                                                      , Sa.Vague_date_end
                                                      , Sa.Vague_date_type
													  , 1))
     
	  -- identification --
	  , [recordedBy] =
			CASE
				WHEN inbo.[ufn_RecordersPerSample](SA.[SAMPLE_KEY], ' | ') = 'Unknown' THEN '' 
				ELSE inbo.[ufn_RecordersPerSample](SA.[SAMPLE_KEY], ' | ')
			END
      , [identifiedBy] = COALESCE(  I.[Forename]
                                  , I.[Initials]
                                  , '') + ' ' + COALESCE( I.[Surname], '')

	  -- location --
      , [decimalLatitude] = CONVERT( NVARCHAR(20), CONVERT( DECIMAL( 12, 5), Round( SA.LAT , 5)))
      , [decimalLongitude] = CONVERT( NVARCHAR(20), CONVERT( DECIMAL( 12, 5), Round( SA.LONG, 5)))
      , [geodeticDatum] = CONVERT( NVARCHAR(10), 'WGS84')
      , [coordinateUncertaintyInMeters] = '30'
      , [verbatimLatitude] =  CONVERT( DECIMAL( 12, 0), LEFT( Sa.Spatial_ref, Charindex(  ',', Sa.Spatial_ref, 1) - 1))                                                           
      , [verbatimLongitude] =  CONVERT( DECIMAL( 12, 0), Substring(  Sa.Spatial_ref, Charindex(  ',', Sa.Spatial_ref, 1) + 1, Len( Sa.Spatial_ref)))
      , [verbatimCoordinateSystem] = CASE WHEN SA.SPATIAL_REF_SYSTEM = 'BD72' THEN 'Belgian Lambert 72'
										ELSE SA.SPATIAL_REF_SYSTEM 
									END
	  , [verbatimSRS] = 'Belgian Datum 1972'
      
	  -- record --
	  , [accessRights] = N'http://www.inbo.be/en/norms-for-data-use'
	  , [license] = N'http://creativecommons.org/publicdomain/zero/1.0/'
	  , [rightsHolder] =  CONVERT(Nvarchar(20),'INBO')
	  , [type] = CONVERT(Nvarchar(20), 'Event') -->"Dataset" tpye
	  , [datasetID] = 'https://doi.org/10.15468/zan6uj'
	  , [datasetName] = 'Depletion fishing in the rivers Grote Nete and Kleine Nete in Flanders, Belgium'
	  , [ownerInstitutionCode] = CONVERT(Nvarchar(20),'INBO') 
	  , [continent] = N'Europe'

	  --, [sampleref] = Sa.SAMPLE_REFERENCE
	  --, [NBN_SurveyName] = CONVERT( NVARCHAR(100), S.Item_name)
	  --, [informalGroup] = Max(ns.[INFORMAL GROUP])

FROM  Dbo.Survey S
        INNER JOIN [Dbo].[Survey_event] Se ON  Se.[Survey_key] = S.[Survey_key]
        LEFT JOIN [Dbo].[Location] L ON  L.[Location_key] = Se.[Location_key]
        LEFT JOIN [Dbo].[Location_name] Ln ON  Ln.[Location_key] = L.[Location_key]
        INNER JOIN [Dbo].[Sample] Sa ON  Sa.[Survey_event_key] = Se.[Survey_event_key]
        LEFT JOIN [Dbo].[Sample_type] St ON  St.[Sample_type_key] = Sa.[Sample_type_key]
        INNER JOIN [Dbo].[Taxon_occurrence] Tao ON  Tao.[Sample_key] = Sa.[Sample_key]
        LEFT JOIN [Dbo].[Record_type] Rt ON  Rt.[Record_type_key] = Tao.[Record_type_key]
        LEFT JOIN [Dbo].[Specimen] Sp ON  Sp.[Taxon_occurrence_key] = Tao.[Taxon_occurrence_key]
        LEFT JOIN [Dbo].[Taxon_determination] Td ON  Td.[Taxon_occurrence_key] = Tao.[Taxon_occurrence_key]
        LEFT JOIN [Dbo].[Individual] I ON  I.[Name_key] = Td.[Determiner]
        LEFT JOIN [Dbo].[Determination_type] Dt ON  Dt.[Determination_type_key] = Td.[Determination_type_key]
                                                    --Taxon
                                                    
        LEFT JOIN [Dbo].[Taxon_list_item] Tli ON  Tli.[Taxon_list_item_key] = Td.[Taxon_list_item_key]
        LEFT JOIN [Dbo].[Taxon_version] Tv ON  Tv.[Taxon_version_key] = Tli.[Taxon_version_key]
        LEFT JOIN [Dbo].[Taxon] T ON  T.[Taxon_key] = Tv.[Taxon_key]
        INNER JOIN [Dbo].[Taxon_rank] Tr ON  Tr.Taxon_rank_key = Tli.Taxon_rank_key
		INNER JOIN dbo.NAMESERVER NSR ON NSR.INPUT_TAXON_VERSION_KEY = tli.TAXON_VERSION_KEY

		--Normalizing to Vernacular names
		LEFT OUTER JOIN (	SELECT TVen.*
								, ROW_NUMBER() OVER (PARTITION by NS.INPUT_TAXON_VERSION_KEY ORDER BY Tven.ITEM_NAME) as Nbr
								, NS.INPUT_TAXON_VERSION_KEY AS [INBO_TAXON_VERSION_KEY]
							FROM [dbo].[NameServer] NS
								 INNER JOIN dbo.TAXON_LIST_ITEM TLIVen ON TLIVen.PREFERRED_NAME = NS.RECOMMENDED_TAXON_LIST_ITEM_KEY
								 INNER JOIN dbo.TAXON_VERSION TVVen ON TVVen.TAXON_VERSION_KEY = TLIVen.TAXON_VERSION_KEY
								 INNER JOIN dbo.TAXON TVen ON TVVen.TAXON_KEY = TVen.TAXON_KEY
							WHERE TVen.[LANGUAGE] = 'nl'
						) NormNaam on NormNaam.[INBO_TAXON_VERSION_KEY] = tli.[TAXON_VERSION_KEY] AND NormNaam.Nbr = 1

                                             
        INNER JOIN [Inbo].[Nameserver_12] Ns ON  Ns.[Inbo_taxon_version_key] = Tli.[Taxon_version_key]
                                                 -->Common name nog opzoeken...
                                                 --Recorders
                                                 
        LEFT JOIN [Dbo].[Sample_recorder] Sr ON  Sr.[Sample_key] = Sa.[Sample_key]
       
        LEFT JOIN [dbo].[TAXON_OCCURRENCE_DATA] taoMeas ON  taoMeas.TAXON_OCCURRENCE_KEY = tao.TAXON_OCCURRENCE_KEY
        
        LEFT JOIN dbo.MEASUREMENT_UNIT MUMeas ON  MUMeas.MEASUREMENT_UNIT_KEY = taoMeas.MEASUREMENT_UNIT_KEY
        LEFT JOIN dbo.MEASUREMENT_QUALIFIER MQMeas ON  MQMeas.MEASUREMENT_QUALIFIER_KEY = taoMeas.MEASUREMENT_QUALIFIER_KEY
        LEFT JOIN dbo.MEASUREMENT_TYPE MTMeas ON  MTMeas.MEASUREMENT_TYPE_KEY = MQMeas.MEASUREMENT_TYPE_KEY
		
WHERE  S.[Item_name] = 'Depletie-afvissingen Grote en Kleine Nete'

       AND Isnumeric( Substring(  Ln.[Item_name]
                                , 2
                                , 1)) = 0
       AND Td.[Preferred] = 1
       AND Ns.[Recommended_name_rank] NOT IN(  'FunGp'
                                             , 'Agg'
                                             , 'SppGrp')
       AND Dt.[Short_name] NOT IN(  'Incorrect'
                                  , 'Invalid'
                                  , 'Considered Incorrect'
                                  , 'Requires Confirmation')
       AND Tr.[Sequence] >= 230
       AND Isnumeric( LEFT( Sa.Spatial_ref, Charindex(  ','
                                                      , Sa.Spatial_ref
                                                      , 1) - 1)) = 1
       AND Charindex(  ','
                     , Sa.Spatial_ref
                     , 1) > 5
       AND Isnumeric( Substring(  Sa.Spatial_ref
                                , Charindex(  ','
                                            , Sa.Spatial_ref
                                            , 1) + 1
                                , Len( Sa.Spatial_ref))) = 1
       
        AND MTMeas.SHORT_NAME IN ('Abundance')
        AND MUMeas.SHORT_NAME = 'Count'
        
        AND ISNUMERIC( TAOMeas.DATA) = 1
		AND MTMeas.SHORT_NAME = 'Abundance' 
		-- No Abscent records
		 AND TAOMeas.DATA <> '0' 
       --AND  Tao.Taxon_occurrence_key = 'BFN0017900002YGF'
       
GROUP BY  Tao.[Taxon_occurrence_key]
        , Ln.[Item_name]
        , Rt.[Short_name]
        , St.Short_name
        , CONVERT( NVARCHAR(100), S.Item_name)
        , T.[Item_name]
        , Ns.[Recommended_scientific_name]
        , Ns.[Recommended_name_rank]
        , Ns.[Recommended_name_rank_long]
        , Rt.[Short_name]
        , Sa.[Vague_date_start]
        , Sa.[Vague_date_end]
        , Sa.[Vague_date_type]
        , Sa.[Sample_key]
        , COALESCE(  I.[Forename]
                   , I.[Initials]
                   , '') + ' ' + COALESCE( I.[Surname], '')
        , CONVERT(  NVARCHAR(10), CONVERT(  DATETIME, Dbo.Lcreturnvaguedateshort(  TD.VAGUE_DATE_START , TD.Vague_date_end, Td.Vague_date_type), 103), 120)
		, CONVERT( NVARCHAR(20), CONVERT( DECIMAL( 12, 5), Round( SA.LAT , 5)))
		, CONVERT( NVARCHAR(20), CONVERT( DECIMAL( 12, 5), Round( SA.LONG, 5)))
        , SA.SPATIAL_REF
        , SA.SPATIAL_REF_SYSTEM
		, NormNaam.ITEM_NAME
		, NS.RECOMMENDED_NAME_AUTHORITY + ISNULL ( ' ' + NS.RECOMMENDED_NAME_QUALIFIER , '')
		, CASE WHEN TAOMeas.DATA <> '0' THEN 'present' 
								ELSE 'absent'
							END
		, Sa.SAMPLE_REFERENCE
      ;

/*

-- ChangeDate 20130807
-- Modif [inbo].[LCReturnVagueDateGBIF] new vague date closer to ISO standard
-- Modif 20150908 => Eventdate to Single date ( no range ), range => [verbatimEventDate]
-- Modif 20150908 => GlobalUniqueId => [occurrenceID]
*/

GO


