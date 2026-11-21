import 'package:flutter/material.dart';
import 'package:studio_core/core/strings.dart';
import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/arcade.dart';

import 'retro_engine.dart';

// Kendi LCD paletimiz: zeytin yeşili ekran, koyu noktalar.
const _screen = Color(0xFF9DAF8A);
const _off = Color(0xFF8FA07C);
const _on = Color(0xFF1F2A1A);
const _frame = Color(0xFF2E3A33);

const _names = [
  ['YARIŞ', 'RACE'],
  ['YILAN', 'SNAKE'],
  ['ATIŞ', 'SHOOT'],
  ['TUĞLA KIR', 'BRICKS'],
];

void paintRetro(Canvas c, ArcadeSim sim, ArcadePalette p, double t, [String lang = 'en']) {
  final s = sim as RetroSim;
  const cell = 62.0;
  const left = 40.0, top = 210.0;
  final screen = Rect.fromLTWH(left - 16, top - 16, kW * cell + 32, kH * cell + 32);
  c.drawRRect(RRect.fromRectAndRadius(screen.inflate(14), const Radius.circular(26)), Paint()..color = _frame);
  c.drawRRect(RRect.fromRectAndRadius(screen, const Radius.circular(12)), Paint()..color = _screen);
  final px = s.pixels();
  final blink = s.shield > 0 && (s.ticks ~/ 8).isOdd;
  for (var y = 0; y < kH; y++) {
    for (var x = 0; x < kW; x++) {
      final on = px.contains(y * kW + x);
      final r = Rect.fromLTWH(left + x * cell, top + y * cell, cell, cell).deflate(5);
      final col = on ? (blink ? _on.withValues(alpha: 0.45) : _on) : _off;
      c.drawRect(r, Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6);
      c.drawRect(r.deflate(12), Paint()..color = col);
    }
  }
  // Yan panel
  const sx = left + kW * cell + 40;
  final pw = kWorldW - sx - 18;
  final name = _names[s.game.index];
  paintText(c, Strings.tx(lang, name[0], name[1]), Offset(sx + pw / 2, top + 50), 40, Colors.white);
  paintText(c, '${s.score}', Offset(sx + pw / 2, top + 200), 52, const Color(0xFFFFE082));
  paintText(c, '♥' * s.lives, Offset(sx + pw / 2, top + 290), 40, const Color(0xFFEF9A9A));
  paintText(c, '◀', Offset(sx + pw / 2 - 60, top + kH * cell - 80), 70, Colors.white24);
  paintText(c, '▶', Offset(sx + pw / 2 + 60, top + kH * cell - 80), 70, Colors.white24);
}

Sfx? retroSound(ArcadeSim sim) => switch ((sim as RetroSim).lastEvent) {
      1 => Sfx.coin,
      2 => Sfx.lose,
      3 => Sfx.tap,
      _ => null,
    };

