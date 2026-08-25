# Lokaler Testbericht — Value-Add Batch 2

**Stand: 2026-08-26**
**Ergebnis: statische Prüfungen und Datenbankfälle vollständig bestanden —
lokal, gegen einen eigenen PostgreSQL-Cluster.**
**Status bleibt: lokal getestet, noch nicht auf Production ausgeführt.**

Dieser Bericht trennt weiterhin sauber, wer was ausgeführt hat:

- Der **maßgebliche Harness-Lauf** (statisch + Datenbankfälle) wurde von
  **Codex** unabhängig ausgeführt und auditiert — auf dem **aktuellen**
  Textstand, also **nach** den Entschärfungen aus §6. Die Zahlen in §1 stammen
  aus diesem Lauf, nicht aus einer Rekonstruktion.
- Die **statischen Gegenproben** in §2 wurden in der Claude-Session manuell
  über `grep`/`sha256sum` nachgezogen, weil dort die Ausführung von
  Shell-Skripten von der Berechtigungsschicht abgelehnt wird (§3).

---

## 0. Was dieser Vorgang nicht angefasst hat

- Kein Supabase-Aufruf, kein MCP-Tool, kein Netzwerkzugriff.
- Kein Zugriff auf `project/ydiihvzcxaaoqhmgoqvu` (Production).
- Kein Zugriff auf `project/nmzuycveumyfvtxdcnuc` (Pilot/Staging).
- Kein `git add`, kein Commit, kein Push, kein Deploy.
- Keine Änderung an `apps/web/supabase/production_value_add/` (Batch 1) — per
  `sha256sum -c` belegt, siehe §1.2 und §2.1.
- Keine Änderung am Obsidian-Vault.

---

## 1. Der maßgebliche Harness-Lauf (Codex, nach den Textentschärfungen)

### 1.1 Umgebung und Aufruf

PostgreSQL **16.15** war und ist auf dieser Maschine **nicht systemweit
installiert**. Codex hat den Paketbaum ausschließlich nach `/tmp` entpackt und
den Harness über `CBB_PG_BIN` und `LD_LIBRARY_PATH` auf diese temporären
Binaries gezeigt — Aufrufmuster:

```
env LD_LIBRARY_PATH=<entpackter-baum>/root/usr/lib/x86_64-linux-gnu \
    CBB_PG_BIN=<entpackter-baum>/root/usr/lib/postgresql/16/bin \
    bash test/run_local_postgres_test.sh
```

Erfolgreicher Workdir des maßgeblichen Laufs: `/tmp/cbb-pgtest-b2.CvjYPVa5`.
Der Cluster wurde am Ende sauber gestoppt.

Das sind `/tmp`-Pfade. Sie überleben keinen Neustart — eine Wiederholung
braucht das Entpacken erneut. Die Binaries wurden **nicht** nach `/usr`
installiert.

### 1.2 Ergebnis

| | Wert |
|---|---|
| Exit-Code | **0** |
| Ausgeführte Schritte | **106** |
| Abweichungen | **0** |
| Gesamturteil | **GESAMT PASS** |
| v1-Manifest | **34/34 identisch** |

Abgedeckt und bestanden:

- Happy Path (`01` → `02` → `02b` → `03` → `04` → `04b`)
- Wiederholungen aller drei schreibenden Dateien (fail-closed)
- Drift zwischen Snapshot und Bestand
- Transaktionsrollback mitten in `03`
- doppelter Restore-Roundtrip (`02` → `03` → `05` → `05`, idempotent)
- Guards: Pilot-Artefakt, Bestand < 300, unvollständiges Schema, unpublished
  Relationsziel, fremdbefüllte Zielzeile, fehlendes Batch-1-Artefakt (v1)
- Negativtests der Absicherung: ACL-Loch auf der **Payload** und auf dem
  **Snapshot** — beide wurden wie gefordert als FAIL gemeldet
