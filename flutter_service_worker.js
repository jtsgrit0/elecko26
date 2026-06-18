'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"version.json": "31729911078a552655fb045098aeb132",
"index.html": "1834a71d1c5943b59e8e24f5910944dd",
"/": "1834a71d1c5943b59e8e24f5910944dd",
"main.dart.js": "7179f6b6316817ec6f3b837e74b5c064",
"flutter.js": "c71a09214cb6f5f8996a531350400a9a",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "31980859bbc251c7eceb7a6438ab29c3",
"assets/AssetManifest.json": "2ae5723f2f0bba67467d4479f6b4a9e2",
"assets/NOTICES": "f311906651dd6c880bb83fcb53a970a0",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "03eaea978de8e401f5945807f50a2f7e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "ffd063c5ddbbe185f778e7e41fdceb31",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "4ca23b095368b319141e78ba6e47a09f",
"assets/fonts/MaterialIcons-Regular.otf": "49fca37222cd83b70ae82a7dbad3067e",
"assets/data/election_candidates_backup_1776636741329.json": "93b6dd7fca40118f65d3b5e3130073da",
"assets/data/election_candidates_analyzed_backup_1776929995624.json": "4205972937e7c918b3c8e70a2d3a443a",
"assets/data/election_candidates_enriched_backup_1776642700103.json": "ac62468089a55566eb72881c12fed1ec",
"assets/data/election_candidates_backup_1776636063971.json": "a9d0ce9350c50f03d81fdeefbe500b11",
"assets/data/nesdc_polls_pretty.json": "cb2df6413afceeed37d7b1bcb445097f",
"assets/data/election_candidates_backup_1776636818895.json": "7a31816bf681c685ba25a531bbd1bc2e",
"assets/data/election_candidates_analyzed_backup_1776929620253.json": "bd6afcd2ba76ce4cde6fdf88d459d432",
"assets/data/election_candidates_backup_1776638085723.json": "9b4766303bab46d44f961b08306cd27a",
"assets/data/election_candidates_enriched_backup_1776663379624.json": "ce623d401ff9af61c783122e0b4c704e",
"assets/data/election_candidates_backup_1776637555424.json": "44124f979473bed0b37844054d7c474c",
"assets/data/election_candidates_enriched_backup_1776664147870.json": "c1681111f7ce47084ce16b28c2a19435",
"assets/data/election_candidates_analyzed_backup_1776929586999.json": "8005e92432e6e449403f2e8d9063ef39",
"assets/data/election_candidates_backup_1776637592000.json": "a515e74821925c69925238950a44a2ca",
"assets/data/election_candidates_analyzed_backup_1776929381093.json": "8005e92432e6e449403f2e8d9063ef39",
"assets/data/election_candidates_analyzed_backup_1776932910326.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_backup_1776637813383.json": "3e260a85fbc20b98863e6edcaa48b89c",
"assets/data/election_candidates_backup_1776636376053.json": "0d20c04109a14c345b7ac9e90ee2304f",
"assets/data/historical_election_6th.json": "2614d534f48f681ec72e88ccbf395c41",
"assets/data/election_candidates_enriched_backup_1776925902050.json": "f9e5907d2ffd6a4138d9d93204835795",
"assets/data/election_candidates_backup_1776636474993.json": "89ce943b11308640c6c40536b3c1ae8f",
"assets/data/election_candidates_enriched_backup_1776818373145.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_backup_1776636781302.json": "2d1e6b38ccb9f504b9445e80229ea1a8",
"assets/data/election_candidates_enriched_backup_1776934368324.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_enriched_backup_1776643604694.json": "d1d106cc0cc0ea92c7608604e232adb9",
"assets/data/election_candidates_backup_1776636857261.json": "04c583bdb598829806fd38349c86110a",
"assets/data/election_candidates_backup_1776637277948.json": "7056f35e1f3467ac2d6f967c5d6cbc27",
"assets/data/election_candidates_backup_1776636876245.json": "a6e68d44e1c1d613ac25fe407fa91fcc",
"assets/data/election_candidates_backup_1776636098671.json": "b62f60b26b27757669212c068912be2a",
"assets/data/election_candidates_enriched_backup_1776643026140.json": "ac62468089a55566eb72881c12fed1ec",
"assets/data/election_candidates_enriched_backup_1776643238793.json": "53c7fc5839115fc26aa5a33ffc51314f",
"assets/data/election_candidates_backup_1776637685118.json": "b7067c484552c6853f084af65cbdfaab",
"assets/data/election_candidates_backup_1776636532510.json": "04c1c3ee3fd79617b3dddde71d27269c",
"assets/data/election_candidates_backup_1776636415805.json": "8fb8ad45ee04fa6d0e25877a35b9213a",
"assets/data/election_candidates_backup_1776637757735.json": "eda71bf57da991f36bf3066c9d42bbf6",
"assets/data/election_candidates_backup_1776636571036.json": "8af0895768bf38dc239dd2e9bed194a7",
"assets/data/historical_election_8th.json": "cff226610ea121172d9cddb256bc80ff",
"assets/data/election_candidates_backup_1776636799820.json": "5bdab61b9819cec6e2146545a6bc3ab7",
"assets/data/election_candidates_enriched_backup_1776934443818.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_enriched_backup_1776646669998.json": "c21a1880e75b659f35de782c0995caac",
"assets/data/election_candidates_backup_1776637776838.json": "fcfd3a9ba57b09ca652c4f28af788663",
"assets/data/election_candidates_enriched_backup_1776665015617.json": "24653dc4b0b607508bbb867771f64a91",
"assets/data/election_candidates_enriched_backup_1776646506812.json": "1369a1d0bae2e67327843c7e4bd597e6",
"assets/data/election_candidates_backup_1776637259319.json": "f53e7eee295a41fa4c1948e51b794e4c",
"assets/data/historical_election_5th_summary.json": "f41a40cdd64f0a5eb65fd3dda847b392",
"assets/data/election_candidates_enriched_backup_1776639373998.json": "53c7fc5839115fc26aa5a33ffc51314f",
"assets/data/election_candidates_backup_1776638119743.json": "b3cc301124e70581887438c6f9913656",
"assets/data/election_candidates_enriched_backup_1776643073822.json": "ac62468089a55566eb72881c12fed1ec",
"assets/data/election_candidates_enriched_backup_1776665453316.json": "4eb07cce9dba465a4c80d584141b13f9",
"assets/data/election_candidates_backup_1776637126909.json": "381cc1b9e9c00f460d3be181aad46ab2",
"assets/data/election_candidates_backup_1776637221688.json": "a12853b4911a70e9408b63322bb5469e",
"assets/data/election_candidates_analyzed_backup_1776931120011.json": "0587b95e1a9d86630ede8349d91a6783",
"assets/data/election_candidates_backup_1776636077661.json": "11945feb8952151ab05b994d9fd575bf",
"assets/data/election_candidates_backup_1776637667405.json": "ff0a18b950e8d7809bbe95bf04d107b4",
"assets/data/election_candidates_enriched_backup_1776665832879.json": "6b88e121caf152be634f46706ecf2ac6",
"assets/data/election_candidates_enriched_backup_1776640192185.json": "083611464286e667c2e8059eb3f3e4a4",
"assets/data/election_candidates_enriched_backup_1776844681664.json": "b742370a793210c829c34b4df2c64847",
"assets/data/election_candidates_enriched_backup_1776644507751.json": "95ff536e0d72ee76e6b343fcb9685e35",
"assets/data/election_candidates_backup_1776637833610.json": "2267ba350dd901e5714ed5d366ff9f5d",
"assets/data/election_candidates_enriched_backup_1776643915649.json": "d1d106cc0cc0ea92c7608604e232adb9",
"assets/data/election_candidates_backup_1776636494334.json": "ab6fd431f8a3082ed87bd22ed6c059d3",
"assets/data/election_candidates_backup_1776637203501.json": "35fdda6ac4384f8e92d75bcb33457a9e",
"assets/data/election_candidates_backup_1776636760834.json": "bb771590c77a15c6f753fde09b61709b",
"assets/data/election_candidates_backup_1776636973083.json": "de8dd33927a62239cab101bc7ded09ee",
"assets/data/election_candidates_enriched_backup_1776818857154.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_backup_1776636934764.json": "b1523b3b2cb74b48caa089a3362746f6",
"assets/data/election_data.json": "fa2d6c2745d5dc7aab21ac35ddc1c393",
"assets/data/election_candidates_backup_1776632610318.json": "c0f5ba091592454950a639477d74e86d",
"assets/data/election_candidates_enriched_backup_1776820268056.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_analyzed_backup_1776930143225.json": "4205972937e7c918b3c8e70a2d3a443a",
"assets/data/election_candidates_enriched_backup_1776934839286.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_enriched_backup_1776934379358.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_backup_1776637386603.json": "a78262cc6d325931689a3a7270d6620d",
"assets/data/historical_election_8th_summary.json": "62cf660d9967e1b8be103be1411341c1",
"assets/data/election_candidates_backup_1776637069574.json": "1ab0012793b9ecc13eae6ec8a61cf8f8",
"assets/data/election_candidates_backup_1776637089777.json": "cce19cc10e215f960cc9791c0609e380",
"assets/data/election_candidates_backup_1776638137179.json": "814b050e6e9c4a1fed1ee6edbe1a7028",
"assets/data/election_candidates_analyzed_backup_1776934884899.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_backup_1776637958099.json": "e02dd60781fe75bb5aabf3343788220a",
"assets/data/election_candidates_backup_1776636278240.json": "a945ca76e4a2a35b1d88b4e32e3c6413",
"assets/data/election_candidates_enriched_backup_1776662349874.json": "be903e38a48616e2b7391db580e30fb7",
"assets/data/election_candidates_backup_1776637240830.json": "7916d4c2aa7ef31b3488c9e182566d28",
"assets/data/election_candidates_backup_1776637184905.json": "eb3995f2c055eb57ceed8a4af8893fa2",
"assets/data/election_candidates_backup_1776636454093.json": "8f7e33eb1e10f87909efa05d28656b10",
"assets/data/election_candidates_backup_1776636158416.json": "82c58449e73100b0e1cbf8f6a0df493f",
"assets/data/election_candidates_cleaned_backup_1776639440847.json": "53c7fc5839115fc26aa5a33ffc51314f",
"assets/data/election_candidates_analyzed_backup_1776929946642.json": "4205972937e7c918b3c8e70a2d3a443a",
"assets/data/election_candidates_backup_1776638103353.json": "f6de3f2f0135f71188f1c31ab1f4b802",
"assets/data/election_candidates_backup_1776636298262.json": "d1fca46178945355c3dbc9201eff20d2",
"assets/data/election_candidates_enriched_backup_1776644171244.json": "d1d106cc0cc0ea92c7608604e232adb9",
"assets/data/historical_election_7th_summary.json": "e1a1440623ed5594010f800055404217",
"assets/data/election_data_pretty.json": "407a635ce6105c74480ba7a53dac6494",
"assets/data/election_candidates_backup_1776632239904.json": "1dd51a33a1e793c9c475c2057df63530",
"assets/data/election_candidates_backup_1776637648602.json": "1ca4a23dd255201f1fa98be419557881",
"assets/data/election_candidates_enriched_backup_1776666136380.json": "2a65be22b3f37b95858fd56e8c8318ad",
"assets/data/election_candidates_backup_1776638153599.json": "b6693c59691e75966d683a2b50118ee5",
"assets/data/historical_election_6th_summary.json": "5988a96f41ce799166fd95fa38aee86f",
"assets/data/election_candidates_backup_1776635987771.json": "ec8a242c9788bd6644a9fe1b1eee14c5",
"assets/data/election_candidates_enriched_backup_1776639312783.json": "53c7fc5839115fc26aa5a33ffc51314f",
"assets/data/election_candidates_backup_1776636008517.json": "41da97e19a5dd1b3eb7a3adb1faa02d6",
"assets/data/election_candidates_backup_1776636198922.json": "879be7b5f1a574f8348e9122bc9eba5f",
"assets/data/election_candidates_enriched_backup_1776644554088.json": "1aa16d986b0c4e76ed48de48748880ed",
"assets/data/election_candidates_backup_1776637869079.json": "5e6b0d6de7c37373d401531493fbecdf",
"assets/data/election_candidates_backup_1776637721316.json": "4a9d348806d39780946f8f7ac750a20a",
"assets/data/election_candidates_enriched_backup_1776822818227.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_enriched_backup_1776644734697.json": "352382d4cd6188839e4df69d381d90c2",
"assets/data/election_candidates_backup_1776637108294.json": "a795eee18849062149a66c303ea73f75",
"assets/data/election_candidates_enriched_backup_1776640440708.json": "083611464286e667c2e8059eb3f3e4a4",
"assets/data/election_candidates_backup_1776636954155.json": "9fdf791fcbd40eeabb77fe7cb5df36f0",
"assets/data/election_candidates_enriched_backup_1776785790452.json": "73795f1a311f520a758dbf57723c3016",
"assets/data/election_candidates_backup_1776636589592.json": "b2336cca288a171f1a3fabed047d1718",
"assets/data/election_candidates_enriched_backup_1776818748153.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_backup_1776636048217.json": "fb67adae6a49357ea332eeb6f74f61b0",
"assets/data/election_candidates_backup_1776636626517.json": "b34b175b84e30ff398d21001f93e9123",
"assets/data/election_candidates_backup_1776636896368.json": "54464533816ddcdf5f7506a62e3df9a3",
"assets/data/election_candidates_backup_1776637994589.json": "5b0616d06b24724f874455d38970fd75",
"assets/data/election_candidates_analyzed_backup_1776930092971.json": "4205972937e7c918b3c8e70a2d3a443a",
"assets/data/election_candidates_enriched_backup_1776818787612.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/historical_elections_combined.json": "ed83e44e455b088f063ae6be44619177",
"assets/data/election_candidates_backup_1776637572818.json": "87fa9b412bbcf6acab0293ff92e032c0",
"assets/data/election_candidates_enriched_backup_1776646023606.json": "86dc2022da90e9ce9a3594d69bef2399",
"assets/data/election_candidates_enriched_backup_1776644432464.json": "71a07eabd570c4480479964088da6741",
"assets/data/election_candidates_backup_1776637535828.json": "bbc75b2e24ff1ca7c1ed5eecabeac36d",
"assets/data/election_candidates_backup_1776637922393.json": "70b8542d8263579cb958cd4501e02a06",
"assets/data/election_candidates_enriched_backup_1776664275858.json": "e41a7505ab83bb0b4d0c9e1103992efc",
"assets/data/election_candidates_backup_1776637610248.json": "460b947389011f704fc97eb2333910fa",
"assets/data/election_candidates_analyzed_backup_1776929893789.json": "4205972937e7c918b3c8e70a2d3a443a",
"assets/data/election_candidates_backup_1776636336599.json": "ad695ba360ed70a5f04cca914275c011",
"assets/data/election_candidates_analyzed_backup_1776930181285.json": "4205972937e7c918b3c8e70a2d3a443a",
"assets/data/election_candidates_enriched_backup_1776820428201.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_enriched_backup_1776820389724.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_enriched_backup_1776666046394.json": "92d2a0026e7f775cc1682dbecdaefd59",
"assets/data/election_candidates_backup_1776636512474.json": "24a06a8b71a2f495572d9bd9ddbb589b",
"assets/data/historical_election_7th.json": "6a837f65c864e8fe1d2b025d5023d7ba",
"assets/data/election_candidates_backup_1776636552513.json": "cee85a49e5c685c06c6281cebe5c9af9",
"assets/data/election_candidates_backup_1776635892829.json": "3561ee38426de41bda95d41df10aa675",
"assets/data/election_candidates_enriched_backup_1776646087685.json": "a2a67e071ce9cb6d3d270af1c375a734",
"assets/data/election_candidates_backup_1776638013265.json": "12ebca2e52c6c9905a804d354f2e3651",
"assets/data/election_candidates_backup_1776636028321.json": "986acfbfd38e7b03576cff24959607aa",
"assets/data/election_candidates_backup_1776636683956.json": "7c6ab65f32591e1639525a3cd6dcb909",
"assets/data/election_candidates_backup_1776636118898.json": "3d84dc2a39b59964cdf546f657dc7e79",
"assets/data/election_candidates_backup_1776637166294.json": "30f536ced6d7d2a1ebe21a2364bc0eef",
"assets/data/election_candidates_enriched_backup_1776818968161.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_backup_1776636356101.json": "51647a2abd20dff622bcf25d927dee3c",
"assets/data/election_candidates_backup_1776637295986.json": "900a770ac57f8cb4b6153c42413f7a53",
"assets/data/election_candidates_backup_1776637010459.json": "c29b31393b12246e8ba65141977ba3ec",
"assets/data/election_candidates_backup_1776637313220.json": "2ad0013a58e6f14b4289d807e9883ed1",
"assets/data/election_candidates_backup_1776637496889.json": "b678fc42828af7a04948fe951f61d97a",
"assets/data/election_candidates_enriched_backup_1776644672791.json": "a9781c857e1038971b0923bdd01730fa",
"assets/data/election_candidates_backup_1776637051800.json": "a7a3cac224af1b8072a3966c02163d19",
"assets/data/election_candidates_backup_1776637629554.json": "4c49aa3804f9a7d1d4856abec96628e4",
"assets/data/election_candidates_enriched_backup_1776661251473.json": "be903e38a48616e2b7391db580e30fb7",
"assets/data/election_candidates_backup_1776637406771.json": "44bd0f2a17f8fc3de86887e255272eeb",
"assets/data/election_candidates_enriched_backup_1776644243699.json": "5dc9737dcf4939cce294300674d44ad0",
"assets/data/election_candidates_backup_1776633135889.json": "d6fd4b2ef2348b78a332e3240d99c7f2",
"assets/data/election_candidates_backup_1776636645164.json": "38f23137f1c85cd5b187bf407be537f3",
"assets/data/election_candidates_backup_1776637939726.json": "cd22e6b394ef165f7e59a430548e0f45",
"assets/data/election_candidates_backup_1776635852497.json": "db189829c4b8bddb568422a1cf2c8022",
"assets/data/election_candidates_analyzed_backup_1776929054907.json": "2737fc14fd1752267406e53e41f62ba5",
"assets/data/election_candidates_backup_1776637795212.json": "c3435f895ba4a4d0f5392d7ab5fb4c4c",
"assets/data/election_candidates_backup_1776636839441.json": "d82a33d7c2a7288021194ce26ddc50c8",
"assets/data/candidates_split/candidates_4.json": "62119902e0af7a567e48d6b4595a1129",
"assets/data/candidates_split/candidates_8.json": "c731f310ee2db8812c77f442647c26ca",
"assets/data/candidates_split/candidates_5.json": "afeb30bfe2dfbfcff63df9d4884663a0",
"assets/data/candidates_split/candidates_2.json": "26cd5f76d3d07a07f396763cb29e34ad",
"assets/data/candidates_split/candidates_3.json": "4764116bd0918889bd553c7efe43b0ea",
"assets/data/candidates_split/candidates_0.json": "564507b29862a547c12cb3d11d982bf2",
"assets/data/candidates_split/candidates_1.json": "d1855ceb86dadcf28481e772d25e1016",
"assets/data/candidates_split/candidates_6.json": "f277e6a0bad8e76d05e1d474516f781b",
"assets/data/candidates_split/candidates_7.json": "180258d9899a3f45a52989351246b7ae",
"assets/data/election_candidates_enriched_backup_1776639782021.json": "13fc7e8d3f121c701ccabfe5c414f2b8",
"assets/data/election_candidates_enriched_backup_1776664651528.json": "fa3608852e60d0cc7e576a6ddcad93a7",
"assets/data/election_candidates_backup_1776636394784.json": "d7ffdfd0731e8a821513e44210adaffa",
"assets/data/election_candidates_backup_1776637739913.json": "e4ca6e06da67252fd53c6b38458f06b6",
"assets/data/election_candidates_enriched_backup_1776662427783.json": "977b990ac007f6c40cec2dc042773b00",
"assets/data/historical_election_5th.json": "fe6bbc1afdf5fb8e741fcf2dc5ad0634",
"assets/data/election_candidates_enriched_backup_1776639642061.json": "13fc7e8d3f121c701ccabfe5c414f2b8",
"assets/data/election_candidates_backup_1776637887196.json": "b340b1c3452a987e07aba9a723bfb694",
"assets/data/election_candidates_enriched_backup_1776663855295.json": "0fd7f2f6b5a0da7534a7a0460f9002f3",
"assets/data/election_candidates_backup_1776637351064.json": "047eedb344bc5d81cabc727df10b639f",
"assets/data/election_candidates_enriched_backup_1776663906967.json": "0fd7f2f6b5a0da7534a7a0460f9002f3",
"assets/data/election_candidates_enriched_backup_1776932890081.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_enriched_backup_1776818592893.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_enriched_backup_1776818639793.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_enriched_backup_1776665237624.json": "bedbd1a50b3d01d69e34209c55e88008",
"assets/data/election_candidates_enriched_backup_1776661984492.json": "be903e38a48616e2b7391db580e30fb7",
"assets/data/election_candidates_backup_1776632571945.json": "123ac225570c85c054340ca0939ecfc1",
"assets/data/election_candidates_enriched_backup_1776808137828.json": "1bc8a7d00788514b73226965c4099596",
"assets/data/election_candidates_backup_1776636138911.json": "a5e611f8f03a5c0f4eed5c5f2aadc3fc",
"assets/data/election_candidates_enriched_backup_1776663210627.json": "230d99bbe6e123cfa67edbfbbdfd7d98",
"assets/data/election_candidates_backup_1776638171443.json": "fd312482dffa6d8af0664cf24693c1a0",
"assets/data/election_candidates_enriched_backup_1776639896352.json": "9a55d79e1fc138285f2beb06c8f18a3e",
"assets/data/election_candidates_backup_1776635873504.json": "564b962e9eca2bedf79f25936d20e569",
"assets/data/election_candidates_backup_1776636238753.json": "e11ac9396d522f45fff884a232f7e60c",
"assets/data/election_candidates_analyzed_backup_1776929264331.json": "8005e92432e6e449403f2e8d9063ef39",
"assets/data/election_candidates_enriched_backup_1776818818795.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/historical_pdf_data.json": "36773f56201e0564100f83186b2ed093",
"assets/data/election_candidates_backup_1776637424830.json": "25e691bec49f3dc6168b221d2bac7346",
"assets/data/election_candidates_enriched_backup_1776642741745.json": "ac62468089a55566eb72881c12fed1ec",
"assets/data/election_candidates_enriched_backup_1776646465375.json": "1369a1d0bae2e67327843c7e4bd597e6",
"assets/data/election_candidates_analyzed_backup_1776929026890.json": "2737fc14fd1752267406e53e41f62ba5",
"assets/data/election_candidates_backup_1776636178196.json": "06a9d44b92b34e09bb8b44aefde3f694",
"assets/data/election_candidates_enriched_backup_1776640623047.json": "cf0e385741fe45be72ae8d31f6815ca1",
"assets/data/election_candidates_backup_1776638049103.json": "31f2f1fecf0b4564a80e41d77dbfc240",
"assets/data/election_candidates_backup_1776637368508.json": "b864351e17a91dbd9590f1b97a840646",
"assets/data/election_candidates_backup_1776637479758.json": "981f9fffca1e5e185b3088405d6e9a1f",
"assets/data/election_candidates_backup_1776636992308.json": "2d85bd4c1d4642ea40fb124c6856ae62",
"assets/data/election_candidates_backup_1776637703055.json": "c71879000a027ba33b17fe639a054bc8",
"assets/data/election_candidates_backup_1776636258723.json": "8d68ff7892b37d90b4881900295ac01b",
"assets/data/election_candidates_backup_1776637851059.json": "fbc376a187336fde26f8b01d0f79e1ba",
"assets/data/election_candidates_backup_1776637975849.json": "376ce462aa0db9c0233efe8880eb5637",
"assets/data/election_candidates_enriched_backup_1776639220058.json": "53c7fc5839115fc26aa5a33ffc51314f",
"assets/data/election_candidates_enriched_backup_1776934291972.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_enriched_backup_1776820314544.json": "f2ae7236c30058af88d233d88098b20b",
"assets/data/election_candidates_backup_1776637147192.json": "d1e1ab9246d7ac7852fb2ae0688c875f",
"assets/data/election_candidates_backup_1776636703682.json": "27919fe17a49eac9dd60fe0bc0bfd6c5",
"assets/data/election_candidates_backup_1776637462338.json": "8d45b015513a808e549491d71cb13610",
"assets/data/election_candidates_backup_1776636915534.json": "171c525f12d3cb2f356f7ad5d6404958",
"assets/data/election_candidates_backup_1776637033172.json": "3fb0559eb4c18f7ddea19ba9bca92cd9",
"assets/data/election_candidates_backup_1776636317579.json": "bae1020f2103ca0714d1e4511319a075",
"assets/data/election_candidates_backup_1776636219039.json": "1e2140567f06ce817c23ed526fa427d2",
"assets/data/election_candidates_backup_1776637905376.json": "943bdf0a86ef1ba0deb0b081cb64d0a1",
"assets/data/election_candidates_enriched_backup_1776642857952.json": "ac62468089a55566eb72881c12fed1ec",
"assets/data/election_candidates_backup_1776636665022.json": "52c8b14c00e9c351e72255fe47c10c86",
"assets/data/election_candidates_backup_1776637516244.json": "eb27dfd55cd7120630a23049e2dfae9a",
"assets/data/election_candidates_backup_1776638030650.json": "a8ebc2a6b329c234668416f30f24a252",
"assets/data/nesdc_polls.json": "9e0d93676744a0b104f0c082427d2665",
"assets/data/election_candidates_enriched_backup_1776844181421.json": "1717e94d7167037ba4e8592833eb2573",
"assets/data/election_candidates_backup_1776636608123.json": "d44d16e0ac9c0a598f3732862699f379",
"assets/data/election_candidates_backup_1776636723516.json": "4420c4c9a02e2101a94d1375b8e45dc8",
"assets/data/election_candidates_backup_1776636435053.json": "723dcca13a1683e84e2759144e53778a",
"assets/data/election_candidates_backup_1776637443042.json": "4dc37ac6586c82b0e35ef0613cb00433",
"assets/data/election_candidates_enriched_backup_1776813908972.json": "ce387eeb9372eff8806078ff27386062",
"assets/data/election_candidates_analyzed_backup_1776931007782.json": "0587b95e1a9d86630ede8349d91a6783",
"assets/data/election_candidates_backup_1776637332297.json": "1994b59c04f4c618a26bf07fb0386883",
"assets/data/election_candidates_backup_1776638066118.json": "f4b002ec11d7b4563259918315893459",
"assets/data/election_candidates_enriched_backup_1776638823089.json": "aa9f24c688bb6224893b0135cddfdf2f",
"assets/data/election_candidates_keyword_backup_1776935070090.json": "fbea39f57b76e1462aa2e2576e911ba6",
"assets/data/election_candidates_enriched_backup_1776879717610.json": "e9c0ab554dbfc2c9c9629603a3567031",
"assets/assets/images/party/progressive.png": "27d31b488bfac24c1ca853fce71909f3",
"assets/assets/images/party/reform.png": "25a7759c519eddea223cc49eaaa57611",
"assets/assets/images/party/power.png": "4cf08b022b05670cdf6fa18da818be8d",
"assets/assets/images/party/minjoo.png": "ae93fe1a25dedf4a6e79c1b2f960b228",
"assets/assets/images/party/basicincome.png": "bc0892a2ad14c9a474d9fc62f3200eb8",
"assets/assets/images/party/justice.png": "718524f95e196e5a5054ac274c9fb5f9",
"assets/assets/images/party/rebuilding.png": "85dc98fb784b523079f978bad5ee8d42",
"assets/assets/images/silla_duel.png": "4f357c65e09b085f2aa9887126106633",
"assets/assets/images/election_icon.png": "54601939b845979c465e4b09c3c32404",
"canvaskit/skwasm.js": "445e9e400085faead4493be2224d95aa",
"canvaskit/skwasm.js.symbols": "741d50ffba71f89345996b0aa8426af8",
"canvaskit/canvaskit.js.symbols": "38cba9233b92472a36ff011dc21c2c9f",
"canvaskit/skwasm.wasm": "e42815763c5d05bba43f9d0337fa7d84",
"canvaskit/chromium/canvaskit.js.symbols": "4525682ef039faeb11f24f37436dca06",
"canvaskit/chromium/canvaskit.js": "43787ac5098c648979c27c13c6f804c3",
"canvaskit/chromium/canvaskit.wasm": "f5934e694f12929ed56a671617acd254",
"canvaskit/canvaskit.js": "c86fbd9e7b17accae76e5ad116583dc4",
"canvaskit/canvaskit.wasm": "3d2a2d663e8c5111ac61a46367f751ac",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
