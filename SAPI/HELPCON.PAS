unit HelpCon;

interface

const
 HelpCount  =36;
 hcRunning  =1000;
 hcFile     =1001;
 hcLoad     =1002;
 hcSave     =1003;
 hcNew      =1004;
 hcWrite    =1005;
 hcRead     =1006;
 hcInfo     =1007;
 hcQuit     =1008;
 hcEdit     =1009;
 hcEdLine   =1010;
 hcEdProg   =1011;
 hcSearch   =1012;
 hcFind     =1013;
 hcAgain    =1014;
 hcSLine    =1015;
 hcRun      =1016;
 hcStart    =1017;
 hcStep     =1018;
 hcReset    =1019;
 hcDebug    =1020;
 hcEval     =1021;
 hcModif    =1022;
 hcTerminal =1023;
 hcAnalog   =1024;
 hcWindow   =1025;
 hcSize     =1026;
 hcZoom     =1027;
 hcTile     =1028;
 hcNext     =1029;
 hcPrev     =1030;
 hcClear    =1031;
 hcconfig   =1032;
 hcCopyr    =1033;
 hcNewLine  =1034;
 hcBreakP   =1035;
 hcDelLine  =1036;

 HelpMsg:array [1..HelpCount] of String[70] =
  ('Prikazy prace se soubory (Load, Save, New, atd.)',
   'Nacte program v Mikro basicu z disku do pameti',
   'Ulozi program v Mikro basicu z pameti na disk',
   'Nenavratne vymaze program z pameti',
   'Presune program z pameti PC do pameti SAPI pres paralelni port',
   'Nacte program ze SAPI do pameti PC pres seriovy port',
   'Zobrazi zakladni informace',
   'Navrat do systemu (nebo na jinou predchozi uroven)',
   'Opravy jednotlivych radek nebo celeho programu',
   'Oprava aktualni radky programu',
   'Nacteni textu programu do editoru',
   'Vyhledavani radku podle cisla nebo libovolneho retezce',
   'Vyhledani retezce od pozice kursoru v programu',
   'Vyhledani dalsiho vyskytu',
   'Nastaveni kurzoru na radku daneho cisla',
   'Rizeni behu programu (Run, Step, Reset)',
   'Spusteni programu v pameti',
   'Krokovani programu po radcich (nikoli po prikazech)',
   'Uvedeni emulatoru do vychoziho stavu (nenuluje buffer obrazovky)',
   'Modifikace promenych zobrazenych v okne Watch',
   'Vypocet zadaneho vzorce (zna pouze funkce Mikro basicu)',
   'Zmena hodnot promenych A-Z a @(*)',
   'Rezim primeho pristupu do pocitace SAPI (nutne plne propojeni)',
   'Zmena hodnot analogovych vstupu a vystupu',
   'Prikazy pro praci s okny (Size, Zoom, Tile, atd.)',
   'Zmena velikosti nebo pozice okna (je-li povolena)',
   'Zvetseni okna na maximalni/puvodni velikost',
   'Nastaveni standartniho usporadani oken',
   'Aktivace nasledujiciho okna',
   'Aktivace predchoziho okna',
   'Zruseni bufferu obrazovky',
   'Nastaveni konfigurace emulatoru',
   'Show version and copyright information',
   'Vlozeni nove radky do programu',
   'Vlozeni breakpointu na aktualni radek.',
   'Vymaz aktualni radky z programu');

implementation

end.