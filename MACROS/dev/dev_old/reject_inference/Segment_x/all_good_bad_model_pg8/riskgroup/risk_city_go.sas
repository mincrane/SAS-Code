if BUSINESSCITY in (
'ABINGDON ',
'ALBUQUERQUE ',
'ANNAPOLIS ',
'APOPKA ',
'ASBURY PARK ',
'BALDWIN PARK ',
'BARRE ',
'BARTLETT ',
'BEAR ',
'BELTSVILLE ',
'BILLINGS ',
'BIRMINGHAM ',
'BOLINGBROOK ',
'BOONE ',
'BRANSON ',
'BRENHAM ',
'BROCKTON ',
'CANYON COUNTRY ',
'CAVE CREEK ',
'CEDAR PARK ',
'CENTENNIAL ',
'CHAMBLEE ',
'CHANDLER ',
'CHANTILLY ',
'CIRCLEVILLE ',
'CLIFFSIDE PARK ',
'COCONUT CREEK ',
'CONCORD ',
'COOPER CITY ',
'COTTON ',
'CYPRESS ',
'DALLAS ',
'DANVILLE ',
'DEERFIELD BEACH ',
'DELRAN ',
'DOWNINGTOWN ',
'DRAPER ',
'DUBLIN ',
'DUNEDIN ',
'EAST HAMPTON ',
'EDISON ',
'EDWARDSVILLE ',
'ELGIN ',
'ELIZABETHTOWN ',
'EPHRATA ',
'ERLANGER ',
'EUREKA ',
'EVANSTON ',
'FALL RIVER ',
'FALLBROOK ',
'FAR ROCKAWAY ',
'FITCHBURG ',
'FLORENCE ',
'FOND DU LAC ',
'FONTANA ',
'FOREST PARK ',
'FORT WALTON BEACH ',
'FRAMINGHAM ',
'FRANKFORT ',
'FREDERICKSBURG ',
'GLENWOOD SPRINGS ',
'GOODYEAR ',
'GOSHEN ',
'GREENBRAE ',
'HARLINGEN ',
'HARWOOD HEIGHTS ',
'HAWTHORNE ',
'HERNDON ',
'HIGH POINT ',
'HIGHLANDS RANCH ',
'HOLLADAY ',
'HOLLYWOOD ',
'HOLMDEL ',
'HOMEWOOD ',
'HOMOSASSA ',
'ISSAQUAH ',
'JACKSONVILLE BEACH ',
'JAMESTOWN ',
'JOHNSTOWN ',
'JUPITER ',
'KENNEWICK ',
'KEW GARDENS ',
'KINGWOOD ',
'LAGUNA HILLS ',
'LAKE HAVASU CITY ',
'LAKEVILLE ',
'LAND O LAKES ',
'LEHI ',
'LIBERTYVILLE ',
'LIVONIA ',
'LOCKPORT ',
'LOGANVILLE ',
'LOMA LINDA ',
'LONGWOOD ',
'LUBBOCK ',
'MABLETON ',
'MAPLEWOOD ',
'MILPITAS ',
'MONROE ',
'MONSEY ',
'MONTAUK ',
'MOORESVILLE ',
'MOUNT VERNON ',
'MURRIETA ',
'MYRTLE BEACH ',
'N LAUDERDALE ',
'NAMPA ',
'NAPERVILLE ',
'NAVARRE ',
'NEW BRAUNFELS ',
'NEW HOPE ',
'NEWARK ',
'NEWNAN ',
'NORFOLK ',
'NORTH ANDOVER ',
'NORTH HOLLYWOOD ',
'NORTH RICHLAND HILLS ',
'NORTHFIELD ',
'O FALLON ',
'OAK PARK ',
'OJAI ',
'OLDSMAR ',
'OWASSO ',
'OXON HILL ',
'PALATINE ',
'PALM SPRINGS ',
'PARIS ',
'PARK CITY ',
'PARMA ',
'PARSIPPANY ',
'PAWLEYS ISLAND ',
'PLANTATION ',
'PLEASANTVILLE ',
'POMONA ',
'PORT SAINT LUCIE ',
'POUGHKEEPSIE ',
'POWAY ',
'RAHWAY ',
'RALEIGH ',
'RCHO STA MARG ',
'RED BANK ',
'RICHFIELD ',
'RIDGEFIELD ',
'RIO RANCHO ',
'ROCK HILL ',
'ROCK ISLAND ',
'ROCKFORD ',
'ROCKVILLE CENTRE ',
'SAN PEDRO ',
'SANTA BARBARA ',
'SANTA CLARA ',
'SCRANTON ',
'SEBASTIAN ',
'SHARON ',
'SISTERS ',
'SOUTH BURLINGTON ',
'SPANISH FORK ',
'SPOKANE ',
'STATE COLLEGE ',
'STILLWATER ',
'STRONGSVILLE ',
'SUN CITY ',
'SUN PRAIRIE ',
'SUNRISE ',
'TEMPLE HILLS ',
'TEXARKANA ',
'TIGARD ',
'TOBYHANNA ',
'TOLLESON ',
'TROY ',
'TRUCKEE ',
'TULSA ',
'TUSCALOOSA ',
'UPPR MARLBORO ',
'VALLEY STREAM ',
'VALLEY VILLAGE ',
'VENICE ',
'VERONA ',
'WAKE FOREST ',
'WAKEFIELD ',
'WARNER ROBINS ',
'WARRENTON ',
'WATERFORD ',
'WAUSAU ',
'WAYZATA ',
'WEST BABYLON ',
'WEST DES MOINES ',
'WEST HILLS ',
'WEST JORDAN ',
'WHITESTONE ',
'WILLIAMSPORT ',
'WILLIAMSTON ',
'WILSONVILLE ',
'WINDERMERE ',
'WOBURN ',
'WORCESTER ',
'WORTHINGTON ',
'YOUNGSTOWN ',
'ZEPHYRHILLS ',
'_last_') then risk_citygo = 1;
else if risk_citygb=0 and risk_cityg1=0 and risk_cityg2=0 and risk_cityg3=0 and risk_cityg4=0 then risk_citygo=1;
else risk_citygo = 0;