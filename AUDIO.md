# Letter audio

Spoken pronunciations played by `AudioService` (bundled files always win over
the synthesized fallback tones).

Naming convention (§4.6):

- `letter-<id>.m4a` — the letter's name (e.g. `letter-2.m4a` = "بَاء"),
  ids 1–28 in alphabet order (1 = ا … 28 = ي).
- `letter-<id>-<fatha|damma|kasra>.m4a` — the vowelled syllable
  (e.g. `letter-2-fatha.m4a` = "بَ").
- `alphabet-song.m4a` — all 28 letter names in order.

## Provenance

Generated 2026-07-07 with the macOS built-in Arabic voice **Majed**
(`say -v Majed`, syllables at rate 80 with silence padding), encoded to
AAC 64 kbps via `afconvert`. This upgrades the §7.1 placeholder tones to real
spoken Arabic, but native-speaker studio recordings are still preferred for
release — to replace any file, drop a recording with the same name here;
no code changes needed.

Quranic recitation files (`fatihah.m4a`, `ikhlas.m4a`, `nas.m4a`) are
intentionally NOT synthesized — recitation must come from a human reciter
(§7.1); the library falls back to a placeholder tone until then.
