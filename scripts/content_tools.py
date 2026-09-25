#!/usr/bin/env python3
"""Traduzione dei contenuti: l'italiano è la struttura, l'inglese solo la prosa.

  dump <track> <topic-id>...   stampa la prosa italiana di quegli argomenti
  check <track> <topic-id>...  verifica i frammenti tradotti contro l'originale
  build [track]...             ricompone Resources/en.lproj/<track>.json
  status                       quanti argomenti sono già tradotti

I frammenti stanno in translations/en/<track>/<topic-id>.json e contengono solo
testo, più il codice con commenti e stringhe tradotti: id, risposta giusta e
difficoltà vengono sempre dall'italiano, così una traduzione non può spostare
la risposta di una domanda.
"""
import json, os, sys

TRACKS = ["swift", "uikit", "kotlin", "flutter"]
SRC = "Resources/it.lproj/{}.json"
OUT = "Resources/en.lproj/{}.json"
FRAG = "translations/en/{}/{}.json"


def load(track):
    return json.load(open(SRC.format(track)))


def dump(track, ids):
    topics = {t["id"]: t for t in load(track)["topics"]}
    for tid in ids:
        t = topics[tid]
        def sec(s):
            d = {"heading": s["heading"], "body": s["body"]}
            if s.get("code") is not None: d["code"] = s["code"]
            return d
        def quest(q):
            d = {"prompt": q["prompt"]}
            if q.get("code") is not None: d["code"] = q["code"]
            d.update({"options": q["options"], "answer": q["answer"],
                      "explanation": q["explanation"], "whyWrong": q.get("whyWrong")})
            return d
        out = {"title": t["title"], "summary": t["summary"],
               "lesson": [sec(s) for s in t["lesson"]],
               "questions": [quest(q) for q in t["questions"]]}
        print(f"\n===== {track}/{tid} =====")
        print(json.dumps(out, ensure_ascii=False, indent=1))


def apply(track, t, f):
    """Copia la prosa del frammento f nell'argomento t, controllando che la forma combaci."""
    where = f"{track}/{t['id']}"
    assert isinstance(f.get("title"), str) and isinstance(f.get("summary"), str), f"{where}: title/summary"
    assert len(f["lesson"]) == len(t["lesson"]), f"{where}: sezioni lezione {len(f['lesson'])} != {len(t['lesson'])}"
    assert len(f["questions"]) == len(t["questions"]), f"{where}: domande {len(f['questions'])} != {len(t['questions'])}"
    t["title"], t["summary"] = f["title"], f["summary"]

    def code(orig, frag, label):
        if "code" not in frag: return orig
        assert (orig is None) == (frag["code"] is None), f"{label}: code presente in uno solo dei due"
        return frag["code"]

    for i, (sec, fs) in enumerate(zip(t["lesson"], f["lesson"])):
        sec["heading"], sec["body"] = fs["heading"], fs["body"]
        c = code(sec.get("code"), fs, f"{where} lezione {i}")
        if c is not None: sec["code"] = c
    for q, fq in zip(t["questions"], f["questions"]):
        assert len(fq["options"]) == len(q["options"]), f"{q['id']}: opzioni {len(fq['options'])} != {len(q['options'])}"
        assert all(isinstance(o, str) and o for o in fq["options"]), f"{q['id']}: opzione vuota"
        assert len(set(fq["options"])) == len(fq["options"]), f"{q['id']}: opzioni duplicate"
        q["prompt"], q["options"], q["explanation"] = fq["prompt"], fq["options"], fq["explanation"]
        c = code(q.get("code"), fq, q["id"])
        if c is not None: q["code"] = c
        if q.get("whyWrong") is not None:
            w = fq.get("whyWrong")
            assert w is not None and len(w) == len(q["whyWrong"]), f"{q['id']}: whyWrong di lunghezza diversa"
            # Il buco deve restare sulla risposta giusta, non altrove.
            assert w[q["answer"]] is None, f"{q['id']}: whyWrong[{q['answer']}] deve essere null"
            for i, orig in enumerate(q["whyWrong"]):
                assert (orig is None) == (w[i] is None), f"{q['id']}: whyWrong[{i}] non combacia con l'originale"
            q["whyWrong"] = w


def check(track, ids):
    topics = {t["id"]: t for t in load(track)["topics"]}
    ok = True
    for tid in ids:
        path = FRAG.format(track, tid)
        try:
            apply(track, topics[tid], json.load(open(path)))
            print(f"ok      {path}")
        except (AssertionError, KeyError, TypeError, ValueError, FileNotFoundError) as e:
            ok = False
            print(f"ERRORE  {path}: {e!r}")
    sys.exit(0 if ok else 1)


def build(tracks):
    for track in tracks:
        data = load(track)
        missing = []
        for t in data["topics"]:
            path = FRAG.format(track, t["id"])
            if not os.path.exists(path):
                missing.append(t["id"])
                continue
            apply(track, t, json.load(open(path)))
        if missing:
            print(f"  {track}: mancano {len(missing)} argomenti -> {', '.join(missing)}")
        with open(OUT.format(track), "w") as out:
            json.dump(data, out, ensure_ascii=False, indent=2)
            out.write("\n")
        print(f"  scritto {OUT.format(track)}")


def status():
    total = done = 0
    for track in TRACKS:
        ids = [t["id"] for t in load(track)["topics"]]
        have = [i for i in ids if os.path.exists(FRAG.format(track, i))]
        total += len(ids); done += len(have)
        todo = [i for i in ids if i not in have]
        print(f"{track:8} {len(have):2}/{len(ids):2}" + (f"  da fare: {', '.join(todo)}" if todo else "  ✓"))
    print(f"{'TOTALE':8} {done:2}/{total:2}")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "dump": dump(sys.argv[2], sys.argv[3:])
    elif cmd == "check": check(sys.argv[2], sys.argv[3:])
    elif cmd == "build": build(sys.argv[2:] or TRACKS)
    elif cmd == "status": status()
    else: print(__doc__); sys.exit(1)
