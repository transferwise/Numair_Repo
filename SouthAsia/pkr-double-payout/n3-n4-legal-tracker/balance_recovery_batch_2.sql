/*
 Author: Numair Fazili
 Description: The following query is used to track recoveries via balance reservations for affected transfers in N3/N4 category
 to whom legal letters were sent on 14 December 2022
 */


WITH CTE AS (
    SELECT DISTINCT PMT.TRANSFER_ID,COALESCE(PCL.PAYOUT_CLASSIFICATION,PMT.PAYOUT_CLASSIFICATION) AS TRANSFER_STATE
    FROM REPORTS.PKR_DOUBLE_PAYOUT_MASTER_TABLE PMT
    LEFT JOIN  REPORTS.PKR_DOUBLE_PAYOUT_CHANGE_LOG PCL ON PCL.TRANSFER_ID = PMT.TRANSFER_ID

),

MAIN_TABLE AS (SELECT
DISTINCT CTE.TRANSFER_ID AS TRANSFER_ID,
LAST_VALUE(CTE.TRANSFER_STATE) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS TRANSFER_STATE,
LAST_VALUE(WI.STATE) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS WORK_ITEM_STATE,
LAST_VALUE(SOURCE_CURRENCY) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS SOURCE_CURRENCY,
LAST_VALUE(TARGET_CURRENCY) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS TARGET_CURRENCY,
LAST_VALUE(INVOICE_VALUE_LOCAL) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS AMOUNT_IN_SOURCE_CCY,
LAST_VALUE(FEE_VALUE_LOCAL) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS FEES_IN_SOURCE_CCY,
LAST_VALUE(INVOICE_VALUE_GBP) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS AMOUNT_IN_GBP,
LAST_VALUE(WI.LAST_UPDATED ) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS LAST_UPDATED,
LAST_VALUE(PKRC.CATEGORY) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS CATEGORY,
LAST_VALUE(PKRC.NOTIFICATION_CATEGORY) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS NOTIFICATION_CATEGORY,
LAST_VALUE(PKRC.PAYIN_CHANNEL) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS PAYIN_CHANNEL,
LAST_VALUE(RAS.USER_PROFILE_ID) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS USER_PROFILE_ID,
LAST_VALUE(RAS.USER_ID) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS USER_ID,
LAST_VALUE(IFF(WI.STATE = 'CLOSED',WI.LAST_UPDATED,NULL) ) OVER (PARTITION BY CTE.TRANSFER_ID ORDER BY LAST_UPDATED) AS DATE_CLOSED
FROM CTE
         INNER JOIN FX.WORK_ITEM WI ON WI.REQUEST_ID = CTE.TRANSFER_ID
         INNER JOIN REPORTS.REPORT_ACTION_STEP RAS ON RAS.REQUEST_ID = CTE.TRANSFER_ID
         LEFT JOIN  REPORTS.PKR_DOUBLE_PAYOUT_CLASSIFICATION PKRC ON PKRC.TRANSFER_ID = CTE.TRANSFER_ID

WHERE TRUE
 AND RAS.NOT_DUPLICATE = 1
 AND WI.TYPE = 'PROBLEMATIC_OOPS'
 AND CTE.TRANSFER_STATE = 'DPO'),
/*
 FETCHED USER PROFILES FROM SPREADSHEET -- FOR CONSISTENCY AS SOME BALANCES WERE CHANGED
 */
