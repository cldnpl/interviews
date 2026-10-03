#!/usr/bin/env python3
"""Sostituisce un argomento dentro i JSON dei contenuti, in inglese e in italiano.

Uso: patch_topic.py <track> <nuovo_topic.json>
dove il file contiene {"en": {...topic...}, "it": {...topic...}}.

Controlla che id delle domande, indice della risposta e difficoltà restino
quelli di prima: i progressi salvati sono legati a quegli id, e le due lingue
devono restare allineate.
"""
import json, sys, pathlib

def load(p):
    return json.loads(pathlib.Path(p).read_text())

def check(old, new, where):
    assert old['id'] == new['id'], f"{where}: id dell'argomento cambiato"
    oq = {q['id']: q for q in old['questions']}
    nq = {q['id']: q for q in new['questions']}
    assert set(oq) == set(nq), f"{where}: id delle domande diversi: {set(oq) ^ set(nq)}"
    for qid, q in nq.items():
        o = oq[qid]
        assert q['answer'] == o['answer'], f"{where}/{qid}: indice della risposta cambiato"
        assert q['difficulty'] == o['difficulty'], f"{where}/{qid}: difficoltà cambiata"
        assert len(q['options']) == len(o['options']), f"{where}/{qid}: numero di opzioni cambiato"
        ww = q.get('whyWrong')
        if ww is not None:
            assert len(ww) == len(q['options']), f"{where}/{qid}: whyWrong di lunghezza sbagliata"
            assert ww[q['answer']] is None, f"{where}/{qid}: whyWrong non nullo sulla risposta giusta"
            for i, w in enumerate(ww):
                assert i == q['answer'] or (w and w.strip()), f"{where}/{qid}: whyWrong vuoto all'opzione {i}"
        for key in ('prompt', 'explanation'):
            assert q.get(key, '').strip(), f"{where}/{qid}: {key} vuoto"
    for s in new['lesson']:
        assert s['heading'].strip() and s['body'].strip(), f"{where}: sezione di lezione vuota"

def main():
    track, path = sys.argv[1], sys.argv[2]
    payload = load(path)
    for lang in ('en', 'it'):
        f = pathlib.Path(f'Resources/{lang}.lproj/{track}.json')
        data = load(f)
        new = payload[lang]
        i = next(i for i, t in enumerate(data['topics']) if t['id'] == new['id'])
        check(data['topics'][i], new, f'{lang}/{track}/{new["id"]}')
        data['topics'][i] = new
        f.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print(f'ok {track}/{payload["en"]["id"]}')

if __name__ == '__main__':
    main()