- Trigger-Verhalten von `products_touch_updated_at()`
- Lock-Timeout unter `AccessExclusiveLock`, `lock_timeout = '5s'`

Damit sind die in früheren Fassungen dieses Berichts offenen Punkte
„0 von 15 Datenbankfällen ausgeführt", „Gate 0 blockiert, weil kein
PostgreSQL vorhanden ist" und „der bestätigende Wiederholungslauf nach den
Textentschärfungen steht aus" **erledigt und gegenstandslos**.

### 1.3 Historie: der erste Lauf (vor den Textentschärfungen)

Vor diesem Lauf hatte Codex denselben Harness bereits einmal vollständig
gefahren — auf dem Textstand **vor** den Entschärfungen aus §6, Workdir
`/tmp/cbb-pgtest-b2.6t9bQFUe`, mit identischem Ergebnis: Exit 0, 106 Schritte,
0 Abweichungen, GESAMT PASS, v1-Manifest 34/34. Dieser Lauf ist Historie; der
Gate-0-Beleg ist der Lauf aus §1.1/§1.2 (`CvjYPVa5`).

**Infrastrukturvorlauf (Historie):** ein noch früherer Versuch innerhalb der
Sandbox scheiterte bereits am Anlegen des Unix-Sockets (`EPERM`) und damit
**vor** dem ersten Datenbankfall. Das war kein SQL-Befund und keine Aussage
über die Rollout-Dateien.

### 1.4 Was dieser Lauf nicht belegt

Er belegt die **Semantik der SQL-Dateien**. Er belegt **nicht** den
Production-Zustand: die Fixture bildet Production nach, sie ist nicht
Production (§4, Risiko 2).

Zwischen den beiden Läufen wurden ausschließlich **Fließtexte** in
`03_backfill_value_add_batch2.sql` entschärft (§6). SQL-Struktur, Slugs,
Relationen, Feld- und Array-Anzahl sowie alle Guards blieben unverändert;
die statischen Invarianten sind in §2 nachgezählt — und der Lauf aus §1.2
belegt sie jetzt zusätzlich dynamisch auf dem entschärften Stand.

---

## 2. Statische Gegenproben nach den Textentschärfungen (Claude-Session)

Alle Kommandos liefen aus
`apps/web/supabase/production_value_add_batch2/` bzw. `…/test/`.

### 2.1 Integrität von Batch 1 — PASS

```
$ cd apps/web/supabase/production_value_add_batch2/test
$ sha256sum -c V1_MANIFEST.sha256 --quiet
(keine Ausgabe)
```

Exit 0, keine Ausgabe = keine Abweichung. 34 Dateien geprüft: die 13 Dateien
auf oberster Ebene von `production_value_add/` (9 SQL, RUNBOOK, Testreport,
test/README, test/run_local_postgres_test.sh), 5 Fixture-Dateien, 15
Case-Dateien, plus der gemeinsam genutzte `../seo_updated_at_trigger.sql`.
Batch 1 ist byteweise unangetastet — vor und nach den Textedits.

### 2.2 Transaktionsklammer und `SET LOCAL`-Position in `03` — PASS

```
$ grep -n "^begin;\|^set local \|^commit;" 03_backfill_value_add_batch2.sql
44:begin;
50:set local lock_timeout = '5s';
51:set local statement_timeout = '60s';
548:commit;
```

Genau ein `begin;`, genau ein `commit;`, `statement_timeout` direkt unter
`lock_timeout`, beide hinter `begin;` und vor dem ersten `do $$` (Zeile 53).
Zwischen `begin;` und `set local` stehen nur Leerzeilen und `--`-Kommentare.
Die Zeilennummern haben sich gegenüber dem ersten Codex-Lauf nur am Dateiende
verschoben (`commit;` 551 → 548, drei Zeilen weniger Text); die Reihenfolge
ist identisch.

### 2.3 Keine destruktiven Anweisungen in `03` — PASS