BALANCE_CHECK AS (
    SELECT USER_PROFILE_ID AS PROFILE_ID,
        CASE
            WHEN USER_PROFILE_ID IN (6091,22073,56371,56371,56371,174216,245127,418739,430937,515794,557752,557752,599728,612921,626538,632738,638969,694721,694721,791450,791450,802044,802044,802119,809415,821189,829488,836929,840931,846674,846674,873718,878772,883886,887533,916652,935995,959482,1031501,1046890,1093332,1099597,1115622,1121549,1195664,1259843,1265898,1271728,1271728,1330200,1377496,1401219,1401219,1403158,1419711,1449137,1455276,1455276,1498758,1498758,1498758,1505695,1505695,1537036,1575229,1584131,1598016,1598016,1605776,1630327,1643260,1723999,1767834,1767834,1915567,1952459,1954239,1972862,2008450,2008450,2057311,2057311,2122938,2142382,2155015,2155015,2173634,2199512,2199512,2199512,2199512,2199512,2213556,2241610,2281599,2349210,2442800,2453606,2453606,2555580,2573280,2639766,2650300,2650300,2669184,2669184,2676815,2679114,2701229,2701229,2731462,2731462,2738988,2738988,2738988,2754505,2775468,2798537,2827810,2869063,2869955,2869955,2892486,2948535,3114738,3116755,3118344,3157802,3158357,3336357,3341235,3346166,3366022,3377369,3377369,3377369,3377369,3426630,3435810,3441351,3449119,3499880,3503508,3503508,3503508,3532925,3532925,3579220,3618592,3619842,3623340,3623340,3731708,3737839,3757864,3762457,3815783,3878721,3891572,3940323,3981551,4005098,4081079,4166327,4166327,4172791,4244623,4365351,4393395,4393395,4427100,4502973,4513651,4513651,4535066,4573597,4595704,4600607,4600607,4647764,4669715,4674928,4702433,4777425,4783924,4783924,4892904,4927097,4940013,4940013,4946467,5015661,5027291,5090330,5108356,5147953,5151164,5151164,5169091,5234503,5234511,5271045,5308009,5340872,5347986,5466901,5466901,5466901,5473558,5473558,5480667,5480667,5480667,5500858,5590513,5595494,5605554,5609385,5659394,5659394,5659394,5659394,5711055,5759238,5764886,5764886,5858106,5860701,5872615,5872615,5940993,5940993,5984142,5995376,6007623,6011551,6026143,6135730,6161981,6169717,6169717,6217432,6222484,6330100,6344134,6346040,6346040,6373206,6373691,6401708,6407038,6449058,6488222,6517164,6569282,6569282,6617905,6669297,6697852,6697852,6715001,6726786,6736131,6737745,6738639,6770144,6795609,6836214,6836214,6848584,6868429,6914400,6917909,6924670,6924670,6987683,6997217,7004443,7004443,7004443,7004443,7030944,7030944,7030944,7049651,7058560,7058560,7065946,7098789,7205598,7226200,7235462,7244704,7244704,7244704,7255439,7270909,7283322,7285526,7299094,7319618,7344695,7353340,7484524,7524403,7529198,7531263,7537473,7537473,7563539,7586481,7586481,7601932,7601932,7616328,7619924,7623602,7633481,7661045,7680441,7730800,7730800,7737286,7737895,7737895,7813604,7829388,7877210,7880332,7912454,7929290,7938699,7949038,8040255,8054355,8068518,8068983,8097207,8097207,8097243,8097243,8135738,8164882,8283549,8283549,8298934,8298934,8298934,8323636,8391495,8391495,8453784,8509359,8521531,8521531,8522947,8526231,8526231,8581472,8581472,8600884,8600884,8608011,8613253,8639708,8639708,8642380,8644205,8671142,8694473,8694473,8717217,8717217,8717217,8759349,8759836,8861171,8861171,8861171,8861171,8876056,8876056,8890268,8907148,8932658,8944330,8950479,9009224,9013195,9027730,9030887,9030887,9042720,9042946,9048760,9050082,9074818,9074818,9105430,9105636,9105636,9108498,9109089,9124941,9143450,9152295,9161953,9173909,9183074,9184616,9187327,9208039,9219050,9220788,9248808,9250040,9254484,9268273,9290374,9422778,9467552,9501840,9501840,9567515,9568761,9576818,9584295,9584295,9585831,9589905,9589905,9589905,9592733,9599348,9667545,9690351,9732300,9781640,9781640,9788866,9810051,9823118,9836497,9945785,9945785,9974718,9979185,9985908,9985908,9999488,10009214,10017445,10028923,10046326,10052601,10062585,10062585,10073105,10081925,10081925,10081925,10088343,10092139,10108560,10122319,10175667,10175667,10203655,10203655,10203655,10333559,10351951,10438925,10478374,10574109,10574109,10654612,10695807,10696745,10696745,10726381,10731721,10778466,10855281,10855281,10855281,10855281,10855281,10896603,10896603,10896603,10927486,10930267,10936352,10941583,10965898,11020944,11033858,11033858,11033858,11033858,11097471,11097471,11106523,11149859,11153718,11175743,11191071,11195747,11195747,11195747,11239816,11284196,11284196,11302798,11325797,11333179,11334982,11354820,11365343,11367885,11376694,11403854,11446452,11454884,11459671,11459873,11470751,11540760,11546495,11652062,11655247,11661229,11731045,11731045,11743159,11747750,11792882,11809775,11819665,11821727,11824824,11858651,11920591,11952674,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11987873,11994413,11995591,11995591,11995591,11997392,12114127,12152097,12152097,12154190,12183041,12230384,12267741,12336666,12339506,12363699,12382756,12421456,12442473,12442473,12459414,12586369,12586369,12608736,12611506,12611506,12611506,12689545,12689824,12696277,12696277,12758984,12762729,12765342,12843044,12843044,12843044,12919129,12932277,12945051,12945051,12945863,12954632,12958547,12970742,12970742,12970742,12979511,12987349,13116828,13116828,13123592,13138756,13138756,13162258,13162258,13222150,13222150,13239324,13261780,13269824,13317215,13317215,13324302,13328212,13347364,13405075,13467213,13467213,13478419,13478419,13478419,13483456,13487821,13495867,13509819,13509819,13512140,13541607,13544998,13544998,13547122,13558702,13583272,13585190,13613570,13624271,13628770,13628770,13631408,13631408,13632746,13639333,13639333,13645227,13645227,13698394,13698394,13753781,13774391,13801782,13801782,13801782,13811682,13847703,13847703,13847703,13855726,13862935,13907064,13918005,13923761,13962426,13962426,13990078,13990938,13991943,13993212,14002885,14012790,14016486,14038786,14071398,14077456,14077456,14077456,14079752,14084640,14088112,14104936,14152957,14154942,14166835,14186675,14186675,14530803,14530803,14553692,14564524,14564524,14564524,14564524,14571727,14571727,14571753,14574384,14574384,14592573,14603548,14606882,14627423,14639039,14663043,14751784,14816582,14816582,14839774,14847601,14847601,14865945,14868107,14868107,14868107,14880102,14962204,14971916,14971916,14972445,15001149,15062358,15142185,15144968,15150834,15150834,15166041,15202721,15247790,15265702,15275037,15335156,15335156,15341933,15341933,15341933,15341933,15341933,15345036,15364074,15364273,15365213,15372498,15388780,15398922,15402965,15432220,15439434,15582232,15583607,15657245,15674425,15700162,15776908,15776908,15869252,15870723,15870723,15904484,15949266,15991275,16015372,16048765,16083265,16083265,16144333,16144333,16152511,16167017,16190039,16190039,16209137,16209137,16209137,16209137,16209137,16209137,16209137,16307149,16307149,16307149,16327900,16327900,16327900,16346420,16381275,16384485,16409359,16411984,16411984,16461632,16469524,16509010,16556065,16556065,16615007,16625019,16673743,16673743,16673743,16673743,16680423,16692422,16692422,16705704,16739525,16739525,16797860,16809245,16810524,16822300,16841756,16841756,16841756,16841756,16841756,16842895,16842895,16842895,16842895,16961555,16990470,16994609,16994609,17024103,17024103,17024103,17027917,17030141,17032399,17035899,17044287,17080555,17085714,17118470,17245302,17248081,17261291,17273522,17275927,17301106,17358964,17411413,17415481,17415481,17417428,17467218,17467218,17483935,17569632,17569632,17627094,17637676,17776128,17795733,17804667,17807460,17838775,17862853,17862853,17862853,17878340,17892750,17892750,17892750,17899333,17924269,17947946,18003483,18003483,18020398,18020398,18087768,18112123,18170321,18223154,18227013,18231377,18299463,18299463,18369057,18384642,18401036,18401036,18401036,18427275,18436912,18470299,18475647,18477938,18477938,18491963,18504703,18516419,18564582,18564582,18564582,18572666,18577335,18590033,18592216,18613185,18614112,18614112,18623618,18651353,18653696,18653696,18716293,18749856,18749856,18764699,18770944,18777774,18799457,18801810,18801810,18814144,18838660,18843443,18863683,18892561,18892912,18914323,18920876,18949532,18949532,18951932,18961639,19006557,19038124,19040847,19040847,19051399,19055267,19132078,19132078,19209650,19214687,19263135,19272612,19319637,19319637,19319637,19319637,19348569,19370050,19443611,19556934,19581819,19581819,19598252,19598252,19598252,19598252,19601226,19652403,19669731,19676726,19684940,19708757,19714700,19733262,19799447,19873223,19873223,19873223,19881011,19881011,19945933,19945933,20202964,20248617,20321628,20321628,20329544,20329544,20329544,20356298,20356298,20356298,20398860,20398860,20466701,20466701,20478660,20543482,20586155,20605672,20607591,20686386,20700338,20714189,20715637,20720291,20720291,20733036,20744119,20749808,20772398,20784851,20794184,20851118,20906578,20917125,20931080,20931080,20932669,20932669,20986226,20986226,20995151,21015433,21035552,21070608,21095801,21095801,21132838,21132838,21132838,21132838,21145282,21145282,21155472,21156428,21182105,21217576,21217576,21217576,21217576,21217576,21280614,21302615,21317962,21323167,21342505,21346566,21346566,21346566,21394171,21467621,21482337,21482337,21491867,21534489,21555136,21555136,21582172,21619550,21619550,21619550,21673716,21688899,21697297,21697297,21701506,21726086,21739590,21748613,21768008,21768008,21777535,21787643,21791746,21820948,21862573,21868026,21907495,21921134,21926360,21932237,21932237,21948160,21948590,22053529,22066247,22083399,22146322,22147411,22147411,22147411,22173356,22176560,22176560,22176560,22176560,22176560,22176560,22178845,22198813,22225327,22225327,22225327,22231438,22247209,22261315,22271174,22279973,22291410,22291410,22291410,22301049,22323310,22323310,22377766,22389217,22408092,22431119,22452076,22455738,22464032,22464032,22472192,22507252,22549670,22553869,22554573,22564283,22591730,22652040,22657320,22657320,22657320,22672535,22695472,22695472,22695472,22695472,22695472,22703228,22705630,22728852,22728852,22745552,22792295,22809634,22829756,22863603,22863603,22896477,22921952,22921952,22921952,22921952,22940223,22971573,22971573,23039162,23157202,23192642,23265939,23265939,23272418,23292078,23399299,23405365,23420912,23426251,23449632,23511689,23586545,23586545,23615286,23629652,23652659,23670293,23676790,23676790,23696455,23700909,23700909,23729695,23733975,23737873,23758710,23783452,23845890,23845890,23845890,23921507,23943964,23958183,23963642,23996968,23997932,23997932,23997932,23997932,24004411,24054156,24097241,24158121,24165424,24165424,24216637,24216637,24235979,24304152,24310085,24324849,24365184,24374579,24374579,24376266,24392322,24392322,24435100,24435565,24435565,24435565,24446392,24458745,24478159,24503407,24518263,24575646,24576785,24577121,24586247,24610908,24623992,24632195,24639452,24646775,24672167,24704484,24713183,24713183,24713183,24713183,24764835,24788761,24799185,24799185,24823386,24857898,24876415,24876415,24897814,24915353,24919656,24933861,24933861,24934527,24935115,24970021,24970021,25012119,25012119,25018384,25037087,25037087,25055282,25063189,25081426,25091328,25108600,25154374,25166057,25173416,25183782,25199746,25214664,25214664,25227714,25227714,25230179,25245637,25270933,25288141,25302993,25312635,25339690,25367892,25383775,25394056,25400827,25410046,25410046,25417645,25442236,25444211,25488905,25503339,25503339,25503339,25513627,25513627,25561696,25561696,25561696,25588991,25588991,25607738,25608098,25608098,25613889,25639091,25649576,25667862,25725670,25729217,25731652,25745763,25745763,25769400,25769400,25773920,25784765,25784765,25784765,25784765,25784765,25784765,25784765,25784765,25784765,25784765,25786622,25814048,25852501,25852501,25860630,25875418,25887512,25905203,25930162,25943928,25943928,25943928,25986090,25986090,25986090,26020276,26042171,26042171,26042171,26044652,26044652,26054721,26085503,26144917,26144917,26154769,26196551,26219498,26232130,26253856,26253856,26253856,26269038,26287185,26287185,26287185,26298159,26298159,26306374,26354148,26362712,26362712,26362712,26362712,26397991,26438744,26440644,26440644,26441889,26442471,26442471,26443094,26458759,26471310,26483616,26487784,26494105,26494105,26494105,26508881,26514699,26525787,26562040,26580169,26653696,26698876,26767587,26767587,26767587,26767587,26772452,26807957,26835206,26839113,26846766,26867759,26881334,26881334,26881334,26939244,26952680,26955096,26960732,26960732,26960732,26961664,26966143,26985714,26988453,26988453,27000352,27011145,27018062,27063042,27085169,27086212,27121257,27121257,27121257,27123231,27221223,27221223,27221223,27232116,27234250,27252951,27252951,27263602,27263602,27278289,27278642,27278642,27278642,27282225,27296346,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27333566,27351394,27351394,27354114,27388240,27413676,27427924,27432188,27443008,27476038,27486664,27525556,27525556,27527676,27572926,27572926,27572926,27573394,27590209,27595531,27598620,27621772,27654181,27677513,27679705,27679705,27679705,27706827,27722959,27727004,27771611,27802219,27810561,27812277,27837516,27837595,27847535,27857832,27888527,27893182,27912340,27923688,27933891,27957172,27977010,27977636,28062779,28114833,28124071,28204171,28234996,28291119,28291119,28299562,28330538,28330538,28367605,28375110,28375110,28375110,28375110,28377184,28379249,28393225,28427593,28427593,28434054,28434054,28434054,28434054,28434054,28452283,28467243,28467403,28467403,28513226,28516118,28579615,28579615,28597582,28625408,28630280,28635362,28652416,28668630,28680519,28709542,28721160,28783946,28783946,28783946,28792544,28792544,28793737,28835818,28870291,28883770,28883770,28883770,28883770,28891962,28891962,28891962,28901855,28901855,28901855,28901855,28901855,28972639,29054705,29069544,29088431,29090627,29130489,29154116,29154116,29180638,29182633,29207075,29264471,29287662,29301768,29351659,29393588,29418392,29419415,29419415,29444431,29444675,29452603,29452705,29472195,29553759,29575704,29577114,29612992,29617878,29689242,29725966,29737902,29753314,29768307,29796518,29799507,29821118,29821118,29822155,29822613,29859774,29862697,29909396,29909396,29909396,29944147,29944147,29944147,29944147,29973039,30030413,30063884,30063884,30083722,30083722,30083722,30083722,30084594,30248548,30277272,30277272,30356320,30359210,30359210,30393258,30488654,30488654,30496076,30548236,30548236,30558577,30575308,30575308,30575308,30575671,30580803,30608174,30608454,30611645,30611645,30617364,30617364,30653754,30658424,30658424,30658424,30658424,30658424,30723477,30723477,30767564,30785710,30785710,30785710,30785710,30786069,30843288,30846586,30855443,30859393,30866665,30884447,30891050,30902430,30919835,30931494,30944350,30948294,30958088,30958088,30958163,30980350,30980350,31047369,31047419,31057078,31084723,31084723,31084723,31098550,31098550,31098550,31110742,31128126,31129891,31164581,31180143,31192671,31227287,31238980,31246614,31285710,31399578,31429507,31438668,31447972,31504761,31507182,31511557,31535587,31535587,31539559,31549063,31578823,31629262,31653135,31662561,31664630,31710664,31763880,31771721,31773365,31811123,31822014,31831890,31831890,31831890,31831890,31838880,31852846,31852846,31926944,31928225,31948934,31954715,31983941,31983941,31985141,31985141,31988388,32033501,32043555,32047209,32048394,32055717,32064536,32064536,32095281,32102143,32154024,32177519,32178724,32210415,32210415,32337738,32339024,32339024,32339024,32395809,32424519,32434340,32441707,32458971,32477646,32494256,32524472,32536775,32571617,32572536,32576585,32577354,32603694,32620794,32620794,32628310,32634435,32637667,32644936) THEN TRUE
        ELSE FALSE
    END AS BALANCE_RESERVATION
        FROM MAIN_TABLE
    GROUP BY 1
),

