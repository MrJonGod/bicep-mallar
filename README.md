**Översikt**

- **Repo**: Ett enkelt exempelrepo för en PoC kring AI-stött generering av Azure-integrationsflöden.

**Flöden**
- **Exempelflöde 1**: Innehåller ett enkelt integrationsflöde med `main.bicep` och tillhörande parameterfiler. Finns i mappen `Exempelflöde_1` och inkluderar även `Deploy.ps1` samt `parameters.dev.json`, `parameters.test.json` och `parameters.prod.json`.
- **Exempelflöde 2**: Mer infrastrukturfokuserat exempel som innehåller `Infra/`-mallar, resurser för servicebus/tema och pipeline-exempel under `Pipelines/`. Finns i mappen `Exempelflöde_2`.
- **PoC-flow**: Det enda flödet som i denna PoC implementerar konceptet för AI-agentstyrning enligt projektplanen. Mappen `PoC-flow` innehåller `AGENT.md`, `main.bicep`, exempel på `.bicepparam` och README som visar hur agenten kan användas för att generera parametrar och validera flödet.

**Syfte (sammanfattning)**
- **Mål**: Demonstrera att ett AI-styrt arbetssätt kan minska manuell kodkopiering, ge mer enhetliga flöden, förenkla onboarding och snabbt generera stommar för återanvändbara integrationer.
- **PoC-avgränsning**: PoC:n visar ett koncept (inte ett färdigt verktyg). Endast ett fungerande flöde ingår och allt körs i sandbox.

**Namnstandard (kortfattat)**
- **Mönster**: `[kundprefix]-[domän/teknisk area]-[funktion]-([subfunktion])-([löpnummer])-([region])-[miljö]-[resurstyp]`.
- **Format**: Kebab-case, enbart lowercase.
- **Miljö**: En bokstav (`d`, `t`, `q/s`, `p`) används för miljö istället för fullständiga namn.
- **Specialfall för Storage/KeyVault**: På grund av längdbegränsningar används ett kompakt format utan bindestreck och med suffix `st` för storage och `kv` för keyvault (max ~24 tecken). Exempel: `telgeintstratsyspst`, `lejonintdynamicsdkv`.
- **Region**: Ange endast när det är relevant; använd officiella regionförkortningar (t.ex. `SDCR`, `SDSR`, `WE`, `NE`).