```
$ grep -nPi '^(?!\s*--).*(?<![_a-zA-Z0-9])(drop|truncate|delete)(?![_a-zA-Z0-9])' \
    03_backfill_value_add_batch2.sql
208:) on commit drop;
```

Ein einziger Treffer, die `on commit drop`-Klausel der **temporären**
Payload-Tabelle. Der Harness kennt diese Ausnahme explizit
(`static_write_safety` maskiert `on commit drop` vor der Suche).

### 2.4 Zielmenge vollständig — PASS

```
$ grep -c '<slug1>\|<slug2>\|…\|<slug10>' 03_backfill_value_add_batch2.sql
28
```

28 Zeilentreffer in `03` — unverändert gegenüber dem Stand vor den Textedits.
Kein Slug wurde beim Umformulieren berührt.

### 2.5 Struktur der Payload — PASS

```
$ grep -c 'array\[' 03_backfill_value_add_batch2.sql
20

$ grep -n "'complement'\|'alternative'\|  null, null, null," 03_backfill_value_add_batch2.sql
228, 244, 298, 315, 332, 349, 366, 384   -> 8 × null, null, null,
262                                      -> 'complement'
281                                      -> 'alternative'
```

**20 `array[`** im Payload-Valuesblock (10 × `pros` + 10 × `cons`),
**exakt 8 null-Triplets**, **1 `complement`**, **1 `alternative`**. Die
Treffer ab Zeile 464 liegen im Nachprüf-Guard, nicht im `values`-Block.

Pro Zeile nachgezählt: `pros` 2–4 Einträge (Spanne des Guards in `04`
eingehalten), `cons` je 2 Einträge (≥ 1 eingehalten), und `fuer_wen`,
`nicht_fuer`, `key_fact`, `editorial_note` sind in allen zehn Zeilen gesetzt
und nicht leer.

### 2.6 Content-Regeln nach den Umformulierungen — PASS

```
$ grep -niE 'revolution|ultimativ|must-have|game-changer|jetzt zugreifen|nicht verpassen|schnäppchen|schnaeppchen|!!!' \
    03_backfill_value_add_batch2.sql
512:    'hot-wheels-ultimative-garage-3ft',
```

Einziger Treffer ist der **Produkt-Slug** aus der Batch-1-Guardliste — kein
generierter Text.

```
$ grep -nP "[a-zA-ZäöüÄÖÜß]'[a-zA-ZäöüÄÖÜß]" 03_backfill_value_add_batch2.sql
(keine Ausgabe)
```

Keine Apostrophe innerhalb deutscher Wörter — kein Risiko, dass ein
Umgangsapostroph ein SQL-Literal aufbricht.

---

## 3. Was in der Claude-Session nicht ausführbar war

Die Berechtigungsschicht dieser Session lehnt weiterhin jede Ausführung von
Shell-Skripten ab; die Session ist nicht-interaktiv, eine Freigabe ist nicht
einholbar:

```
bash -n test/run_local_postgres_test.sh                   -> requires approval
env CBB_STATIC_ONLY=1 bash test/run_local_postgres_test.sh -> requires approval
```

Beides wurde versucht und dokumentiert, **nicht** umgangen — insbesondere
wurde nicht auf Netzwerk, Supabase oder ein MCP-Tool ausgewichen. Erlaubt
waren einzelne lesende Kommandos (`grep`, `find`, `sha256sum`, `ls`), mit
denen §2 gefahren wurde.

Für `bash -n` und `CBB_STATIC_ONLY=1` gilt: beide sind im maßgeblichen
Codex-Lauf (§1) implizit mitgelaufen — der vollständige Lauf startet mit
`case_0_statisch` und setzt eine fehlerfreie Skriptsyntax voraus. Da dieser
Lauf auf dem entschärften Textstand stattfand, ist das für den aktuellen Stand
belegt.

---

## 4. Offene Risiken