-- FOR USERS WITH MULTIPLE TX

-- GET EOD BALANCE

GET_LATEST_BALANCE AS (
SELECT
    RBHBP.PROFILE_ID as GET_BALANCE_PROFILE_ID,
    AMOUNT_CURRENCY AS BALANCE_CURRENCY,
    SUM(LOCAL_BALANCE_END_OF_DAY) AS BALANCE_AMOUNT,
    SUM(GBP_BALANCE_END_OF_DAY) AS BALANCE_GBP
FROM REPORTS.REPORT_BORDERLESS_HISTORIC_BALANCES_PROFILES RBHBP
where TRUE
AND PROFILE_ID IN (SELECT BALANCE_CHECK.PROFILE_ID FROM BALANCE_CHECK WHERE BALANCE_RESERVATION = TRUE)
AND DATE_BALANCE = CURRENT_DATE() - 1
GROUP BY 1,2
),

GET_PRIOR_LEGAL_BALANCE AS (
SELECT
    RBHBP.PROFILE_ID as GET_BALANCE_PROFILE_ID,
    AMOUNT_CURRENCY AS BALANCE_CURRENCY,
    SUM(LOCAL_BALANCE_END_OF_DAY) AS BALANCE_AMOUNT,
    SUM(GBP_BALANCE_END_OF_DAY) AS BALANCE_GBP
FROM REPORTS.REPORT_BORDERLESS_HISTORIC_BALANCES_PROFILES RBHBP
where TRUE
AND PROFILE_ID IN (SELECT BALANCE_CHECK.PROFILE_ID FROM BALANCE_CHECK WHERE BALANCE_RESERVATION = TRUE)
AND DATE_BALANCE = '2022-12-14'
GROUP BY 1,2
),


