---
title: Architecture Overview
sidebar_position: 2
description: Visual overview of all SGOS applications and their relationships
---

# Architecture Overview

## System Landscape

```mermaid
graph TB
    subgraph External["External Systems"]
        Twilio[Twilio]
        Dropscan[Dropscan]
        Google[Google Workspace]
        GChat[Google Chat]
        Website[sonnenglas.net]
        PartnerPortal[Partner Portal]
    end

    subgraph Customers["Customer Touchpoints"]
        Phone[Phone<br/>Telephony Gateway]
        Ikhaya[Ikhaya<br/>B2B Webshop]
        Ufudu[Ufudu<br/>Partner Portal Backend]
        Soup[Soup<br/>Content API]
    end

    subgraph Core["Core Business"]
        Xhosa[Xhosa<br/>Order Management]
        Docflow[Docflow<br/>Document Management]
        Accounting[Accounting<br/>Financial Records]
        Inventory[Inventory<br/>Stock Management]
    end

    subgraph Manufacturing["Manufacturing"]
        MRP[MRP<br/>Production Planning]
        Baobab[Baobab<br/>Product Master]
    end

    subgraph Intelligence["Intelligence"]
        Anansi[Anansi<br/>Price Crawler]
    end

    subgraph Internal["Internal Tools"]
        Directory[Directory<br/>Employee Directory]
        Clock[Clock<br/>Time Tracking]
    end

    subgraph Platform["Platform Services"]
        Bus[Bus<br/>Event Bus]
        Identity[Identity<br/>SSO/Auth]
        Sangoma[Sangoma<br/>Error Analysis]
    end

    %% External connections
    Twilio --> Phone
    Dropscan --> Docflow
    Google --> Directory
    Website --> Soup
    PartnerPortal --> Ufudu

    %% Customer touchpoint flows
    Phone --> Xhosa
    Ikhaya --> Xhosa
    Ufudu --> Xhosa

    %% Core business flows
    Xhosa --> Accounting
    Xhosa --> Inventory
    Docflow --> Accounting
    Docflow --> Xhosa

    %% Manufacturing flows
    Inventory --> MRP
    MRP --> Baobab
    Inventory --> Baobab
    Xhosa --> Baobab

    %% Internal flows
    Directory --> Clock

    %% Platform connections (simplified)
    Bus -.-> Xhosa
    Bus -.-> Inventory
    Bus -.-> Accounting
    Identity -.-> Xhosa
    Identity -.-> Docflow
    Sangoma -.-> Xhosa
    Sangoma -.-> Docflow
```

## Application Status

| App | Purpose | Server | Status |
|-----|---------|--------|--------|
| **Phone** | Twilio telephony gateway | Hornbill | Live |
| **Xhosa** | Order management (ERP core) | Hornbill | Live |
| **Docflow** | Document processing & archive | Hornbill | Live |
| **Accounting** | Financial records & reporting | Hornbill | Planned |
| **Inventory** | Stock levels & movements | Hornbill | Planned |
| **Baobab** | Product & brand master data | Hornbill | Concept |
| **MRP** | Manufacturing planning | Hornbill | Concept |
| **Ufudu** | Partner portal backend | Hornbill | Planned |
| **Soup** | Content API for website | Hornbill | Planned |
| **Anansi** | Competitor price crawling | Hornbill | Concept |
| **Ikhaya** | B2B webshop | Hornbill | Concept |
| **Directory** | Employee directory | Hornbill | Planned |
| **Clock** | Time tracking | Hornbill | Concept |
| **Bus** | Event message broker | Hornbill | Concept |
| **Identity** | SSO/authentication | Hornbill | Concept |
| **Sangoma** | Automated error analysis | Toucan | Concept |

## Data Flow: Order Lifecycle

```mermaid
sequenceDiagram
    participant C as Customer
    participant P as Phone
    participant X as Xhosa
    participant I as Inventory
    participant A as Accounting
    participant D as Docflow

    C->>P: Calls hotline
    P->>X: Creates/updates order
    X->>I: Reserves stock
    X->>A: Creates invoice
    A->>D: Archives invoice PDF
    D-->>C: Sends invoice email
```

## Data Flow: Document Processing

```mermaid
sequenceDiagram
    participant DS as Dropscan
    participant DF as Docflow
    participant A as Accounting
    participant X as Xhosa

    DS->>DF: Webhook (new scan)
    DF->>DF: Classify document
    alt Invoice
        DF->>A: Create payable
        A->>X: Link to supplier order
    else Contract
        DF->>DF: Archive & notify
    end
```

## Server Distribution

```mermaid
graph LR
    subgraph Hornbill["Hornbill (Business Apps)"]
        H1[Phone]
        H2[Xhosa]
        H3[Docflow]
        H4[Accounting]
        H5[Inventory]
        H6[+ future apps]
    end

    subgraph Toucan["Toucan (Control Plane)"]
        T1[Grafana]
        T2[Loki]
        T3[GlitchTip]
        T4[Sangoma]
        T5[Beszel]
    end

    Hornbill -->|logs| Toucan
    Hornbill -->|errors| Toucan
    Toucan -->|fixes| Hornbill
```

## Integration Points

| From | To | Method | Purpose |
|------|-----|--------|---------|
| Twilio | Phone | Webhook | Incoming calls |
| Dropscan | Docflow | Webhook | Scanned documents |
| Phone | Xhosa | Internal API | Order creation |
| Xhosa | Accounting | Internal API | Invoice generation |
| Xhosa | Inventory | Internal API | Stock reservation |
| Docflow | Accounting | Internal API | Payables from invoices |
| Bus | All apps | Redis pub/sub | Event distribution |
| Identity | All apps | OAuth/OIDC | Authentication |
| GlitchTip | Sangoma | API polling | Error collection |
| Sangoma | GitHub | API | PR/issue creation |