| # | Risiko | Bewertung |
|---|---|---|
| 1 | **PostgreSQL liegt nur unter `/tmp`.** Der entpackte Paketbaum überlebt keinen Neustart. Jede weitere Wiederholung braucht das Entpacken erneut plus `LD_LIBRARY_PATH` und `CBB_PG_BIN` wie in §1.1. | niedrig, aber betrieblich zu wissen |
| 2 | **Die Fixture bildet Batch 1 nach, statt es auszuführen.** `fixture/03_v1_artifacts.sql` erzeugt Struktur und Inhalt der v1-Tabellen von Hand. Weicht Production davon ab, testet der Harness einen anderen Zustand. Gegenmaßnahme: `01_preflight` prüft `v1_snapshot_form` und `v1_payload_form` (RLS, Policies, Spaltenzahl, PK) direkt auf Production. | niedrig |
| 3 | **Der `editorial_note`-Ist-Stand der zehn Zielzeilen ist unbekannt.** Deshalb ist die entsprechende Prüfung in `02b` INFO statt PASS (RUNBOOK §8.2). Der Backfill überschreibt bestehende Notizen bewusst; der Snapshot sichert sie. | niedrig, aber vor Gate 4 dem Benutzer zu nennen |
| 4 | **`service_role` ist nirgends abgesichert** — nicht revoked, typischerweise `BYPASSRLS`. Bewusst nur INFO. Übernommen aus Batch 1. | bekannt und akzeptiert |
| 5 | **Der Relationsguard kann nicht isoliert auslösen**, weil beide Relationsziele in der Zielmenge liegen. Der Published-Guard greift zuerst — strenger, nicht schwächer. Dokumentiert in RUNBOOK §8.4. | keines |
| 6 | **Keine einzige Aussage über Production.** Kein Artefakt lief gegen `ydiihvzcxaaoqhmgoqvu`. Der lokale Lauf sagt nichts über den dortigen Ist-Bestand. | offen bis Gate 1 |

---

## 5. Befunde aus der Erstellung — gefunden und behoben

Diese drei Punkte wurden bei der statischen Durchsicht der eigenen
Erwartungswerte gefunden, **bevor** der Harness lief. Sie stehen weiter hier,
weil sie den Unterschied zwischen „Test geschrieben" und „Test stimmt"
markieren.

### 5.1 Falsche Fehlererwartung bei der Backfill-Wiederholung

`case_b_wiederholungen` erwartete ursprünglich, dass ein zweiter Lauf von `03`
am **Drift-Guard** scheitert — so war es in Batch 1. In Batch 2 steht die
Existenzprüfung von `value_add_payload_v2` aber bewusst schon im **ersten**
Guard-Block, also vor dem Zeilen-Lock. Der zweite Lauf bricht deshalb mit
`Audit-Payload v2 existiert bereits.` ab, nicht mit der Drift-Meldung.

Behoben: Erwartung korrigiert **und** `case_n_drift` ergänzt, damit der
Drift-Guard weiterhin eigens geprüft wird. Ohne diese Korrektur wäre der
Drift-Guard in Batch 2 ungetestet geblieben — im Lauf aus §1 ist er jetzt
belegt.

### 5.2 Nicht eindeutige Zählung im Sicherheits-Fall

`case_l_payload_security` sollte ursprünglich nach dem Backfill auch `02b`
prüfen. `02b` verlangt jedoch zusätzlich, dass `value_add_payload_v2` noch
nicht existiert — nach dem Backfill wäre diese Zeile ebenfalls FAIL gewesen und
die FAIL-Zahl nicht mehr eindeutig dem gesetzten Rechte-Loch zuzuordnen.

Behoben: aufgeteilt in `case_l_payload_security` (Grant auf die Payload, `04b`
muss 8 PASS / 2 FAIL liefern) und `case_o_snapshot_security` (Grant auf den
Snapshot, vor dem Backfill, `02b` muss 15 PASS / 2 FAIL liefern). Beide Fälle
sind im Lauf aus §1 bestanden.

### 5.3 Trigger und Baseline in der Fixture

