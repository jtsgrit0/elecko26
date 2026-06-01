'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"members.json": "a38ee068722c755d1e3c2e735641acf2",
"version.json": "31729911078a552655fb045098aeb132",
"icons/Icon-maskable-192.png": "934c165ec492e3e9b981542c24fa1e0f",
"icons/Icon-512.png": "934c165ec492e3e9b981542c24fa1e0f",
"icons/Icon-maskable-512.png": "934c165ec492e3e9b981542c24fa1e0f",
"icons/Icon-192.png": "934c165ec492e3e9b981542c24fa1e0f",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"log.txt": "ece84a4578a2cd3c29cab321a663f266",
"splash/img/dark-1x.png": "2775d79238bfa15c8396d50d876d351d",
"splash/img/light-2x.png": "c7901ce2bd764ff768c8441129c34a31",
"splash/img/light-4x.png": "4ea64e9799da1eb7ff5fed78cd3c505c",
"splash/img/dark-4x.png": "4ea64e9799da1eb7ff5fed78cd3c505c",
"splash/img/dark-2x.png": "c7901ce2bd764ff768c8441129c34a31",
"splash/img/light-3x.png": "23a7496d8f7251f521a3cff0939ab185",
"splash/img/dark-3x.png": "23a7496d8f7251f521a3cff0939ab185",
"splash/img/light-1x.png": "2775d79238bfa15c8396d50d876d351d",
"api/members.json": "312d382c4e87b9cfe7370fe5578e86c9",
"members.php": "c56f68a62ac7c428019fdd27e334e12c",
"check_env.php": "53628903e3c9cf1593d4ef97067fba40",
"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"insert_members.php": "cc76383e4956cbace74ba8012f4ef421",
"dummy.txt": "81e6a22b62fc6e28e355713517fdc3d8",
"flutter_bootstrap.js": "74d7ab9f074c44ce96d60fd4064bb511",
"manifest.json": "31980859bbc251c7eceb7a6438ab29c3",
"index.html": "d25366562cf731879d50d593390eab9e",
"/": "d25366562cf731879d50d593390eab9e",
"favicon.png": "934c165ec492e3e9b981542c24fa1e0f",
"members_temp.php": "10ebf2a6ce5f0d264102a30d10289221",
"main.dart.js": "e3e369f69839b90c535607898c644abe",
"assets/NOTICES": "ea166bb1c785e87f796c14ff25f14b27",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/AssetManifest.bin": "8d0972118d44efd29bcd1a3c92a9ba07",
"assets/AssetManifest.bin.json": "8f67ed26b7cf258593e76667785e069f",
"assets/api/members.json": "312d382c4e87b9cfe7370fe5578e86c9",
"assets/api/members_with_images.json": "2d5037210df5f62e6c2adcb559c4a645",
"assets/api/members_with_images.json.tmp": "d41d8cd98f00b204e9800998ecf8427e",
"assets/api/members_test.json": "6a9191318c3f0d04aaa846cf27a9691e",
"assets/api/members.php": "bcd1717d4d94c5ab9685228f2717b5a3",
"assets/api/check_env.php": "53628903e3c9cf1593d4ef97067fba40",
"assets/api/members_enriched_with_history.json": "ee5b015659f1ac131d570c9a9bf9ec5c",
"assets/api/party_support_trends.json": "8679cab03a8512751b413418ca81a9a3",
"assets/api/insert_members.php": "cc76383e4956cbace74ba8012f4ef421",
"assets/api/members_with_images_temp.json": "8b56ca4df623a768103fd719fae78a29",
"assets/api/members_enriched.json": "8bd2d5877bfd23bfb8c30875f5c9d33f",
"assets/api/members_enriched.json.bak": "8bd2d5877bfd23bfb8c30875f5c9d33f",
"assets/AssetManifest.json": "f5ae1fe22cf4d42420a5de1eec36a6b8",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "f26a5e8a7463dadb7d2d6fccd27f098c",
"assets/assets/pdf/pdf_filename_mapping.json": "000f1992d4a28fa69579287f9a6248ed",
"assets/assets/animations/horse_animation.json": "4158745d0cf605c348e15a17ebab5cc8",
"assets/assets/images/avatar.png": "934c165ec492e3e9b981542c24fa1e0f",
"assets/assets/images/party/justice.png": "718524f95e196e5a5054ac274c9fb5f9",
"assets/assets/images/party/minjoo.png": "ae93fe1a25dedf4a6e79c1b2f960b228",
"assets/assets/images/party/progressive.png": "27d31b488bfac24c1ca853fce71909f3",
"assets/assets/images/party/rebuilding.png": "85dc98fb784b523079f978bad5ee8d42",
"assets/assets/images/party/reform.png": "25a7759c519eddea223cc49eaaa57611",
"assets/assets/images/party/power.png": "4cf08b022b05670cdf6fa18da818be8d",
"assets/assets/images/party/basicincome.png": "bc0892a2ad14c9a474d9fc62f3200eb8",
"assets/assets/images/silla_duel.png": "4f357c65e09b085f2aa9887126106633",
"assets/assets/images/election_icon.png": "934c165ec492e3e9b981542c24fa1e0f",
"assets/assets/images/elecko26_icon.png": "934c165ec492e3e9b981542c24fa1e0f",
"assets/assets/data/polls/%25EC%25B2%25AD%25EC%25A3%25BC%25EC%258B%259C%25EC%2583%2581%25EB%258B%25B9%25EA%25B5%25AC.json": "d9908320c4c46b6c5f04fb5f5de889fd",
"assets/assets/data/polls/%25EA%25B0%2580%25ED%258F%2589%25EA%25B5%25B0.json": "9d03d2b2c38accb08fe9bad283499ce0",
"assets/assets/data/polls/%25EC%259E%25A5%25EC%2588%2598%25EA%25B5%25B0.json": "63da796f8bfc64734ac9d2688980e2d8",
"assets/assets/data/polls/%25EC%2598%2581%25EC%25A3%25BC%25EC%258B%259C.json": "a99ed0291b06c47b06f16845655c820e",
"assets/assets/data/polls/%25EC%25B2%25AD%25EC%25A3%25BC%25EC%258B%259C%25ED%259D%25A5%25EB%258D%2595%25EA%25B5%25AC.json": "f9c5cb4e0e62eb906dcc8104c791c547",
"assets/assets/data/polls/%25ED%2595%25A8%25ED%258F%2589%25EA%25B5%25B0.json": "ca0601eeb33ec37a6d47aefd8c74adb5",
"assets/assets/data/polls/%25EC%2584%259C%25EC%25B2%259C%25EA%25B5%25B0.json": "4ce1ca50cd9dda11e3fac74c1f1a43d5",
"assets/assets/data/polls/%25EC%25A0%2584%25EC%25A3%25BC%25EC%258B%259C%25EB%258D%2595%25EC%25A7%2584%25EA%25B5%25AC.json": "facd66a5607fa878203ed33f5615b5ea",
"assets/assets/data/polls/%25EA%25B3%25A0%25ED%259D%25A5%25EA%25B5%25B0.json": "40f8f169fd60c1f17ccca64b56b986c6",
"assets/assets/data/polls/%25EB%25B3%25B4%25EC%2584%25B1%25EA%25B5%25B0.json": "1622980828149a522b3c347b4ff21fd9",
"assets/assets/data/polls/%25EC%259D%2598%25EB%25A0%25B9%25EA%25B5%25B0.json": "372a90c0d74acbbb35cbd6de06505fcd",
"assets/assets/data/polls/%25EC%25B0%25BD%25EB%2585%2595%25EA%25B5%25B0.json": "7f226db599aa91bb2c1ae0a2d0f30f06",
"assets/assets/data/polls/%25ED%259A%25A1%25EC%2584%25B1%25EA%25B5%25B0.json": "cbbe8d749c9419ec10918a8b0d6f7ef7",
"assets/assets/data/polls/%25EB%2585%25BC%25EC%2582%25B0%25EC%258B%259C.json": "ab2b613243fd0f93180f648ae2d2ccca",
"assets/assets/data/polls/%25ED%2595%25B4%25EB%2582%25A8%25EA%25B5%25B0.json": "8d0151fe3b642e4c63ecc4a2f9d0bfc7",
"assets/assets/data/polls/%25EA%25B0%2595%25EB%25A6%2589%25EC%258B%259C.json": "897c91d6db051398d7c9eb797478ad07",
"assets/assets/data/polls/%25EC%2586%258D%25EC%25B4%2588%25EC%258B%259C.json": "76112dfe5ab9c96a5d2477d19ae7bba6",
"assets/assets/data/polls/%25EC%25A7%2584%25EC%2595%2588%25EA%25B5%25B0.json": "fb7bc3bcc66e6735c8ca42b74e49a622",
"assets/assets/data/polls/%25EC%2595%2584%25EC%2582%25B0%25EC%258B%259C%25EC%259D%2584.json": "0a7a26f649a1d88cc437682f4f629f6e",
"assets/assets/data/polls/%25EC%25B2%25AD%25EC%2586%25A1%25EA%25B5%25B0.json": "44d16bbfb7ec49a2d8d741c2fcc03858",
"assets/assets/data/polls/%25ED%2595%25A8%25EC%2596%2591%25EA%25B5%25B0.json": "69a352861ba3281db9f9ac7f57f39ceb",
"assets/assets/data/polls/%25EC%259E%25A5%25EC%2584%25B1%25EA%25B5%25B0.json": "0d0e3026db0d8456d1ec1c1db9735057",
"assets/assets/data/polls/%25EC%259B%2590%25EC%25A3%25BC%25EC%258B%259C.json": "cbd1e12b485fbc1bf3c0e6a3865cdc87",
"assets/assets/data/polls/%25EA%25B5%25AC%25EB%25AF%25B8%25EC%258B%259C.json": "8002c95054d25ae7f30c4beb94397487",
"assets/assets/data/polls/%25EC%258B%259C%25ED%259D%25A5%25EC%258B%259C.json": "265235f7ce675c54f3dfad69173f20eb",
"assets/assets/data/polls/%25ED%258F%2589%25EC%25B0%25BD%25EA%25B5%25B0.json": "4feee455719fef0f8f9b4c9dd341cd4c",
"assets/assets/data/polls/%25ED%2595%25A9%25EC%25B2%259C%25EA%25B5%25B0.json": "41fb6453ee183c6181c965947b135947",
"assets/assets/data/polls/%25EC%259D%2598%25EC%2599%2595%25EC%258B%259C.json": "e37f16101d20c75f8e0e03c74f3bbf3a",
"assets/assets/data/polls/%25EC%25A0%2595%25EC%259D%258D%25EC%258B%259C.json": "360820f49f5823f8c84bd7add2689ec5",
"assets/assets/data/polls/%25EA%25B2%25BD%25EC%2582%25B0%25EC%258B%259C.json": "d33f7ca9d13f80ffb68a80d3148cc991",
"assets/assets/data/polls/%25EC%25B9%25A0%25EA%25B3%25A1%25EA%25B5%25B0.json": "1f6f5cea954c371b026ec8167b453992",
"assets/assets/data/polls/%25ED%258F%2589%25ED%2583%259D%25EC%258B%259C%25EC%259D%2584.json": "75904cb462885587881e63e09290466b",
"assets/assets/data/polls/%25ED%2599%2594%25EC%2584%25B1%25EC%258B%259C%25EB%25A7%258C%25EC%2584%25B8%25EA%25B5%25AC.json": "4c4905bf87bf4582631865211bdec8e2",
"assets/assets/data/polls/%25EA%25B3%25B5%25EC%25A3%25BC%25EC%258B%259C%25EB%25B6%2580%25EC%2597%25AC%25EA%25B5%25B0%25EC%25B2%25AD%25EC%2596%2591%25EA%25B5%25B0.json": "23a8179ffe8c8d8dbe845010162af5a7",
"assets/assets/data/polls/%25EA%25B4%2591%25EC%2582%25B0%25EA%25B5%25AC%25EC%259D%2584.json": "478d83bb0cf4e2eab825ba35ee716db0",
"assets/assets/data/polls/%25EA%25B3%25A0%25EC%25B0%25BD%25EA%25B5%25B0.json": "456d4cce1f4e450d8896fdc926e15fc5",
"assets/assets/data/polls/%25EC%259A%25A9%25EC%259D%25B8%25EC%258B%259C%25EC%25B2%2598%25EC%259D%25B8%25EA%25B5%25AC.json": "ec31d31b55bea696fd92c89bf1b3fc4b",
"assets/assets/data/polls/%25EA%25B8%2588%25EC%2582%25B0%25EA%25B5%25B0.json": "5fb40bb2d85a88ed8d659842bffc4a58",
"assets/assets/data/polls/%25EC%2597%25B0%25EC%2588%2598%25EA%25B5%25AC%25EA%25B0%2591.json": "ca5801f7cf4229104192c83ba08b2e6a",
"assets/assets/data/polls/%25ED%258F%25AC%25EC%25B2%259C%25EC%258B%259C.json": "f40801424d66188816a302c8dc524e70",
"assets/assets/data/polls/%25EC%2598%25A5%25EC%25B2%259C%25EA%25B5%25B0.json": "b40015b0d905cb5584d4f11e7932e864",
"assets/assets/data/polls/%25ED%2599%258D%25EC%25B2%259C%25EA%25B5%25B0.json": "60ac9a2510ceae09ce08966c21872365",
"assets/assets/data/polls/%25EA%25B2%25BD%25EC%2583%2581%25EB%25B6%2581%25EB%258F%2584.json": "b4504d90fc88a05486fc14ec8dea3984",
"assets/assets/data/polls/%25EC%25A0%2584%25EB%25B6%2581%25ED%258A%25B9%25EB%25B3%2584%25EC%259E%2590%25EC%25B9%2598%25EB%258F%2584.json": "6ff3515ff2f8254cfd3cba52463ac65a",
"assets/assets/data/polls/%25EC%2588%259C%25EC%25B0%25BD%25EA%25B5%25B0.json": "ae4f013892e4e70e412a17a23c7e4570",
"assets/assets/data/polls/%25EC%259D%2598%25EC%2584%25B1%25EA%25B5%25B0.json": "d4b27bd44f9569d39ca7bbb4cfac6bb1",
"assets/assets/data/polls/%25EC%2596%2591%25ED%258F%2589%25EA%25B5%25B0.json": "32bc4549d91d22da3948dbf21333e6e0",
"assets/assets/data/polls/%25EA%25B0%2595%25EC%25A7%2584%25EA%25B5%25B0.json": "13201181a37e08633904ca5e88da17e3",
"assets/assets/data/polls/%25EA%25B9%2580%25EC%25A0%259C%25EC%258B%259C.json": "2d87b447f4332a684532d467f385b789",
"assets/assets/data/polls/%25EC%2598%2581%25EA%25B4%2591%25EA%25B5%25B0.json": "2142f562135bd0a670626ff54c94dec7",
"assets/assets/data/polls/%25EC%2584%25B1%25EC%25A3%25BC%25EA%25B5%25B0.json": "af9be6f8c253e52b33e07762c3a04759",
"assets/assets/data/polls/%25ED%258F%25AC%25ED%2595%25AD%25EC%258B%259C%25EB%25B6%2581%25EA%25B5%25AC.json": "5a698e96ae0cb08d59f4064b7dfafec3",
"assets/assets/data/polls/%25EB%2582%25A8%25EC%2596%2591%25EC%25A3%25BC%25EC%258B%259C.json": "489432f0b08a03ac310d4dae3b6ba13e",
"assets/assets/data/polls/%25EC%2582%25BC%25EC%25B2%2599%25EC%258B%259C.json": "8f254bf43b264d559a026fa8c47fb411",
"assets/assets/data/polls/%25EB%258B%25B9%25EC%25A7%2584%25EC%258B%259C.json": "44721227dd0d6409886b754985a04cf3",
"assets/assets/data/polls/%25EC%2598%2581%25EC%259B%2594%25EA%25B5%25B0.json": "937deca4a384aff50ce411c250dd8b13",
"assets/assets/data/polls/%25EC%2598%2588%25EC%2582%25B0%25EA%25B5%25B0.json": "97509206a0c235bc011c887c10e72fa9",
"assets/assets/data/polls/%25EC%25B0%25BD%25EC%259B%2590%25EC%258B%259C%25EC%25A7%2584%25ED%2595%25B4%25EA%25B5%25AC.json": "d3fe7b286ece3e00e3165c19569f979f",
"assets/assets/data/polls/%25EA%25B2%25BD%25EA%25B8%25B0%25EB%258F%2584.json": "4425e1ce0dd9e2801e4f4d45e86b111a",
"assets/assets/data/polls/%25EA%25B3%25A0%25EC%2596%2591%25EC%258B%259C%25EB%258D%2595%25EC%2596%2591%25EA%25B5%25AC.json": "54a519527c3548b04e53b8069946f7f3",
"assets/assets/data/polls/%25EB%258F%2599%25ED%2595%25B4%25EC%258B%259C.json": "4bf252fbf4a296105190b08a8cae3df4",
"assets/assets/data/polls/%25EC%25B0%25BD%25EC%259B%2590%25EC%258B%259C%25EC%259D%2598%25EC%25B0%25BD%25EA%25B5%25AC.json": "edb6b2b2d27e7050f7e1d81b12b3578e",
"assets/assets/data/polls/%25ED%2583%259C%25EB%25B0%25B1%25EC%258B%259C.json": "db380318c6649663e7e8b1e3867fd5b5",
"assets/assets/data/polls/%25EC%25B6%25A9%25EC%25B2%25AD%25EB%2582%25A8%25EB%258F%2584.json": "a0f66189c75602dda32aae9614bf291f",
"assets/assets/data/polls/%25EB%2582%2598%25EC%25A3%25BC%25EC%258B%259C.json": "b911d28b7e0f97d783e543bb6108d523",
"assets/assets/data/polls/%25EA%25B4%25B4%25EC%2582%25B0%25EA%25B5%25B0.json": "92aca30a9ecde35e6fbc43084d1d561b",
"assets/assets/data/polls/%25EC%25B6%2598%25EC%25B2%259C%25EC%258B%259C.json": "835633b9c7c2fc7b9c21e16139d453c3",
"assets/assets/data/polls/%25EC%2595%2584%25EC%2582%25B0%25EC%258B%259C.json": "0de2b9b1084864b259218afccb8aeaeb",
"assets/assets/data/polls/%25EB%25AC%25B8%25EA%25B2%25BD%25EC%258B%259C.json": "5ef095704db4316d1be64311db6af9a2",
"assets/assets/data/polls/%25EC%259D%2598%25EC%25A0%2595%25EB%25B6%2580%25EC%258B%259C.json": "e68aff0f244e7c0015413bede6d801b2",
"assets/assets/data/polls/%25EC%2595%2588%25EC%2584%25B1%25EC%258B%259C.json": "ed2fcddb9cdcc6f71b702f38b8b6b3b8",
"assets/assets/data/polls/%25EB%25B4%2589%25ED%2599%2594%25EA%25B5%25B0.json": "67670d3d944fcb931dcc7bc121ba1ac0",
"assets/assets/data/polls/%25EB%25B0%2580%25EC%2596%2591%25EC%258B%259C.json": "4d521a4eac8bb69c7dba4fcc46a79f9b",
"assets/assets/data/polls/%25ED%2599%2594%25EC%2584%25B1%25EC%258B%259C%25ED%259A%25A8%25ED%2596%2589%25EA%25B5%25AC.json": "8617c407dc95561537da1d3eb91c67f5",
"assets/assets/data/polls/%25EC%2598%2581%25EB%258F%2599%25EA%25B5%25B0.json": "096fed068ef2d3ace6db738f7c5bc63b",
"assets/assets/data/polls/%25EC%2596%2591%25EA%25B5%25AC%25EA%25B5%25B0.json": "19899f74ba748c4f1adbe19b011d2f95",
"assets/assets/data/polls/%25EB%258C%2580%25EA%25B5%25AC%25EA%25B4%2591%25EC%2597%25AD%25EC%258B%259C.json": "93d8fbb7b6f13b3ab17acec9eae1fa0a",
"assets/assets/data/polls/%25EB%25B3%25B4%25EC%259D%2580%25EA%25B5%25B0.json": "d9c5cb76af8efc299b9ca1af67ce0c80",
"assets/assets/data/polls/%25EA%25B4%2591%25EC%25A3%25BC%25EC%258B%259C.json": "c1485abf0a2663a6289412785741949f",
"assets/assets/data/polls/%25EC%25B6%25A9%25EC%25A3%25BC%25EC%258B%259C.json": "fb13fdd406da467a1a033ed888a76102",
"assets/assets/data/polls/%25EA%25B3%25BC%25EC%25B2%259C%25EC%258B%259C.json": "e15cf7c645aeebf058be7a84c8825c29",
"assets/assets/data/polls/%25EC%2598%2581%25EB%258D%2595%25EA%25B5%25B0.json": "2d955e1a00bed350b23a83f208eaf10f",
"assets/assets/data/polls/%25EB%258B%25A8%25EC%2596%2591%25EA%25B5%25B0.json": "3bc35c26a820185ca23d6ee694365f77",
"assets/assets/data/polls/%25EC%25B2%259C%25EC%2595%2588%25EC%258B%259C%25EB%258F%2599%25EB%2582%25A8%25EA%25B5%25AC.json": "33e4e975d4f96a13ffbb6d49c0bcfb4d",
"assets/assets/data/polls/%25EB%258B%25AC%25EC%2584%25B1%25EA%25B5%25B0.json": "f75e4ec3b9070013c667897fd93899ba",
"assets/assets/data/polls/%25EC%2598%2581%25EC%2595%2594%25EA%25B5%25B0.json": "490220a1f2cdd3a8dd058f22fa9c49be",
"assets/assets/data/polls/%25EC%2582%25B0%25EC%25B2%25AD%25EA%25B5%25B0.json": "94c62bf762d2823689bf5e7198539772",
"assets/assets/data/polls/%25EC%25B2%259C%25EC%2595%2588%25EC%258B%259C%25EC%2584%259C%25EB%25B6%2581%25EA%25B5%25AC.json": "84744d3e99466816a9fce65e8ff70af2",
"assets/assets/data/polls/%25EB%25AA%25A9%25ED%258F%25AC%25EC%258B%259C.json": "c65a7ae54e4a8c81dbfd2f241008d1a6",
"assets/assets/data/polls/%25ED%2599%2594%25EC%2588%259C%25EA%25B5%25B0.json": "ea65e373a2651e7ca55cdab81bc7397b",
"assets/assets/data/polls/%25ED%258F%2589%25ED%2583%259D%25EC%258B%259C.json": "f5976e417657be9183cac76b26bf0b7b",
"assets/assets/data/polls/%25EB%25AC%25B4%25EC%2595%2588%25EA%25B5%25B0.json": "6b20cf7768df59c6ea7370a700ae175a",
"assets/assets/data/polls/%25EC%25B2%25AD%25EC%25A3%25BC%25EC%258B%259C%25EC%25B2%25AD%25EC%259B%2590%25EA%25B5%25AC.json": "8de880495202b9f3b5e21cf2a871cce3",
"assets/assets/data/polls/%25EC%25A7%2584%25EB%258F%2584%25EA%25B5%25B0.json": "04c49e6c8ba6191b294dfb042663ff6c",
"assets/assets/data/polls/%25EC%25B2%25AD%25EC%2596%2591%25EA%25B5%25B0.json": "d3e4878f4c733f273a209ace9541874d",
"assets/assets/data/polls/%25EA%25B1%25B0%25EC%25B0%25BD%25EA%25B5%25B0.json": "30d317148513bdbbf5b0c499b83d89ba",
"assets/assets/data/polls/%25EC%2598%2581%25EC%2596%2591%25EA%25B5%25B0.json": "80c09d23fe079a815fcea06e7b44aeef",
"assets/assets/data/polls/%25EA%25B9%2580%25EC%25B2%259C%25EC%258B%259C.json": "224b412fd6b7df388e3d7d700930fee1",
"assets/assets/data/polls/%25EA%25B4%2591%25EC%2596%2591%25EC%258B%259C.json": "e6592b7640a46ad5134269a4b2d5b7b4",
"assets/assets/data/polls/%25EC%259E%2584%25EC%258B%25A4%25EA%25B5%25B0.json": "ca2d9a790343d9d874b01319bf54bd5c",
"assets/assets/data/polls/%25EC%25A0%2584%25EB%259D%25BC%25EB%2582%25A8%25EB%258F%2584.json": "a731300b51f6690eab7f61abd6906a67",
"assets/assets/data/polls/%25EB%25B6%2580%25EC%25B2%259C%25EC%258B%259C%25EC%2586%258C%25EC%2582%25AC%25EA%25B5%25AC.json": "f6a6de5939f898fa136e26e959d4f0ff",
"assets/assets/data/polls/%25EC%259D%25B4%25EC%25B2%259C%25EC%258B%259C.json": "368af42e26dbda2f4e9cb7339547f69e",
"assets/assets/data/polls/%25EC%25A7%2584%25EC%25A3%25BC%25EC%258B%259C.json": "5433fa72f696234df6df490cf8a04f9d",
"assets/assets/data/polls/%25EB%25B6%2580%25EC%25B2%259C%25EC%258B%259C%25EC%259B%2590%25EB%25AF%25B8%25EA%25B5%25AC.json": "6b956ddf415dff719d0111b618ee04dd",
"assets/assets/data/polls/%25EA%25B9%2580%25ED%2595%25B4%25EC%258B%259C.json": "da9836f8d5b9541d70888392f4e43d0e",
"assets/assets/data/polls/%25ED%2586%25B5%25EC%2598%2581%25EC%258B%259C.json": "6c950b4e67d3952e7c743798d5570b97",
"assets/assets/data/polls/%25ED%2595%2598%25EB%2582%25A8%25EC%258B%259C.json": "3f2f0383ea133c6e1bf1a79d962e5347",
"assets/assets/data/polls/%25EA%25B3%2584%25EB%25A3%25A1%25EC%258B%259C.json": "7288348eb204b5a867ba001762e2dd2b",
"assets/assets/data/polls/%25EC%2584%25B8%25EC%25A2%2585%25ED%258A%25B9%25EB%25B3%2584%25EC%259E%2590%25EC%25B9%2598%25EC%258B%259C.json": "4ca6a6b0e2cf966ba5216eb450ba1a39",
"assets/assets/data/polls/%25EA%25B3%25A1%25EC%2584%25B1%25EA%25B5%25B0.json": "ce1ddfd1fa56d9cab6d8b59479156403",
"assets/assets/data/polls/%25EC%25B2%25A0%25EC%259B%2590%25EA%25B5%25B0.json": "1c8fcf17d5e3e8899f3692c860795b80",
"assets/assets/data/polls/%25EC%2595%2588%25EC%2582%25B0%25EC%258B%259C%25EB%258B%25A8%25EC%259B%2590%25EA%25B5%25AC.json": "ada6ae11e0ca84d2a9651c68775ef5d9",
"assets/assets/data/polls/%25EC%25B0%25BD%25EC%259B%2590%25EC%258B%259C%25EC%2584%25B1%25EC%2582%25B0%25EA%25B5%25AC.json": "6d512bf5822895ae8b5c750ae4ab1646",
"assets/assets/data/polls/%25ED%2599%258D%25EC%2584%25B1%25EA%25B5%25B0.json": "89214a61b40e568b79c6889d0d8ff856",
"assets/assets/data/polls/%25EC%2596%2591%25EC%2582%25B0%25EC%258B%259C.json": "534b37dca10bfa8684c09d6a001f58c1",
"assets/assets/data/polls/%25EC%2597%25AC%25EC%2588%2598%25EC%258B%259C.json": "54c43db6d37cb6e17e45f4ff5acf584c",
"assets/assets/data/polls/%25EC%25A0%259C%25EC%25A3%25BC%25ED%258A%25B9%25EB%25B3%2584%25EC%259E%2590%25EC%25B9%2598%25EB%258F%2584.json": "4c004abb944b64794a8177a1b65ee534",
"assets/assets/data/polls/%25EA%25B5%25B0%25EC%2582%25B0%25EC%258B%259C%25EA%25B9%2580%25EC%25A0%259C%25EC%258B%259C%25EB%25B6%2580%25EC%2595%2588%25EA%25B5%25B0%25EC%259D%2584.json": "44cf1f886d588f2212aad54a45b6f8b5",
"assets/assets/data/polls/%25EC%2596%2591%25EC%25A3%25BC%25EC%258B%259C.json": "2095215aad59b6a302e1f2bc544b9311",
"assets/assets/data/polls/%25EA%25B4%2591%25EB%25AA%2585%25EC%258B%259C.json": "33627ea5a9eb282a67b2488c1286ccfe",
"assets/assets/data/polls/%25EC%2588%259C%25EC%25B2%259C%25EC%258B%259C.json": "d03fab5e82ea66ca0a45b8aef3b702fb",
"assets/assets/data/polls/%25ED%2595%25A8%25EC%2595%2588%25EA%25B5%25B0.json": "2d04a0c31b7a7b51487cc23b68524fca",
"assets/assets/data/polls/%25EC%25B0%25BD%25EC%259B%2590%25EC%258B%259C%25EB%25A7%2588%25EC%2582%25B0%25ED%2595%25A9%25ED%258F%25AC%25EA%25B5%25AC.json": "7be87eefcdbabe5b0c9f8410ba7eef44",
"assets/assets/data/polls/%25EA%25B2%25BD%25EC%2583%2581%25EB%2582%25A8%25EB%258F%2584.json": "1b056455cdb0c7842997dae8daa95252",
"assets/assets/data/polls/%25ED%258F%25AC%25ED%2595%25AD%25EC%258B%259C%25EB%2582%25A8%25EA%25B5%25AC.json": "44ba0b8cc9ef3a7fb20386268a9e58ba",
"assets/assets/data/polls/%25EC%2595%2588%25EC%2582%25B0%25EC%258B%259C%25EA%25B0%2591.json": "82a8f33f628e51bab736cf0ce50ce31d",
"assets/assets/data/polls/%25ED%2583%259C%25EC%2595%2588%25EA%25B5%25B0.json": "80c624c7ecd6f150797935091be9062b",
"assets/assets/data/polls/%25EC%25A0%2584%25EC%25A3%25BC%25EC%258B%259C%25EC%2599%2584%25EC%2582%25B0%25EA%25B5%25AC.json": "53c95729578707d30606943afb475d44",
"assets/assets/data/polls/%25EA%25B9%2580%25ED%258F%25AC%25EC%258B%259C.json": "f6d651890a71ffda2f679a0b7ef1358b",
"assets/assets/data/polls/%25EC%2597%25AC%25EC%25A3%25BC%25EC%258B%259C.json": "58c5da82f63b91a795d2ddcc9bf98cf5",
"assets/assets/data/polls/%25EA%25B2%25BD%25EC%25A3%25BC%25EC%258B%259C.json": "207d768556fa3345a94aec3f9319df78",
"assets/assets/data/polls/%25EC%259D%25B5%25EC%2582%25B0%25EC%258B%259C.json": "a7d9390c8b33af7083d6b4b76f40f8a0",
"assets/assets/data/polls/%25ED%2599%2594%25EC%2584%25B1%25EC%258B%259C%25EB%258F%2599%25ED%2583%2584%25EA%25B5%25AC.json": "9145eaa1042434bd4639f3d2db246781",
"assets/assets/data/polls/%25EB%25B6%2580%25EC%2582%25B0%25EA%25B4%2591%25EC%2597%25AD%25EC%258B%259C.json": "3992d7920deb22efd8079de022ae1791",
"assets/assets/data/polls/%25EC%25B2%25AD%25EB%258F%2584%25EA%25B5%25B0.json": "fe4e5cbb7056132146fd62960bc78377",
"assets/assets/data/polls/%25EC%258B%25A0%25EC%2595%2588%25EA%25B5%25B0.json": "c254e64f4490d4bcb2b5ee57737e1a46",
"assets/assets/data/polls/%25EA%25B5%25B0%25EC%2582%25B0%25EC%258B%259C%25EA%25B9%2580%25EC%25A0%259C%25EC%258B%259C%25EB%25B6%2580%25EC%2595%2588%25EA%25B5%25B0%25EA%25B0%2591.json": "8df84a93a8e5a0efcd7d1f59a507088f",
"assets/assets/data/polls/%25EB%258B%25B4%25EC%2596%2591%25EA%25B5%25B0.json": "2dcf9e4f5ec2c5a3de76e75cc4e7d7d0",
"assets/assets/data/polls/%25EC%25B6%25A9%25EC%25B2%25AD%25EB%25B6%2581%25EB%258F%2584.json": "724aea63d033fa5e13f279befe16e577",
"assets/assets/data/polls/%25EA%25B4%2591%25EC%25A7%2584%25EA%25B5%25AC.json": "71a46f32dc88d3fdc4317952a6e69df5",
"assets/assets/data/polls/%25EC%259A%25B8%25EC%25A7%2584%25EA%25B5%25B0.json": "65a407f636e319a50bb1767ce50ec12e",
"assets/assets/data/polls/%25EC%2598%2581%25EC%25B2%259C%25EC%258B%259C.json": "b28dd00895659d063e560964db966292",
"assets/assets/data/polls/%25EB%258F%2599%25EB%2591%2590%25EC%25B2%259C%25EC%258B%259C.json": "10d3ee5c60a042aaf4aeedd1b178d288",
"assets/assets/data/polls/%25EC%2595%2588%25EB%258F%2599%25EC%258B%259C.json": "af68aea07c0ce02d764a2fccc002c1d5",
"assets/assets/data/polls/%25EC%2584%259C%25EC%259A%25B8%25ED%258A%25B9%25EB%25B3%2584%25EC%258B%259C.json": "b1f94134b690fec8e412429b40f7a2bf",
"assets/assets/data/polls/%25EC%259D%25B8%25EC%25A0%259C%25EA%25B5%25B0.json": "b7157d1c356fa23a9f62381acc03c423",
"assets/assets/data/polls/%25EC%25A0%2595%25EC%2584%25A0%25EA%25B5%25B0.json": "e76415242e3992a826848493443c5935",
"assets/assets/data/polls/%25EB%2582%25A8%25EA%25B5%25AC%25EA%25B0%2591.json": "7b7f52eca738f72dcca4bfb953ee0d10",
"assets/assets/data/polls/%25EC%259A%25A9%25EC%259D%25B8%25EC%258B%259C%25EA%25B8%25B0%25ED%259D%25A5%25EA%25B5%25AC.json": "1a734d9638ba7f72919f8bd57293e95f",
"assets/assets/data/polls/%25EA%25B3%25B5%25EC%25A3%25BC%25EC%258B%259C.json": "60eef4a20fc66ffc199ad79aad3c52e4",
"assets/assets/data/polls/%25ED%2599%2594%25EC%2584%25B1%25EC%258B%259C%25EB%25B3%2591%25EC%25A0%2590%25EA%25B5%25AC.json": "4bce37d7ed012ab6fea4cf4b71c5701b",
"assets/assets/data/polls/%25EB%258C%2580%25EC%25A0%2584%25EA%25B4%2591%25EC%2597%25AD%25EC%258B%259C.json": "b7fded4ecf46129c63cfe18a3e04374b",
"assets/assets/data/polls/%25EC%2584%259C%25EC%2582%25B0%25EC%258B%259C.json": "680f5b51f5dc5a90fbd160f45aa14383",
"assets/assets/data/polls/%25EC%259D%25B8%25EC%25B2%259C%25EA%25B4%2591%25EC%2597%25AD%25EC%258B%259C.json": "7dfd34b336a328dab488c1084a785590",
"assets/assets/data/polls/%25EC%2599%2584%25EC%25A3%25BC%25EA%25B5%25B0.json": "75e9d7265585b2daa59f4f08ff35123b",
"assets/assets/data/polls/%25EC%2595%2588%25EC%2596%2591%25EC%258B%259C%25EB%25A7%258C%25EC%2595%2588%25EA%25B5%25AC.json": "4748006b6944a867251c21a9758a38c1",
"assets/assets/data/polls/%25EC%2597%25B0%25EC%25B2%259C%25EA%25B5%25B0.json": "a687c2d9c4bc2f519586ab6826ab9b91",
"assets/assets/data/polls/%25EB%25B6%2580%25EC%2597%25AC%25EA%25B5%25B0.json": "c396f24dbe3c08192496ac0559a734c7",
"assets/assets/data/polls/%25EC%25A6%259D%25ED%258F%2589%25EA%25B5%25B0.json": "4d495e0e49b00b5dfb4f2244f105c912",
"assets/assets/data/polls/%25ED%2599%2594%25EC%25B2%259C%25EA%25B5%25B0.json": "4e6a484fd7b5bc452178761a53d0b904",
"assets/assets/data/polls/%25EC%25A0%259C%25EC%25B2%259C%25EC%258B%259C.json": "a285cf22e4af5f417a4cc23b5c435862",
"assets/assets/data/polls/%25EC%259A%25B8%25EC%2582%25B0%25EA%25B4%2591%25EC%2597%25AD%25EC%258B%259C.json": "37fa162182b5b6364c0bb6fbb3f3ff15",
"assets/assets/data/polls/%25EC%259A%25B8%25EB%25A6%2589%25EA%25B5%25B0.json": "3cc626e3d5f646e687658562eb91abdf",
"assets/assets/data/polls/%25EB%25B6%2580%25EC%2595%2588%25EA%25B5%25B0.json": "20837b2f7cfdda98b8b70e2e2c466e87",
"assets/assets/data/polls/%25EA%25B5%25B0%25EC%2582%25B0%25EC%258B%259C.json": "8756f1f67be35cf838960e6553e53f80",
"assets/assets/data/polls/%25EC%2582%25AC%25EC%25B2%259C%25EC%258B%259C.json": "5c20242d5de581472574be36b0d1b59e",
"assets/assets/data/polls/%25EB%25B6%2580%25EC%25B2%259C%25EC%258B%259C%25EC%2598%25A4%25EC%25A0%2595%25EA%25B5%25AC.json": "f65e76e55a89ba9dafe6e6f853f8de23",
"assets/assets/data/polls/%25ED%2595%2598%25EB%258F%2599%25EA%25B5%25B0.json": "0d7d45a249e76ba5e5616cf7876233dd",
"assets/assets/data/polls/%25EC%2596%2591%25EC%2596%2591%25EA%25B5%25B0.json": "bce0ede1e93aaae84790e2ac565edaab",
"assets/assets/data/polls/%25EC%2598%2588%25EC%25B2%259C%25EA%25B5%25B0.json": "958b4b44abe575f0036fe1affc55fc7f",
"assets/assets/data/polls/%25ED%2595%2598%25EB%2582%25A8%25EC%258B%259C%25EA%25B0%2591.json": "20e4d07b7acb063c0e0be423cef0c529",
"assets/assets/data/polls/%25EA%25B3%2584%25EC%2596%2591%25EA%25B5%25AC%25EC%259D%2584.json": "8beebbc3d4a34d4944ee36b778f360df",
"assets/assets/data/polls/%25EB%25B3%25B4%25EB%25A0%25B9%25EC%258B%259C.json": "5901d15eb83372e58ed2e19fe0ff1673",
"assets/assets/data/polls/%25EA%25B3%25A0%25EC%2596%2591%25EC%258B%259C%25EC%259D%25BC%25EC%2582%25B0%25EC%2584%259C%25EA%25B5%25AC.json": "ea5e0a063706fbf72b5a1b89a771d5e6",
"assets/assets/data/polls/%25EB%2582%25A8%25EC%259B%2590%25EC%258B%259C.json": "4254ff38f60ede759c0e9100cde2a3e9",
"assets/assets/data/polls/%25EA%25B1%25B0%25EC%25A0%259C%25EC%258B%259C.json": "65008c223ebc03c00006e970814f1905",
"assets/assets/data/polls/%25EA%25B3%25A0%25EB%25A0%25B9%25EA%25B5%25B0.json": "30d08fa4bed457a088f4dea02dce58f2",
"assets/assets/data/polls/%25EC%2595%2588%25EC%2596%2591%25EC%258B%259C%25EB%258F%2599%25EC%2595%2588%25EA%25B5%25AC.json": "9c0352a1518a9aaea22ee080608acd88",
"assets/assets/data/polls/%25EA%25B5%25AC%25EB%25A6%25AC%25EC%258B%259C.json": "f694ce55f754c1ea032742f07eeed184",
"assets/assets/data/polls/%25EC%2595%2588%25EC%2582%25B0%25EC%258B%259C%25EC%2583%2581%25EB%25A1%259D%25EA%25B5%25AC.json": "812381eac44a7074a187a68ccb015c2b",
"assets/assets/data/polls/%25EC%2584%259C%25EA%25B7%2580%25ED%258F%25AC%25EC%258B%259C.json": "a40a8961c79f62e51d9c838249e76583",
"assets/assets/data/polls/%25EC%25B0%25BD%25EC%259B%2590%25EC%258B%259C%25EB%25A7%2588%25EC%2582%25B0%25ED%259A%258C%25EC%259B%2590%25EA%25B5%25AC.json": "5c1d3d4c467356f530635c6c90181f82",
"assets/assets/data/polls/%25EC%2598%25A4%25EC%2582%25B0%25EC%258B%259C.json": "c6f26dda6cdad4004141768fba5254c8",
"assets/assets/data/polls/%25EC%259D%258C%25EC%2584%25B1%25EA%25B5%25B0.json": "b7783d0e0f134360595d16cb4e8edee9",
"assets/assets/data/polls/%25EA%25B0%2595%25EC%259B%2590%25ED%258A%25B9%25EB%25B3%2584%25EC%259E%2590%25EC%25B9%2598%25EB%258F%2584.json": "37484fd491b19bb0100acaa881b5e4ad",
"assets/assets/data/polls/%25EC%25A7%2584%25EC%25B2%259C%25EA%25B5%25B0.json": "23f2666d18f199f3ac89c2746e449fc3",
"assets/assets/data/polls/%25EA%25B5%25B0%25ED%258F%25AC%25EC%258B%259C.json": "a402dac2b22dadd50e14e943376717d9",
"assets/assets/data/polls/%25EA%25B5%25AC%25EB%25A1%2580%25EA%25B5%25B0.json": "f9ebf10ee1e6ebed016694962cc85d3a",
"assets/assets/data/polls/%25EA%25B4%2591%25EC%25A3%25BC%25EA%25B4%2591%25EC%2597%25AD%25EC%258B%259C.json": "fdc39bb68265d8f7785ec9d28f743eab",
"assets/assets/data/polls/%25EB%2582%25A8%25ED%2595%25B4%25EA%25B5%25B0.json": "69c667ff82519e847ebcec0a1e5e04e6",
"assets/assets/data/polls/%25EC%259A%25A9%25EC%259D%25B8%25EC%258B%259C%25EC%2588%2598%25EC%25A7%2580%25EA%25B5%25AC.json": "d723d8386c9c94da62d792fb589c63e2",
"assets/assets/data/polls/%25EA%25B3%25A0%25EC%2584%25B1%25EA%25B5%25B0.json": "88dce08cd4fd6304125bbd3760defd6f",
"assets/assets/data/polls/%25EB%25B6%2581%25EA%25B5%25AC%25EA%25B0%2591.json": "6ba7c06b1b9bd8d21e724151c8df5c7a",
"assets/assets/data/polls/%25EA%25B3%25A0%25EC%2596%2591%25EC%258B%259C%25EC%259D%25BC%25EC%2582%25B0%25EB%258F%2599%25EA%25B5%25AC.json": "50c02132798fa4b7a25f886b1a32854b",
"assets/assets/data/polls/%25ED%258C%258C%25EC%25A3%25BC%25EC%258B%259C.json": "6bc19d8dc336813ebc1bce351bd53d18",
"assets/assets/data/polls/%25EC%2583%2581%25EC%25A3%25BC%25EC%258B%259C.json": "d4a39d810892b5064f571154ead92f91",
"assets/assets/data/polls/%25EC%259E%25A5%25ED%259D%25A5%25EA%25B5%25B0.json": "1b6604f174a03937b96863029eef77f6",
"assets/assets/data/polls/%25EB%25AC%25B4%25EC%25A3%25BC%25EA%25B5%25B0.json": "24452add8aa3c7a755aae2ced236ecf4",
"assets/assets/data/polls/%25EC%2599%2584%25EB%258F%2584%25EA%25B5%25B0.json": "2d8dab118c85c74431dd599e560429e8",
"assets/assets/data/polls/%25EC%25B2%25AD%25EC%25A3%25BC%25EC%258B%259C%25EC%2584%259C%25EC%259B%2590%25EA%25B5%25AC.json": "8442457e6db1dc70d95bd637ff31887d",
"assets/assets/data/election_candidates.json": "312d382c4e87b9cfe7370fe5578e86c9",
"assets/assets/data/candidates_2026.json": "f28b9ef99795e0d054ab5ac5ef47bd09"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
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
