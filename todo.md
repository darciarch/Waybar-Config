# Waybar + swaync — Bar/kontrol yüzeyi yeniden düzenleme

Onaylı plan: `~/.claude/plans/suanda-focus-butonu-calismiyor-indexed-sky.md`
Bu dosya = kaldığımız yerden devam için iş listesi. **UYGULANDI (2026-09-05).**

> ⚠️ Doğrulama engeli: `waybar-git` eski `libjsoncpp.so.26`'ya linkli, sistemde artık
> `libjsoncpp.so.27` (jsoncpp 1.9.8) var → `waybar` restart edilemiyor
> (`error while loading shared libraries: libjsoncpp.so.26`). Çalışan bar (pid, upgrade
> öncesi başlamış) hâlâ ayakta. Önce `paru -S waybar-git` (veya `makepkg` ile yeniden derle),
> sonra aşağıdaki "Doğrulama" adımlarını çalıştır.

## Bağlam (neden)

- `custom/media` (mor kutu, battery'nin solunda) bar'ı meşgul ediyor → bildirim merkezine taşınacak.
- `custom/swaync` kutusu görünmüyor → waybar swaync'ten önce başlıyor, `swaync-client -swb`
  bağlanamadan ölüyor, modül tekrar denemiyor.
- Kronometre kullanılamıyor → `hide-empty-text` ile boştayken görünmez, başlatmak için `on-click`'ten
  başka yol yok (görünmeyen kutuya tıklanamaz). `custom/uptime` içine gömülecek.
- Mikrofon `wireplumber` kapsülüne (`format-source`) sıkışmış → swaync panelinde butona taşınacak.
- Güç profili göstergesi yok; tooltip'te "0W" (pil dolu+AC olduğu için normal) "bozuk" hissi veriyor.
- `XF86AudioMicMute` tuşu `hyprland.lua`'da yanlışlıkla `hyprshot -m region`'a bağlı (çakışma).

**DOKUNMA:** parlaklık (`backlight` modülü + scroll) hiç değişmeyecek. Bar sıralaması (istenen
değişiklikler dışında) korunacak.

## İş listesi

### `~/.config/waybar/config.jsonc`
- [x] `modules-left`: `custom/stopwatch` çıkar → `["clock", "hyprland/window"]`
- [x] `modules-right`: `custom/media` çıkar; `battery`'den sonra `power-profiles-daemon` ekle →
      `["battery","power-profiles-daemon","backlight","wireplumber","custom/focus","custom/uptime",
      "custom/wifi","custom/sysinfo","custom/swaync"]`
- [x] `custom/media` bloğunu sil
- [x] `custom/stopwatch` bloğunu sil
- [x] `battery`: `on-click` (battery_profile_toggle.sh) sil; tooltip'i ayır:
      `tooltip-format-discharging: "{timeTo}  ·  {power}W"`, `tooltip-format-charging: "{timeTo}"`,
      `tooltip-format-full: "Şarj dolu"`
- [x] `power-profiles-daemon` bloğu (YENİ): `format: "{icon}"`,
      `tooltip-format: "Güç profili: {profile}\nTıkla → değiştir"`,
      `format-icons: { default: "󰾅", performance: "󰓅", balanced: "󰾅", "power-saver": "󰾆" }`
- [x] `custom/uptime`: `exec` → `$HOME/.config/waybar/scripts/uptime.sh`, `return-type: "json"`,
      `interval: 1`, `tooltip: true`, `on-click: ".../stopwatch.sh toggle"`,
      `on-click-right: ".../stopwatch.sh reset"`, `format: " {}"` (baştaki  glyph korunur)
- [x] `custom/swaync`: `exec-if` → `"swaync-client -c -sw"` (gerisi aynı)

### `~/.config/waybar/scripts/uptime.sh` (YENİ)
- [x] Kutu her zaman uptime gösterir; kronometre durumu **tooltip**'te
- [x] `uptime -p | sed '...'` — mevcut config'teki sed ifadesini birebir koru
- [x] `~/.cache/waybar/stopwatch_state` oku (`running:start:acc`), geçen süreyi hesapla
- [x] Glyph script içinde `printf '\uXXXX'` ile (CLAUDE.md kuralı)
- [x] JSON: `{text, tooltip, class}` — class `idle|running|paused`
      - running: `"󱎫 mm:ss çalışıyor · sol tık: duraklat · sağ tık: sıfırla"`
      - paused (e>0): `"󱎫 mm:ss duraklatıldı · sol tık: devam · sağ tık: sıfırla"`
      - idle: `"Kronometre · sol tık: başlat"`

### `~/.config/waybar/scripts/`
- [x] `stopwatch.sh` — DEĞİŞMEZ (artık sadece `toggle`/`reset` kullanılıyor)
- [x] `media.sh` — SİL
- [x] `battery_profile_toggle.sh` — SİL

### `~/.config/waybar/style.css`
- [x] Ortak kapsül selector listesinden `#custom-media,` ve `#custom-stopwatch,` çıkar
- [x] `#custom-media { color: #cba6f7; }` ve `#custom-stopwatch { color: #cdd6f4; }` bloklarını sil
- [x] battery + güç profili bitişik ("tek kapsül"):
      `#battery { color:#a6e3a1; border-radius:1rem 0 0 1rem; margin-right:0; }`
      `#power-profiles-daemon { background-color:#1e1e2e; color:#cba6f7;
      padding:0.15rem 0.7rem 0.15rem 0.4rem; margin:0.5rem 0.2rem 0.7rem 0;
      border-radius:0 1rem 1rem 0; margin-left:-2px; }`  (dikiş: uygulamada ince ayar)
- [x] `#custom-uptime.running { color:#a6e3a1; }` / `#custom-uptime.paused { color:#f9e2af; }`
      (idle için `#custom-uptime { color: seashell; }` kalır)
- [x] Yorumlar Türkçe, mevcut üslupla

### `~/.config/swaync/config.json`
- [x] `widgets`: `["title","dnd","mpris","buttons-grid","notifications"]`
- [x] `widget-config.mpris`: `{ image-size:90, "show-album-art":"always", autohide:false,
      blacklist:[], "loop-carousel":false }`
- [x] `widget-config.buttons-grid`: `buttons-per-row:3`, tek action:
      `{ label:"󰍬", type:"toggle", active:false,
      command:"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
      "update-command":"sh -c 'wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo true || echo false'" }`
      (checked = mikrofon muted → CSS kırmızı vurgu)

### `~/.config/swaync/style.css`
- [x] Sona `.widget-mpris` + `.widget-buttons-grid` kuralları ekle (Mocha kapsül dili,
      `.widget-dnd`/`.widget-title` ile tutarlı; `button.toggle:checked { background:#f38ba8; color:#11111b; }`)
- [x] GTK node yollarını `GTK_DEBUG=interactive swaync` ile doğrula (buttons-grid iç yapı
      `flowbox > flowboxchild > button` olabilir)

### `~/.config/hypr/hyprland.lua`
- [x] `hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("hyprshot -m region"))` satırını SİL (~208)
      → satır ~247'deki `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` devreye girer (F9 = mic mute)
- [x] Ekle: `hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m region"))`
- [x] Autostart: `swaync &`'i `waybar`'dan **önce** al

### `~/.config/waybar/CLAUDE.md`
- [x] `media.sh` / `battery_profile_toggle.sh` satırlarını kaldır (silindi)
- [x] `stopwatch.sh` → "sadece toggle/reset state yardımcısı; görüntü uptime.sh'de"
- [x] `uptime.sh` (YENİ) ekle
- [x] `custom/media` → swaync `mpris`; `custom/stopwatch` kaldırıldı; `custom/uptime` tıklanabilir
- [x] `power-profiles-daemon` native modül, CSS ile `#battery`'ye bitişik
- [x] Mikrofon-mute `wireplumber` yerine swaync `buttons-grid`'te
- [x] swaync autostart `waybar`'dan önce; `XF86AudioMicMute`→mic mute, bölge SS `SUPER+Print`

## Doğrulanmış ortam gerçekleri (bu oturumda test edildi)

- swaync **0.12.6 kurulu + çalışıyor**. Widget: `mpris`, `buttons-grid`, `volume`, `backlight`,
  `slider`, `menubar`. Toggle buton = `command` + `update-command` (echo true/false),
  bkz. `/usr/share/doc/swaync/README.md` "Toggle Buttons".
- swaync widget-config şeması: `mpris` → image-size/show-album-art/autohide/blacklist/loop-carousel;
  `backlight` → label/device(intel_backlight)/subsystem/min; `volume` → label/show-per-app/...;
  `slider` → label/cmd_setter/cmd_getter/min/max (genel amaçlı komut slider'ı).
- `powerprofilesctl` **aktif + enabled**. Profiller: performance / balanced / power-saver.
  `battery_profile_toggle.sh` test edildi → çalışıyor (balanced→power-saver yaptı, geri alındı).
  Native waybar `power-profiles-daemon` modülü tıklamada profilleri döndürüyor.
- **"0W" arıza değil**: `BAT0` fully-charged + AC → `power_now=0`, `energy-rate: 0 W`. Deşarjda
  gerçek watt görünür.
- `stopwatch.sh toggle`/`reset` **çalışıyor**. State: `~/.cache/waybar/stopwatch_state` =
  `running:start_epoch:accumulated`. Script sağlam; sorun sadece modülün görünmezliğiydi.
- Tarayıcı YouTube/Netflix **MPRIS yayınlıyor** (`playerctl` brave'deki videoyu gördü) → swaync
  `mpris` bunları gösterir (YouTube'da kapak resmi gelir, Netflix'te değişken).
- `hyprshot`, `grim`, `slurp` **kurulu**. Hyprland **0.56.1**, PrtSc = `Print`.
- Laptop: **ASUS** (`asus-nb-wmi` / `asus-wmi-hotkeys`) + ayrıca harici `e-signal` USB klavye.
- `hyprland.lua` autostart: `hl.exec_cmd("waybar")` (~29) `swaync &`'ten (~35) **önce** →
  `custom/swaync` boş kalmasının kök nedeni.
- `hyprland.lua` `XF86AudioMicMute` **iki kez** bağlı: ~208 → `hyprshot -m region` (yanlış),
  ~247 → `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` (doğru). ~208 silinecek.
- `wev` / `libinput` / `evtest` **kurulu değil** (Fn+F10 keysym'i tespit edilemedi → kullanıcı
  `SUPER+Print` seçti).
- backlight: `intel_backlight`, şu an %41 (164/400).
- Mikrofon (`@DEFAULT_AUDIO_SOURCE@`) şu an **muted**; `wpctl get-volume` çıktısı `[MUTED]`
  içeriyor (grep ile parse edilebilir).

## Riskler / geri düşüşler

- `power-profiles-daemon` modülü waybar'da derlenmemişse sessizce düşer → `killall waybar; waybar`
  foreground çıktısını kontrol et. Geri düşüş: `battery` on-click → `battery_profile_toggle.sh`.
- swaync CSS class isimleri sürüme göre değişebilir → `GTK_DEBUG=interactive swaync`.
- `margin-left:-2px` dikişi kapatmazsa `config.jsonc` `spacing`'i ayarla ya da battery+ppd'yi
  tek `custom/` script'te birleştir.

## Doğrulama (uygulama sonrası)

1. `killall waybar; waybar` (foreground) — modül düşmüyor; `power-profiles-daemon`, `custom/uptime`,
   `custom/swaync` render. Ctrl-C, sonra `scripts/launch.sh`.
2. swaync kutusu: en sağda çan; bildirimde mor; tık → panel.
3. Güç profili: ikona tık → `powerprofilesctl get` döngüsü; battery ile dikişsiz.
4. Kronometre: uptime'a sol tık → `stopwatch_state` `1:...`, renk değişir, hover tooltip `mm:ss`;
   sağ tık → `0:0:0`.
5. Medya: YouTube aç → `swaync-client -t` panelinde mpris kontrolleri; bar'da mor kutu yok.
6. Mikrofon: swaync buton → `wpctl get-volume @DEFAULT_AUDIO_SOURCE@` MUTED değişir; muted iken kırmızı.
7. Tuşlar: F9 → mic mute (SS değil); `SUPER+Print` → slurp bölge seçimi.
8. Reload: `killall -SIGUSR2 waybar`, `swaync-client -R`, `swaync-client --reload-config`,
   hyprland config reload / relogin.

---

## Arşiv — Faz 1 (tamamlandı)

Waybar sıfırdan kurulum (grilling, 3 tur). Script'ler yazıldı/test edildi: `wifi_bt.sh`, `sysinfo.sh`,
`media.sh`, `stopwatch.sh`, `battery_profile_toggle.sh`, `workspace_bar_daemon.py`,
`toggle_workspace_bar.sh`, `first_time_setup.sh`. `config.jsonc` + `style.css` + `hyprland.lua`
güncellendi, swaync config'i yazıldı, CLAUDE.md güncellendi. Sistem kurulumu (swaync, ppd enable,
dunst mask) **yapıldı** — swaync 0.12.6 çalışıyor, ppd aktif+enabled.

Ayrıca çözüldü: `custom/focus` butonu (Hyprland Lua config'i `hyprctl dispatch`'i Lua ifadesi olarak
yorumluyor; `focus.sh` `hl.dsp.window.close(...)` / `hl.dsp.exec_cmd(...)` biçimine güncellendi).
CLAUDE.md'ye bu tuzak için "Conventions" notu eklendi.