CREATE_LATEST_BALANCE_VIEW AS (SELECT
MAIN_TABLE.USER_PROFILE_ID,
SOURCE_CURRENCY,
SUM(AMOUNT_IN_SOURCE_CCY) AS AMOUNT_IN_SOURCE_CCY,
SUM(AMOUNT_IN_GBP) AS AMOUNT_IN_GBP,
MAX(BALANCE_AMOUNT) AS BALANCE_AMOUNT,
MAX(BALANCE_GBP) AS BALANCE_GBP,
COUNT(TRANSFER_ID) AS COUNT_TX,
LISTAGG(WORK_ITEM_STATE,',') AS WORK_ITEM_STATES,
IFF(MAX(BALANCE_GBP) < 0, SUM(AMOUNT_IN_GBP) + MAX(BALANCE_GBP),NULL) AS BALANCE_PAID_GBP,
'LATEST' AS TYPE
FROM MAIN_TABLE
    LEFT JOIN GET_LATEST_BALANCE ON GET_LATEST_BALANCE.GET_BALANCE_PROFILE_ID = MAIN_TABLE.USER_PROFILE_ID AND GET_LATEST_BALANCE.BALANCE_CURRENCY = MAIN_TABLE.SOURCE_CURRENCY
WHERE TRUE
AND USER_PROFILE_ID IN (SELECT BALANCE_CHECK.PROFILE_ID FROM BALANCE_CHECK WHERE BALANCE_RESERVATION = TRUE)
AND CATEGORY IN ('N4','N3')
AND AMOUNT_IN_GBP <= 800
AND ((DATE_CLOSED IS NULL) OR (DATE_CLOSED >= '2022-12-09'))
GROUP BY 1,2
HAVING SUM(AMOUNT_IN_SOURCE_CCY) > 200),


