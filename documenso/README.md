# Documenso modifié par Nexellin

Code source de la version de [Documenso](https://github.com/documenso/documenso) utilisée
par le service Nexellin, mis à disposition au titre de l'article 13 de l'AGPL-3.0.

- **Version amont** : `v2.18.0`, commit `389390c884949fe27c240488a3259da3cdba93e0`.
- **Image de départ** : voir `ARG DOCUMENSO_VERSION` dans le `Dockerfile` (tag et empreinte).
- **Licence** : AGPL-3.0, voir `LICENSE`. Copyright © Documenso, Inc. et ses contributeurs ;
  modifications © Nexellin, sous la même licence.

## Modifications

`patch.sh` modifie le code compilé de l'image, à deux endroits seulement :

1. le cookie `lang` dure 6 mois au lieu de 2 ans ;
2. l'adresse IP du signataire est lue d'abord dans `CF-Connecting-IP`, avant `X-Forwarded-For`.

Le build s'arrête si le code amont ne correspond plus.

## Reconstruire l'image

```bash
docker build -t documenso-nexellin documenso/
```

Chaque tag `documenso-v<version>-nx<n>` correspond à une version d'image en service.
