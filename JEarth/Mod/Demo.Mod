MODULE JEarthDemo;
(** Пример подсистемы JEarth (ADR-266): карта Земли в окне BBCB.

    `Run` открывает карту в окне документа: перетаскивание мышью —
    прокрутка, колесо — увеличение/уменьшение. `World` — вся планета,
    `Check` — headless-рендер в PNG (используется смоуком).

    Требуется OpenGL (JOGL из `JEarth/Lib`). Если GL недоступен, вид
    покажет заглушку, а причина будет в `JEarth.lastError`. *)

	IMPORT JEarth, Views, StdLog;

	TYPE
		Capital = RECORD
			lat, lon: REAL
		END;

	VAR
		capitals: ARRAY 320 OF Capital;
		nCapitals: INTEGER;

	PROCEDURE Add (lat, lon: REAL);
	BEGIN
		IF nCapitals < LEN(capitals) THEN
			capitals[nCapitals].lat := lat;
			capitals[nCapitals].lon := lon;
			INC(nCapitals)
		END
	END Add;

	(** Таблица столиц (204 записи; источник — Wikidata, P36 «столица»). *)
	PROCEDURE InitCapitals;
	BEGIN
		nCapitals := 0;
		Add(24.4511, 54.3969);	(* Abu Dhabi *)
		Add(9.0556, 7.4914);	(* Abuja *)
		Add(5.5560, -0.1969);	(* Accra *)
		Add(9.0358, 38.7525);	(* Addis Ababa *)
		Add(12.8000, 45.0333);	(* Aden *)
		Add(36.7764, 3.0586);	(* Algiers *)
		Add(31.9310, 35.9261);	(* Amman *)
		Add(52.3667, 4.8833);	(* Amsterdam *)
		Add(42.5072, 1.5222);	(* Andorra la Vella *)
		Add(39.9358, 32.8387);	(* Ankara *)
		Add(-18.9100, 47.5250);	(* Antananarivo *)
		Add(-13.8333, -171.8333);	(* Apia *)
		Add(37.9500, 58.3833);	(* Ashgabat *)
		Add(15.3333, 38.9167);	(* Asmara *)
		Add(51.1333, 71.4333);	(* Astana *)
		Add(-25.2800, -57.6344);	(* Asunción *)
		Add(37.9842, 23.7281);	(* Athens *)
		Add(33.3153, 44.3661);	(* Baghdad *)
		Add(40.3667, 49.8352);	(* Baku *)
		Add(12.6458, -7.9922);	(* Bamako *)
		Add(4.9167, 114.9167);	(* Bandar Seri Begawan *)
		Add(13.7500, 100.5167);	(* Bangkok *)
		Add(4.3732, 18.5628);	(* Bangui *)
		Add(13.4531, -16.5775);	(* Banjul *)
		Add(17.2983, -62.7342);	(* Basseterre *)
		Add(39.9040, 116.4075);	(* Beijing *)
		Add(33.8869, 35.5131);	(* Beirut *)
		Add(44.8178, 20.4569);	(* Belgrade *)
		Add(17.2500, -88.7675);	(* Belmopan *)
		Add(52.5167, 13.3833);	(* Berlin *)
		Add(46.9480, 7.4474);	(* Bern *)
		Add(42.8667, 74.5667);	(* Bishkek *)
		Add(11.8600, -15.5833);	(* Bissau *)
		Add(-29.1000, 26.2167);	(* Bloemfontein *)
		Add(4.6097, -74.0817);	(* Bogotá *)
		Add(-15.7939, -47.8828);	(* Brasília *)
		Add(48.1517, 17.1093);	(* Bratislava *)
		Add(-4.2694, 15.2711);	(* Brazzaville *)
		Add(13.0975, -59.6167);	(* Bridgetown *)
		Add(50.8467, 4.3517);	(* Brussels *)
		Add(44.4134, 26.0978);	(* Bucharest *)
		Add(47.4983, 19.0408);	(* Budapest *)
		Add(-34.5997, -58.3819);	(* Buenos Aires *)
		Add(30.0444, 31.2358);	(* Cairo *)
		Add(-35.2931, 149.1269);	(* Canberra *)
		Add(-33.9253, 18.4239);	(* Cape Town *)
		Add(10.5061, -66.9144);	(* Caracas *)
		Add(14.0108, -60.9894);	(* Castries *)
		Add(47.0228, 28.8353);	(* Chișinău *)
		Add(1.5917, 10.8222);	(* Ciudad de la Paz *)
		Add(6.9267, 79.8606);	(* Colombo *)
		Add(9.5092, -13.7122);	(* Conakry *)
		Add(55.6761, 12.5689);	(* Copenhagen *)
		Add(14.6726, -17.4320);	(* Dakar *)
		Add(33.5130, 36.2920);	(* Damascus *)
		Add(23.7289, 90.3944);	(* Dhaka *)
		Add(-8.5536, 125.5783);	(* Dili *)
		Add(11.5950, 43.1481);	(* Djibouti *)
		Add(-6.1835, 35.7460);	(* Dodoma *)
		Add(25.2861, 51.5294);	(* Doha *)
		Add(53.3497, -6.2603);	(* Dublin *)
		Add(38.5731, 68.7864);	(* Dushanbe *)
		Add(31.7834, 35.2339);	(* East Jerusalem *)
		Add(8.4872, -13.2356);	(* Freetown *)
		Add(-8.5048, 179.1174);	(* Funafuti *)
		Add(-24.6569, 25.9086);	(* Gaborone *)
		Add(6.8058, -58.1508);	(* Georgetown *)
		Add(-3.4283, 29.9250);	(* Gitega *)
		Add(14.6417, -90.5133);	(* Guatemala City *)
		Add(21.0245, 105.8412);	(* Hanoi *)
		Add(-17.8292, 31.0522);	(* Harare *)
		Add(23.1367, -82.3589);	(* Havana *)
		Add(60.1708, 24.9375);	(* Helsinki *)
		Add(-9.4333, 159.9500);	(* Honiara *)
		Add(33.6989, 73.0369);	(* Islamabad *)
		Add(-6.1753, 106.8269);	(* Jakarta *)
		Add(31.7767, 35.2342);	(* Jerusalem *)
		Add(4.8539, 31.5825);	(* Juba *)
		Add(34.5328, 69.1658);	(* Kabul *)
		Add(0.3136, 32.5811);	(* Kampala *)
		Add(27.7100, 85.3200);	(* Kathmandu *)
		Add(15.6031, 32.5265);	(* Khartoum *)
		Add(-1.9525, 30.1150);	(* Kigali *)
		Add(17.9714, -76.7931);	(* Kingston *)
		Add(13.1553, -61.2274);	(* Kingstown *)
		Add(-4.3219, 15.3119);	(* Kinshasa *)
		Add(3.1478, 101.6953);	(* Kuala Lumpur *)
		Add(29.3750, 47.9800);	(* Kuwait City *)
		Add(50.4500, 30.5236);	(* Kyiv *)
		Add(-16.4958, -68.1333);	(* La Paz *)
		Add(0.4078, 9.4403);	(* Libreville *)
		Add(-13.9864, 33.7681);	(* Lilongwe *)
		Add(-12.0600, -77.0375);	(* Lima *)
		Add(38.7080, -9.1390);	(* Lisbon *)
		Add(46.0514, 14.5061);	(* Ljubljana *)
		Add(-26.4465, 31.2064);	(* Lobamba *)
		Add(6.1300, 1.2158);	(* Lomé *)
		Add(51.5072, -0.1275);	(* London *)
		Add(-8.8150, 13.2300);	(* Luanda *)
		Add(-15.4167, 28.2833);	(* Lusaka *)
		Add(49.6114, 6.1300);	(* Luxembourg *)
		Add(40.4169, -3.7033);	(* Madrid *)
		Add(7.0918, 171.3802);	(* Majuro *)
		Add(4.1750, 73.5083);	(* Malé *)
		Add(12.1547, -86.2737);	(* Managua *)
		Add(26.2167, 50.5833);	(* Manama *)
		Add(14.5958, 120.9772);	(* Manila *)
		Add(-25.9689, 32.5733);	(* Maputo *)
		Add(-29.3100, 27.4800);	(* Maseru *)
		Add(-26.3167, 31.1333);	(* Mbabane *)
		Add(19.3538, -99.1359);	(* Mexico City *)
		Add(53.9022, 27.5618);	(* Minsk *)
		Add(2.0392, 45.3419);	(* Mogadishu *)
		Add(43.7311, 7.4200);	(* Monaco *)
		Add(6.3106, -10.8047);	(* Monrovia *)
		Add(-34.9059, -56.1913);	(* Montevideo *)
		Add(-11.7036, 43.2536);	(* Moroni *)
		Add(55.7506, 37.6175);	(* Moscow *)
		Add(23.6139, 58.5922);	(* Muscat *)
		Add(12.1100, 15.0500);	(* N'Djamena *)
		Add(-1.2864, 36.8172);	(* Nairobi *)
		Add(25.0781, -77.3386);	(* Nassau *)
		Add(19.7475, 96.1150);	(* Naypyidaw *)
		Add(28.6139, 77.2089);	(* New Delhi *)
		Add(7.5006, 134.6242);	(* Ngerulmud *)
		Add(13.5150, 2.1175);	(* Niamey *)
		Add(35.1725, 33.3650);	(* Nicosia *)
		Add(18.0858, -15.9785);	(* Nouakchott *)
		Add(-21.1343, -175.2018);	(* Nukuʻalofa *)
		Add(59.9133, 10.7389);	(* Oslo *)
		Add(45.4247, -75.6950);	(* Ottawa *)
		Add(12.3686, -1.5275);	(* Ouagadougou *)
		Add(6.9178, 158.1850);	(* Palikir *)
		Add(8.9711, -79.5347);	(* Panama City *)
		Add(5.8667, -55.1667);	(* Paramaribo *)
		Add(48.8567, 2.3522);	(* Paris *)
		Add(11.5696, 104.9210);	(* Phnom Penh *)
		Add(42.4414, 19.2628);	(* Podgorica *)
		Add(-20.1619, 57.4989);	(* Port Louis *)
		Add(-9.4789, 147.1494);	(* Port Moresby *)
		Add(-17.7333, 168.3167);	(* Port Vila *)
		Add(10.6667, -61.5167);	(* Port of Spain *)
		Add(18.5469, -72.3403);	(* Port-au-Prince *)
		Add(6.4833, 2.6167);	(* Porto-Novo *)
		Add(50.0875, 14.4214);	(* Prague *)
		Add(14.9177, -23.5092);	(* Praia *)
		Add(-25.7464, 28.1881);	(* Pretoria *)
		Add(42.6667, 21.1667);	(* Pristina *)
		Add(39.0167, 125.7475);	(* Pyongyang *)
		Add(17.1211, -61.8447);	(* Q36262 *)
		Add(-0.2200, -78.5125);	(* Quito *)
		Add(34.0211, -6.8414);	(* Rabat *)
		Add(31.8969, 35.2017);	(* Ramallah *)
		Add(64.1475, -21.9350);	(* Reykjavík *)
		Add(56.9475, 24.1069);	(* Riga *)
		Add(24.6383, 46.7150);	(* Riyadh *)
		Add(41.8931, 12.4828);	(* Rome *)
		Add(15.3000, -61.3833);	(* Roseau *)
		Add(9.9327, -84.0796);	(* San José *)
		Add(43.9320, 12.4484);	(* San Marino *)
		Add(13.6976, -89.1912);	(* San Salvador *)
		Add(15.3500, 44.2000);	(* Sanaa *)
		Add(-33.4375, -70.6500);	(* Santiago *)
		Add(18.4625, -69.9361);	(* Santo Domingo *)
		Add(43.8564, 18.4131);	(* Sarajevo *)
		Add(37.5600, 126.9900);	(* Seoul *)
		Add(1.3000, 103.8000);	(* Singapore *)
		Add(41.9961, 21.4317);	(* Skopje *)
		Add(42.6979, 23.3217);	(* Sofia *)
		Add(1.3333, 172.9667);	(* South Tarawa *)
		Add(6.9000, 79.9164);	(* Sri Jayawardenepura Kotte *)
		Add(12.0525, -61.7531);	(* St. George's *)
		Add(59.3294, 18.0686);	(* Stockholm *)
		Add(-19.0475, -65.2600);	(* Sucre *)
		Add(-18.1267, 178.4400);	(* Suva *)
		Add(0.3375, 6.7283);	(* São Tomé *)
		Add(25.0375, 121.5625);	(* Taipei *)
		Add(59.4372, 24.7450);	(* Tallinn *)
		Add(41.3111, 69.2797);	(* Tashkent *)
		Add(41.7225, 44.7925);	(* Tbilisi *)
		Add(14.1058, -87.2047);	(* Tegucigalpa *)
		Add(35.6889, 51.3897);	(* Tehran *)
		Add(27.4714, 89.6337);	(* Thimphu *)
		Add(41.3283, 19.8181);	(* Tirana *)
		Add(35.6894, 139.6917);	(* Tokyo *)
		Add(32.8875, 13.1875);	(* Tripoli *)
		Add(36.8008, 10.1800);	(* Tunis *)
		Add(47.9214, 106.9055);	(* Ulaanbaatar *)
		Add(47.1406, 9.5222);	(* Vaduz *)
		Add(35.8978, 14.5125);	(* Valletta *)
		Add(41.9040, 12.4530);	(* Vatican City *)
		Add(-4.6236, 55.4544);	(* Victoria *)
		Add(48.2083, 16.3725);	(* Vienna *)
		Add(17.9800, 102.6300);	(* Vientiane *)
		Add(54.6872, 25.2800);	(* Vilnius *)
		Add(52.2300, 21.0111);	(* Warsaw *)
		Add(38.8950, -77.0367);	(* Washington, D.C. *)
		Add(-41.2889, 174.7772);	(* Wellington *)
		Add(-22.5700, 17.0836);	(* Windhoek *)
		Add(6.8161, -5.2742);	(* Yamoussoukro *)
		Add(3.8578, 11.5181);	(* Yaoundé *)
		Add(-0.5477, 166.9209);	(* Yaren District *)
		Add(40.1814, 44.5144);	(* Yerevan *)
		Add(45.8131, 15.9772);	(* Zagreb *)
	END InitCapitals;

	(** Открыть карту (Альпы, 3000 км над Землёй). *)
	PROCEDURE Run*;
		VAR v: JEarth.EarthView;
	BEGIN
		v := JEarth.New();
		IF v = NIL THEN
			StdLog.String("JEarth: "); StdLog.String(JEarth.lastError); StdLog.Ln;
			RETURN
		END;
		JEarth.SetPosition(v, 45.0, 10.0, 3000000.0);	(* Альпы *)
		JEarth.SetImagery(v, JEarth.BlueMarble);
		Views.OpenAux(v, "Земля — JEarth");
		JEarth.Update(v)
	END Run;

	(** Вся планета целиком. *)
	PROCEDURE World*;
		VAR v: JEarth.EarthView;
	BEGIN
		v := JEarth.New();
		IF v = NIL THEN
			StdLog.String("JEarth: "); StdLog.String(JEarth.lastError); StdLog.Ln;
			RETURN
		END;
		JEarth.SetPosition(v, 20.0, 0.0, 2.2E7);
		Views.OpenAux(v, "Земля — мир");
		JEarth.Update(v)
	END World;

	(** Проверка рендера без окна: пишет `JEarth/Rsrc/Cache/demo.png`. *)
	PROCEDURE Check*;
		VAR ok: BOOLEAN;
	BEGIN
		ok := JEarth.RenderToCache();
		IF ok THEN
			StdLog.String("jearth=ok"); StdLog.Ln
		ELSE
			StdLog.String("jearth=fail: ");
			StdLog.String(JEarth.lastError); StdLog.Ln
		END
	END Check;

	(** Поставить красные точки во всех столицах на текущем виде. *)
	PROCEDURE MarkCapitals (v: JEarth.EarthView);
		VAR i: INTEGER;
	BEGIN
		InitCapitals;
		FOR i := 0 TO nCapitals - 1 DO
			JEarth.AddMarker(v, capitals[i].lat, capitals[i].lon, JEarth.red)
		END
	END MarkCapitals;

	(** Открыть карту мира со столицами (все — красными точками). *)
	PROCEDURE Capitals*;
		VAR v: JEarth.EarthView;
	BEGIN
		v := JEarth.New();
		IF v = NIL THEN
			StdLog.String("JEarth: "); StdLog.String(JEarth.lastError); StdLog.Ln;
			RETURN
		END;
		JEarth.SetPosition(v, 20.0, 0.0, 2.2E7);
		JEarth.SetImagery(v, JEarth.BlueMarble);
		MarkCapitals(v);
		Views.OpenAux(v, "Столицы мира — JEarth");
		JEarth.Update(v)
	END Capitals;

	(** Проверка без окна: карта мира со столицами в
	    `JEarth/Rsrc/Cache/capitals.png` + число точек в `Log`. *)
	PROCEDURE CapitalsCheck*;
		VAR v: JEarth.EarthView; ok: BOOLEAN;
	BEGIN
		InitCapitals;
		v := JEarth.New();
		IF v = NIL THEN
			StdLog.String("jearth-capitals=fail: "); StdLog.String(JEarth.lastError); StdLog.Ln;
			RETURN
		END;
		JEarth.SetPosition(v, 20.0, 0.0, 2.2E7);
		MarkCapitals(v);
		ok := JEarth.Snapshot(v, "JEarth/Rsrc/Cache/capitals.png");
		StdLog.String("jearth-capitals=");
		IF ok THEN StdLog.String("ok") ELSE StdLog.String("fail") END;
		StdLog.String(" markers="); StdLog.Int(JEarth.MarkerCount(v));
		StdLog.String(" expected="); StdLog.Int(nCapitals);
		IF ok THEN StdLog.String(" png=capitals.png") ELSE StdLog.String(" err="); StdLog.String(JEarth.lastError) END;
		StdLog.Ln
	END CapitalsCheck;

END JEarthDemo.
