# PoC Flow - Azure Infrastructure Deployment

Detta är ett proof-of-concept flöde för AI-stött deployment av Azure-infrastruktur enligt SX:s namnstandard.

## Översikt

Detta flöde skapar en minimal Azure-infrastruktur bestående av:
- **Storage Account** - För lagring av data
- **Application Insights** - För applikationsövervakning
- **Log Analytics Workspace** - För logghantering och analys

Alla resurser namnges enligt SX:s standard.

## Förutsättningar

- Azure CLI installerat och inloggad (`az login`)
- Bicep CLI installerat (`az bicep install`)
- Rätt prenumeration vald (`az account set --subscription <subscription-id>`)
- Behörighet att skapa resursgrupper och resurser i vald prenumeration

## Snabbstart

### 1. Kopiera exempelfilen

```cmd
copy main.bicepparam.example main.bicepparam
```

### 2. Anpassa parametrarna

Öppna `main.bicepparam` och uppdatera värdena enligt ditt projekt:

```bicep
param customerPrefix = 'sx'        // Ditt kundprefix
param domain = 'int'               // Din domän/teknisk area
param function = 'demo'            // Funktionsbeskrivning
param subfunction = ''             // Valfri subfunktion
param environment = 'd'            // d/t/q/s/p
param location = 'swedencentral'   // Azure-region
```

**Viktigt**: Se till att storage account-namnet blir max 24 tecken (bicep validerar detta automatiskt).

### 3. Skapa resursgruppen

Resursgruppnamnet genereras automatiskt enligt namnstandarden. För att få namnet, kör först en what-if:

```cmd
az deployment sub create ^
  --location swedencentral ^
  --template-file main.bicep ^
  --parameters main.bicepparam ^
  --what-if
```

Eller beräkna namnet manuellt enligt mönstret:
```
[customerPrefix]-[domain]-[function]-[subfunction]-[environment]-rg
```

Exempel med `sx-int-demo-d`: `sx-int-demo-d-rg`

Skapa resursgruppen:

```cmd
az group create ^
  --name sx-int-demo-d-rg ^
  --location swedencentral
```

### 4. Deploya infrastrukturen

```cmd
az deployment group create ^
  --name poc-deployment ^
  --resource-group sx-int-demo-d-rg ^
  --template-file main.bicep ^
  --parameters main.bicepparam
```

### 5. Verifiera deployment

Kontrollera att resurserna skapades:

```cmd
az resource list --resource-group sx-int-demo-d-rg --output table
```

Visa outputs från deployment:

```cmd
az deployment group show ^
  --name poc-deployment ^
  --resource-group sx-int-demo-d-rg ^
  --query properties.outputs
```

## Detaljerad Deployment-guide

### Validera innan deployment (What-If)

Kör en what-if analys för att se vad som kommer att skapas:

```cmd
az deployment group what-if ^
  --name poc-deployment ^
  --resource-group sx-int-demo-d-rg ^
  --template-file main.bicep ^
  --parameters main.bicepparam
```

### Deployment med custom namn

Om du vill använda ett specifikt deployment-namn:

```cmd
SET DEPLOYMENT_NAME=demo-deployment-%RANDOM%

az deployment group create ^
  --name %DEPLOYMENT_NAME% ^
  --resource-group sx-int-demo-d-rg ^
  --template-file main.bicep ^
  --parameters main.bicepparam
```

### Deployment till olika miljöer

Skapa separata `.bicepparam`-filer för varje miljö:

```cmd
copy main.bicepparam.example main.d.bicepparam
copy main.bicepparam.example main.t.bicepparam
copy main.bicepparam.example main.p.bicepparam
```

Uppdatera `environment`-parametern i varje fil och deploya:

```cmd
REM Development
az deployment group create ^
  --name poc-dev ^
  --resource-group sx-int-demo-d-rg ^
  --template-file main.bicep ^
  --parameters main.d.bicepparam

REM Test
az deployment group create ^
  --name poc-test ^
  --resource-group sx-int-demo-t-rg ^
  --template-file main.bicep ^
  --parameters main.t.bicepparam
```

## Namngivning av resurser

### Genererade resursnamn

Med exempelparametrarna (`sx`, `int`, `demo`, `d`, `swedencentral`) genereras följande namn:

| Resurstyp | Namn | Kommentar |
|-----------|------|-----------|
| Resource Group | `sx-int-demo-d-rg` | Skapas manuellt först |
| Storage Account | `sxintdemodst` | Max 24 tecken, inga bindestreck |
| Application Insights | `sx-int-demo-sdcr-d-appi` | Inkluderar region (sdcr) |
| Log Analytics | `sx-int-demo-sdcr-d-log` | Inkluderar region (sdcr) |

### Region-förkortningar

Bicep-templaten konverterar automatiskt Azure-regioner till standardförkortningar:

- `swedencentral` → `sdcr`
- `swedensouth` → `sdsr`
- `westeurope` → `we`
- `northeurope` → `ne`

## AI Agent Workflow

För AI-assisterad deployment, se `AGENT.md` för detaljerade instruktioner om hur en AI-agent ska:
1. Ställa rätt frågor till användaren
2. Validera parametrar (särskilt storage account-namnlängd)
3. Generera korrekt `.bicepparam`-fil och klona `main.bicep`
4. Föreslå deployment-kommandon

## Felsökning

### Storage account-namnet för långt

Om du får ett fel om att storage account-namnet överskrider 24 tecken:
- Förkorta `domain` (t.ex. `integration` → `int`)
- Förkorta `function` 
- Ta bort `subfunction` om den inte är nödvändig
- Använd kortare `customerPrefix`

### Resursgruppen finns redan

Om resursgruppen redan finns kan du hoppa över steg 3 och gå direkt till deployment.

### Felaktig region

Se till att du använder fullständiga Azure-regionnamn (t.ex. `swedencentral`, inte `sdcr`).

### Deployment misslyckades

Kontrollera deployment-detaljer:

```cmd
az deployment group show ^
  --name poc-deployment ^
  --resource-group sx-int-demo-d-rg
```

Visa deployment operations:

```cmd
az deployment operation group list ^
  --name poc-deployment ^
  --resource-group sx-int-demo-d-rg
```

## Rensa upp

För att ta bort alla resurser:

```cmd
az group delete --name sx-int-demo-d-rg --yes --no-wait
```

## Relaterade filer

- `main.bicep` - Bicep-template för infrastrukturen
- `main.bicepparam.example` - Exempelparametrar
- `AGENT.md` - Instruktioner för AI-agenter

## Support

För frågor om namnstandard eller deployment-processen, kontakta SX integration-teamet.
