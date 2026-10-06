# SDO Agentia pipeline

Copado CI/CD pipeline in the copado-trial org: **dev1** and **dev2** -> **qa** -> **Prod** (`main`), all four orgs from one
Salesforce production org (the SDO test org `sdo-pipeline` and its Developer sandboxes).

`main` starts as Prod's baseline for Account, Opportunity and Lead (objects and their page layouts), retrieved
2026-10-06. Every environment branch starts from `main`. Work happens on `feature/US-*` branches through Copado user
stories (Agentia CLI or the Copado UI); `AGENTS.md` tells AI agents the Copado workflow.
