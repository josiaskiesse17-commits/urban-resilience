# Fix Signaler + wizard observations

- [x] Étendre report draft + mapping types + RiskZoneCatalog.nearest
- [x] Déclarer routes /report* dans app_router
- [x] Pointer Signaler (map + risk) vers /report avec contexte zone
- [x] create Firestore (+ Storage photo) depuis summary ; received réel
- [x] Vérifier parcours E2E (`flutter analyze` OK)

## Review

- Routes `/report*` branchées ; Signaler → wizard (zone nearest depuis carte, zone+hazard depuis risk)
- Draft sans mocks ; mapping type → ObservationType + hazard label
- Envoi : `createWithOptionalPhoto` (Firestore + Storage)
- Received : id réel + lien `/observations?zone&hazard`
- Analyze ciblé : No issues found

Hors scope restant : obs dans score live, reject admin, index Firestore

# Fix bascule Clair/Sombre (Profil)

- [x] Dialogs StatefulWidget (controllers owned)
- [x] Chips thème sans AnimatedContainer
- [x] Profil via Theme.of(context)
- [x] Relance app + analyze OK
- [x] Leçon dans tasks/lessons.md