CREATE_PRIOR_BALANCE_VIEW AS (SELECT
MAIN_TABLE.USER_PROFILE_ID,
SOURCE_CURRENCY,
SUM(AMOUNT_IN_SOURCE_CCY) AS AMOUNT_IN_SOURCE_CCY,
SUM(AMOUNT_IN_GBP) AS AMOUNT_IN_GBP,
MAX(BALANCE_AMOUNT) AS BALANCE_AMOUNT,
MAX(BALANCE_GBP) AS BALANCE_GBP,
COUNT(TRANSFER_ID) AS COUNT_TX,
LISTAGG(WORK_ITEM_STATE,',') AS WORK_ITEM_STATES,
IFF(MAX(BALANCE_GBP) < 0, SUM(AMOUNT_IN_GBP) + MAX(BALANCE_GBP),NULL) AS BALANCE_PAID_GBP,
'PRIOR_LEGAL' AS TYPE
FROM MAIN_TABLE
    LEFT JOIN GET_PRIOR_LEGAL_BALANCE ON GET_PRIOR_LEGAL_BALANCE.GET_BALANCE_PROFILE_ID = MAIN_TABLE.USER_PROFILE_ID AND GET_PRIOR_LEGAL_BALANCE.BALANCE_CURRENCY = MAIN_TABLE.SOURCE_CURRENCY
WHERE TRUE
AND USER_PROFILE_ID IN (SELECT BALANCE_CHECK.PROFILE_ID FROM BALANCE_CHECK WHERE BALANCE_RESERVATION = TRUE)
AND CATEGORY IN ('N4','N3')
AND AMOUNT_IN_GBP <= 800
AND ((DATE_CLOSED IS NULL) OR (DATE_CLOSED >= '2022-12-09'))
GROUP BY 1,2
HAVING SUM(AMOUNT_IN_SOURCE_CCY) > 200),