`setup_unpublish_relation.sql` schreibt `updated_at` nach dem Unpublishen
ausdrücklich auf den historischen Wert zurück. `is_published` steht in der
Spaltenliste von `products_touch_updated_at()`; ohne das Zurückschreiben hätte
der Trigger das lastmod angehoben und die Baseline-Prüfung im selben Fall wäre
fälschlich fehlgeschlagen.

---

## 6. Textentschärfungen zwischen den beiden Läufen

Nach dem ersten Codex-Lauf (§1.3) wurden in
`03_backfill_value_add_batch2.sql` ausschließlich Formulierungen ersetzt, die
über die verifizierten Rohfakten hinausgingen. Kein Slug, keine Relation, keine
Feldanzahl und kein Guard wurde dabei angefasst. Der maßgebliche Lauf aus §1.2
fand auf genau diesem entschärften Stand statt.

| Produkt | Entfernt / ersetzt |
|---|---|
| Livondo | „Jahrhunderte alt", „sofort wieder einsatzbereit" — bleibt: Ollas-Prinzip, befüllen/in die Erde, langsame Abgabe, ohne Strom und Timer, Reichweite ausdrücklich unbekannt |
| Wixies | Anlässe (Junggesellenabschied, Wichteln) und jede Aussage zum Packungsformat — bleibt: 7 bedruckte Servietten, derber Scherzartikel |
| Kaffeewärmer | „erhitzt kalten Kaffee nicht neu", „kompakte Stellfläche" — `cons` sind jetzt nur Netzbindung und die Abschaltung nach 8 Stunden |
| Glücksgut-Würfel | Hosentaschen-/Größenbehauptung und die Aussage, welche Seite hörbar ist — bleibt: sechs Seiten, Drücken/Drehen/Schieben/Klicken, ruhige Bedienoptionen, Schreibtisch/Meeting/Fokus |
| Boyfriend-Kissen | „kompakt" und jede Aussage zu ergonomischer Wirkung **oder** Nichtwirkung — bleibt: Pyjama-Oberteil mit Arm, ca. 54 × 50 cm, 30 °C waschbar, Geschmacks-Einordnung |
| Scheisse-Quartett | „in dreißig Sekunden erklärt", Jackentasche, „für Vielspieler zu wenig" — bleibt: 32 Figuren, klassisches Quartettprinzip, Reiseformat, derbes Thema |
| Pool-Ente | „nicht als Schwimm- oder Rettungshilfe gedacht/verwenden" — ersetzt durch die reine Feststellung, dass keine verifizierten Alters-, Sicherheits- oder Belastbarkeitsangaben vorliegen; bleibt: 1,2 m, PVC, Schnellventil |
| Shashibo | Mund-/Verschluckwarnung und „Magnete halten die Form von selbst" — bleibt: magnetisch, laut Produktdaten 70+ Formen, ohne Batterie/App, ab 6 |
| Todesstern-Form | Herausdrücken, Gefrierfachbedarf, Geschmack, Kühlwirkung — bleibt: lebensmittelechtes Silikon, drei Star-Wars-Eiskugeln im Todesstern-Design |
| Katzenschlafsack | „Zum Laufen nicht gedacht" — bleibt: Katzenohren-Kapuze, Armlöcher, weiches Innenfutter, Reißverschluss, S–XL, Passform-/Geschmackshinweis |

---

## 7. Bilanz

| | Anzahl |
|---|---|
| Maßgeblicher Harness-Lauf (Codex, `CvjYPVa5`) | **106 Schritte** |
| Abweichungen | **0** — GESAMT PASS, Exit 0 |
| v1-Manifest | **34/34 identisch** |
| Statische Gegenproben nach den Textedits | **6 Gruppen, alle PASS** |
| Bestätigende Läufe insgesamt | **2** (vor und nach den Textedits, beide GESAMT PASS) |
| Production-Zugriffe | **0** |
| Offener Pflichtschritt vor Gate 0 | **keiner** — es fehlt nur die Freigabe des Benutzers |
</content>