Widget buildRetroStage(PlayContext ctx, RetroLevel level) => ArcadeStage(
      ctx: ctx,
      create: () => RetroSim(level),
      paint: (c, sim, p, t) => paintRetro(c, sim, p, t, ctx.lang),
      sound: retroSound,
      howTo: switch (level.game) {
        RetroGame.race => const [
            'Ekranın soluna/sağına dokun ya da kaydır: şerit değiştir. Arabalara çarpma!',
            'Tap or swipe left/right to change lanes. Avoid the cars!',
            'Links/rechts tippen oder wischen: Spur wechseln.',
            'Toca o desliza a los lados para cambiar de carril.',
            'Touchez ou glissez à gauche/droite pour changer de voie.',
      // ar fa he ur ru uk pl cs ro hu el it pt nl sv da nb fi ja ko zh hi bn id ms th vi fil
      'المس أو اسحب يمينًا/يسارًا لتغيير المسار. تجنب السيارات!',
      'برای عوض کردن خط، چپ/راست را لمس کن یا بکش. از ماشین‌ها دوری کن!',
      'הקישו או החליקו ימינה/שמאלה להחלפת נתיב. התחמקו מהמכוניות!',
      'لین بدلنے کے لیے بائیں/دائیں چھوئیں یا سوائپ کریں۔ گاڑیوں سے بچیں!',
      'Касайтесь или смахивайте влево/вправо, меняя полосу. Не врезайтесь!',
      'Торкайтеся або змахуйте вліво/вправо, щоб змінити смугу. Не врізайтеся!',
      'Dotknij lub przesuń w lewo/prawo, by zmienić pas. Omijaj auta!',
      'Klepni nebo táhni doleva/doprava a změň pruh. Vyhni se autům!',
      'Atinge sau glisează stânga/dreapta ca să schimbi banda. Evită mașinile!',
      'Koppints vagy húzz balra/jobbra a sávváltáshoz. Kerüld az autókat!',
      'Πάτησε ή σύρε αριστερά/δεξιά για αλλαγή λωρίδας. Απόφυγε τα αυτοκίνητα!',
      'Tocca o scorri a destra/sinistra per cambiare corsia. Evita le auto!',
      'Toque ou deslize para os lados para mudar de faixa. Evite os carros!',
      'Tik of veeg links/rechts om van baan te wisselen. Ontwijk de auto\'s!',
      'Tryck eller svep vänster/höger för att byta fil. Undvik bilarna!',
      'Tryk eller stryg til venstre/højre for at skifte bane. Undgå bilerne!',
      'Trykk eller sveip til venstre/høyre for å bytte fil. Unngå bilene!',
      'Napauta tai pyyhkäise vasemmalle/oikealle vaihtaaksesi kaistaa. Väistä autoja!',
      '左右をタップかスワイプで車線変更。車をよけよう！',
      '좌우를 누르거나 밀어 차선 변경. 차를 피하세요!',
      '点击或左右滑动换车道。避开车辆！',
      'लेन बदलने के लिए बाएँ/दाएँ छुएँ या स्वाइप करें। गाड़ियों से बचें!',
      'লেন বদলাতে বাঁ/ডান ছুঁন বা সোয়াইপ করুন। গাড়ি এড়িয়ে চলুন!',
      'Ketuk atau usap kiri/kanan untuk pindah jalur. Hindari mobil!',
      'Ketik atau leret kiri/kanan untuk pindah jalur. Elakkan kereta!',
      'แตะหรือปัดซ้าย/ขวาเพื่อเปลี่ยนเลน หลบรถ!',
      'Chạm hoặc vuốt trái/phải để đổi làn. Tránh xe!',
      'I-tap o i-swipe pakaliwa/pakanan para lumipat ng linya. Iwasan ang mga kotse!',
    ],
        RetroGame.snake => const [
            'Kaydırarak yılanı yönlendir, yemi ye, kendine çarpma.',
            'Swipe to steer, eat the food, don\'t bite yourself.',
            'Wischen zum Lenken, Futter fressen.',
            'Desliza para girar y come.',
            'Glissez pour tourner et mangez.',
      // ar fa he ur ru uk pl cs ro hu el it pt nl sv da nb fi ja ko zh hi bn id ms th vi fil
      'اسحب للتوجيه، كُل الطعام ولا تعضّ نفسك.',
      'برای هدایت بکش، غذا بخور و خودت را گاز نگیر.',
      'החליקו כדי לנווט, אכלו ואל תנשכו את עצמכם.',
      'سوائپ سے راستہ بدلیں، کھانا کھائیں اور خود کو نہ کاٹیں۔',
      'Смахивайте, чтобы управлять, ешьте и не кусайте себя.',
      'Змахуйте, щоб керувати; їжте й не кусайте себе.',
      'Przesuwaj, by sterować; jedz i nie gryź siebie.',
      'Táhni pro řízení, jez a nekousni se.',
      'Glisează ca să conduci, mănâncă și nu te mușca.',
      'Húzással irányíts, egyél, és ne harapd meg magad.',
      'Σύρε για να κατευθύνεις, φάε και μη δαγκώσεις τον εαυτό σου.',
      'Scorri per guidare, mangia e non morderti.',
      'Deslize para guiar, coma e não morda a si mesmo.',
      'Veeg om te sturen, eet en bijt jezelf niet.',
      'Svep för att styra, ät och bit inte dig själv.',
      'Stryg for at styre, spis og bid ikke dig selv.',
      'Sveip for å styre, spis og ikke bit deg selv.',
      'Pyyhkäise ohjataksesi, syö äläkä pure itseäsi.',
      'スワイプで向きを変え、エサを食べよう。自分をかまないで。',
      '밀어서 방향을 바꾸고 먹이를 먹되 자기 몸은 물지 마세요.',
      '滑动控制方向，吃到食物，别咬到自己。',
      'स्वाइप से दिशा बदलें, खाना खाएँ और ख़ुद को न काटें।',
      'সোয়াইপে দিক বদলান, খাবার খান, নিজেকে কামড়াবেন না।',
      'Usap untuk mengarahkan, makan dan jangan gigit diri sendiri.',
      'Leret untuk mengarahkan, makan dan jangan gigit diri sendiri.',
      'ปัดเพื่อบังคับ กินอาหาร และอย่ากัดตัวเอง',
      'Vuốt để lái, ăn mồi và đừng cắn mình.',
      'I-swipe para gabayan, kumain, at huwag kagatin ang sarili.',
    ],
        RetroGame.shoot => const [
            'Sola/sağa dokun: topu kaydır. Parmağın ekrandayken ateş eder.',
            'Tap left/right to move. Hold to fire.',
            'Links/rechts tippen zum Bewegen, halten zum Feuern.',
            'Toca a los lados para moverte, mantén para disparar.',
            'Touchez à gauche/droite, maintenez pour tirer.',
      // ar fa he ur ru uk pl cs ro hu el it pt nl sv da nb fi ja ko zh hi bn id ms th vi fil
      'المس اليسار/اليمين للتحرك. اضغط مطولًا لإطلاق النار.',
      'برای حرکت چپ/راست را لمس کن. برای شلیک نگه دار.',
      'הקישו שמאלה/ימינה כדי לזוז. החזיקו כדי לירות.',
      'حرکت کے لیے بائیں/دائیں چھوئیں۔ فائر کے لیے دبائے رکھیں۔',
      'Касайтесь слева/справа для движения. Удерживайте для стрельбы.',
      'Торкайтеся зліва/справа для руху. Утримуйте для стрільби.',
      'Dotykaj lewej/prawej strony, by się ruszać. Przytrzymaj, by strzelać.',
      'Klepej vlevo/vpravo pro pohyb. Podrž pro střelbu.',
      'Atinge stânga/dreapta pentru mișcare. Ține apăsat ca să tragi.',
      'Koppints balra/jobbra a mozgáshoz. Tartsd lenyomva a lövéshez.',
      'Πάτησε αριστερά/δεξιά για κίνηση. Κράτα για βολή.',
      'Tocca a sinistra/destra per muoverti. Tieni premuto per sparare.',
      'Toque à esquerda/direita para mover. Segure para atirar.',
      'Tik links/rechts om te bewegen. Houd vast om te schieten.',
      'Tryck vänster/höger för att röra dig. Håll in för att skjuta.',
      'Tryk venstre/højre for at bevæge dig. Hold nede for at skyde.',
      'Trykk venstre/høyre for å bevege deg. Hold inne for å skyte.',
      'Napauta vasemmalle/oikealle liikkuaksesi. Pidä painettuna ampuaksesi.',
      '左右をタップで移動。長押しで発射。',
      '좌우를 눌러 이동. 길게 누르면 발사.',
      '点左/右移动。按住射击。',
      'चलने के लिए बाएँ/दाएँ छुएँ। गोली के लिए दबाए रखें।',
      'নড়তে বাঁ/ডান ছুঁন। গুলি করতে চেপে ধরুন।',
      'Ketuk kiri/kanan untuk bergerak. Tahan untuk menembak.',
      'Ketik kiri/kanan untuk bergerak. Tahan untuk menembak.',
      'แตะซ้าย/ขวาเพื่อเคลื่อนที่ กดค้างเพื่อยิง',
      'Chạm trái/phải để di chuyển. Giữ để bắn.',
      'I-tap ang kaliwa/kanan para gumalaw. Pindutin nang matagal para bumaril.',
    ],
        RetroGame.breakout => const [
            'Raketi sürükle ya da sola/sağa dokun. Topu düşürme, bütün tuğlaları kır.',
            'Drag the paddle or tap the sides. Break every brick.',
            'Schläger ziehen oder seitlich tippen. Alle Steine zerstören.',
            'Arrastra la pala o toca los lados. Rompe todos los ladrillos.',
            'Glissez la raquette ou touchez les côtés. Cassez toutes les briques.',
      // ar fa he ur ru uk pl cs ro hu el it pt nl sv da nb fi ja ko zh hi bn id ms th vi fil
      'اسحب المضرب أو المس الجانبين. حطّم كل الطوب.',
      'راکت را بکش یا کناره‌ها را لمس کن. همه آجرها را بشکن.',
      'גררו את המחבט או הקישו בצדדים. שברו את כל הלבנים.',
      'پیڈل گھسیٹیں یا کنارے چھوئیں۔ ساری اینٹیں توڑیں۔',
      'Двигайте платформу или касайтесь краёв. Разбейте все кирпичи.',
      'Рухайте платформу або торкайтеся країв. Розбийте всі цеглини.',
      'Przeciągaj paletkę lub dotykaj boków. Rozbij wszystkie cegły.',
      'Táhni pálku nebo klepej na strany. Rozbij všechny cihly.',
      'Trage paleta sau atinge marginile. Sparge toate cărămizile.',
      'Húzd az ütőt, vagy koppints az oldalakra. Törd szét az összes téglát.',
      'Σύρε τη ρακέτα ή πάτησε στα πλάγια. Σπάσε όλα τα τούβλα.',
      'Trascina la racchetta o tocca i lati. Rompi tutti i mattoni.',
      'Arraste a raquete ou toque nos lados. Quebre todos os tijolos.',
      'Sleep het batje of tik op de zijkanten. Breek alle stenen.',
      'Dra racketen eller tryck på sidorna. Krossa alla tegelstenar.',
      'Træk bat\'et eller tryk i siderne. Smadr alle mursten.',
      'Dra racketen eller trykk på sidene. Knus alle mursteinene.',
      'Vedä mailaa tai napauta reunoja. Riko kaikki tiilet.',
      'パドルをドラッグするか左右をタップ。レンガを全部壊そう。',
      '패들을 끌거나 양옆을 누르세요. 벽돌을 모두 깨세요.',
      '拖动挡板或点两侧。打碎所有砖块。',
      'पैडल खींचें या किनारे छुएँ। सारी ईंटें तोड़ें।',
      'প্যাডেল টানুন বা দুই পাশ ছুঁন। সব ইট ভাঙুন।',
      'Seret pemukul atau ketuk sisi. Hancurkan semua bata.',
      'Seret pemukul atau ketik sisi. Hancurkan semua bata.',
      'ลากไม้ตีหรือแตะด้านข้าง ทำลายอิฐทั้งหมด',
      'Kéo thanh đỡ hoặc chạm hai bên. Phá hết gạch.',
      'I-drag ang paddle o i-tap ang mga gilid. Basagin lahat ng ladrilyo.',
    ],
      },
    );