TEMP_TABLE AS (

    (SELECT * FROM CREATE_LATEST_BALANCE_VIEW) UNION ALL (SELECT * FROM CREATE_PRIOR_BALANCE_VIEW)

)

SELECT
TYPE,
CASE
    WHEN BALANCE_AMOUNT >= 0 THEN 'RECOVERED'
    WHEN BALANCE_AMOUNT < 0 AND ABS(BALANCE_AMOUNT) > ABS(AMOUNT_IN_SOURCE_CCY) THEN 'UNKNOWN_STATE'
    WHEN (AMOUNT_IN_SOURCE_CCY - ABS(BALANCE_AMOUNT))/AMOUNT_IN_SOURCE_CCY  > 0.1 THEN 'PARTIAL_RECOVERY'
    ELSE 'NO_RECOVERY'
END AS BALANCE_RECOVERY_STATE,
    ROUND(SUM(AMOUNT_IN_GBP)) AS AFFECTED_AMOUNT_GBP,
    IFF(SUM(BALANCE_GBP) < 0,ROUND(SUM(BALANCE_GBP)),0) AS REMAINING_BALANCE_GBP,
    ROUND(COALESCE(SUM(BALANCE_PAID_GBP),SUM(AMOUNT_IN_GBP))) AS AMOUNT_PAID_GBP,
    SUM(COUNT_TX) AS NUM_TRANSFERS,
    COUNT(DISTINCT USER_PROFILE_ID) AS NUM_PROFILES,
    ANY_VALUE(CONCAT(USER_PROFILE_ID,'-',SOURCE_CURRENCY,'-',AMOUNT_IN_GBP)) AS SAMPLE_USE_CASE_USER_CCY_AFFAMTGBP,
    LISTAGG(USER_PROFILE_ID,',') AS LIST_PROFILES
FROM TEMP_TABLE
GROUP BY 1,2 ORDER BY 1
