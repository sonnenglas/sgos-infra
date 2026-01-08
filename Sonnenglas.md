# Sonnenglas Systems


# Docflow
All inncomig documents as structured data. Mail, contracts, invoices. 
Paperless-NGX on steroids. 

Input:
	- Users (Upload documents)
	- APIs (Documents uploaded automatically from email, dropscan, etc)

Output:
 - UI
	- API
	- Bank Files (Batch Payments)

Connections:
	- Human in the Soup
	- Precounting


# Precounting
- Accounting System as a single source of truth of all business matters that are financially relevant

Input:
	-  All Financial Transactions (Banks, Stripe, etc)
	-  API
	- Users (Upload Bank Feeds, Create manual business matters (out of the ordinary)

Output:
	- API
	- Various Exports (VAT, DATEV)


Connections:
	- Human in the Soup
	- Docflow (for automatic doc/transaction/ reconciliation)
	- Xhosa (for sales data)
	- DATEV (via Export) 



# Beanstock 
Single Source of Truth for all physical stock movements
Centralized product management (what exists, its attributes)

Input: 
- UI (Users registering stock movements)
- API

Output:
- UI
- API

Connections:
- Xhosa
- Precounting


# MRP
Manufacturing and Production in flat file based archicture and lightweight databse. Strongly connected with Beanstock. Finished Products and Subassemblies are Dependency Files (YAML or JSON). We manage work orders in a lightweight DB. Pushes what then actually happens to Beanstock. MRP is just a "Planning and Organisational UI" that helps to understand: What do we need to manufacture and when. 
It's a module that could be exposed within the Beanstock UI. 
Also tracks production with barcode scanners (serial number scans, etc). Tightly integrated with beanstock and manages processes flows and exposes them as UI (e.g. SOPs, Incoming Goods Registration, Quality Control).

Input: 
	- UI (Users registering stock movements)
	- API

Output:
	- UI
	- API

	Connections:
	- Xhosa
	- Precounting
	- Human in the Soup


# Xhosa
Sales system Single source of truth of all orders and their state, including vat calculation, invoicing, etc. Also for forecasting and demand planning as it has ALL sales data. It is also partially CRM because it has all customer data. 

Input:
	- Website via API and Stripe (create Orders)
	- Amazon (Import API)
	- Other Platform Sales Channels
	- Partner Portal (B2B Self Service Portal)
	- Users (our staff managing orders manually, create, refund, etc.)

Output:
	- API

Connections:
	- Human in the Soup
	- Precounting via API (pushes sales data)
	- Ufudu (pushes fulfillment orders)
	- Beanstock (Queries stock for stock availability information and 	product information)
	- Stripe

# Ufudu 
Pick/Pack Fulfillment System used in the warehouses  to pick and pack orders. Mostly a mobile SPA with barcode scanning functionality to guide fulfillment operations. Runs on android devices with connected barcode scanners. 

Input:
	- API (to receive Orders)

Output:
	- API

Connections: 
	- Human in the Soup
	- Beanstock (Record/Track all movements)
	- Xhosa (Report state of Order)



# Human in the Soup
The general shared todo list where all system can report when they need a human to provide data or resolve a matters. If the precounting app (its llm agent) needs a new bank feed it will add a todo as a request to Human in the Soup. 

Could also be a company wide process and project management high-level overview which exposes human team structure in a Kanban style UI. 

Input:
	- API (LLms use it)

Output:
	- API (Callback URLs)
	- UI (Human Interface for task management)

Connections:
	- ALL systems



# Ctrl
Centralised control server/application that monitor and aggreated all services and apps. Has all logfiles, exceptions, etc. and can coordinate. Ensures backups, etc. An "agent" runs there to observe and look at Errors. Might have read access to the other systems an code to investigate and propose fixes. 

Also backs up all systems daily (with offsite copy)

Input
	- Dokploy or Coolify to Orchestrate
	- Logfiles (Graphana, Loki)
	- Error Logs (GlitchTip)
	- Container Monitoring
	- Backups

Output:
	- UI (Dashboard to see state)
	- Human in the Soup (to raise tasks todo for humans)



# Anansi
Internal general AI assistant connected to all systems. Exposed as chatbot and API. Consume all important information from all system and record them in a vector database for retrieval. Helps internally and also with customer support.

Input:
	- All systema via API (push or pull). Anansi consumes all knowledge somehow. Either as jobs or on the fly (tool calls to Xhosa API to obtain order information for example)
	- All knowledge is scoped and classified from public knowledge to internal knowledge.

Output:
	- Chatbot Internal
	- Chat External (website)
	- API 

Connections:
	- All Systems via API
	- Customer Service Helpdesk


# Ikhaya
Internal knowledge base and blog (Docusaurus project). Contains all company knowledge. Embeds Anansi as a chatbot. 

Input: 
	- API
	- Users

Output:
	- UI
	- Google Chat (Notifications)

Connections: 
	- Anansi

# Helpdesk
Helpdesk/Ticket Software like Sirportly or Chatwoot where all external inbound communication arrives and is managed. Connects to Ananasi to assists or automatically answer.

Input: 
	- Emails, Whatsapp, Forms, Phone
	- Users

Output:
	- UI

Connections: 
	- Anansi



# Website
Our public website and ecommerce shop. Static page using Astro.js with dynamic islands. Connects to our product catalogue and has a checkout with Stripe Checkout. Orders end up in Xhosa. Runs on Cloudflare Pages. 

Input: 
	- Public Website

Output:
	- Orders to Xhosa through Stripe

Connections: 
	- Xhosa
	- Stripe
	- Anansi 

# Partner Portal
This is a portal for resellers to login and manage their orders. 

Input: 
	- Public Website (with login)

Output:
	- Orders to Xhosa

Connections: 
	- Xhosa





# Message Bus

Event bus for async communication between systems. Simple Postgres-backed append-only events table exposed via API. Systems publish events when things happen, other systems subscribe to events they care about. Reduces polling, enables loose coupling, provides audit trail.

Events follow a shared dictionary/schema (e.g., `shipment.completed`, `order.created`, `stock.low`).

Input:
	- API (all systems publish events)

Output:
	- API (systems poll or use webhooks for subscriptions)
	- Webhooks (push to subscribers)

Connections:
	- All systems (publish and subscribe)

Events Dictionary (examples):
	- `order.created` - Xhosa
	- `order.shipped` - Ufudu
	- `stock.movement` - Beanstock
	- `stock.low` - Beanstock
	- `invoice.received` - Docflow
	- `payment.matched` - Precounting
	- `production.completed` - MRP
	- `task.created` - Human in the Soup
	
	
# Directory
A user directory exposed as a simple API so all apps now: Who is who. So that we have a central way to manage our users and their attributes. Apps still manage access control and permissions individually. Name, email, company, department, role, etc . 

Input: 
	- UI
	- Maybe Google Workspace Sync

Output:
	- API (e.g. GET /users)

Connections: 
	- All modules



# Notes:

## UI
UI means a general interface for humans to interact with. Might contain notifications, emails, etc. 

## Identity/Access Control
All apps are behind Tailscale and only expose 80/443 over Cloudflare Tunnel. Access Control over Cloudflare Zero Trust (Google Login, Service Auth for APIs + App specific API keys with scopes).
Service to Service Communication available within Tailscale internal network.

Identity for Users: 
- Google Workspace Login
- Maybed also pocket-id

Directory available to all apps through our Directory API

## Modularity
While all tools are here listed seperatedly they can also be subpages/modules in a single UI layer. Above described the structural setup and not necesarily the presentation setup to the user. 
Also, most systems can run on the same server in Docker containers.

## APIs
All APIs are documented and versioned, so they become stable and reliable contracts between the systems. Of course, all code is on GitHub. 


## Infrastructure
- VPS Servers on Netcup
- Postmark and/or Inbound.new for emailing/messaging

### Server 1: 
Role: CTRL
toucan.sgl.as
152.53.160.251

### Server 2: 
Role: App Server
hornbill.sgl.as
159.195.68.119






